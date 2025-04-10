#=
# OpPoDyn.jl - Eine Bibliothek für Energiesystemdynamik
## Einführung und Setup

In diesem Workshop werden wir mit OpPoDyn.jl arbeiten, einer Julia-Bibliothek zur Simulation 
und Analyse von dynamischen Vorgängen in Energiesystemen. Wir beginnen mit der Einrichtung 
unserer Arbeitsumgebung.
=#
using WorkshopCompanion
using OpPoDyn, OpPoDyn.Library
using NetworkDynamics, NetworkDynamicsInspector
using NetworkDynamics: SII
using ModelingToolkit
using ModelingToolkit: D_nounits as Dt, t_nounits as t
using OrdinaryDiffEqRosenbrock, OrdinaryDiffEqNonlinearSolve, DiffEqCallbacks
using SciMLSensitivity, Optimization, Optimisers
using LinearAlgebra
using CairoMakie, DataFrames, Graphs

@time nw = WorkshopCompanion.load_39bus()

#=
## Inspektion von Modellkomponenten

OpPoDyn.jl basiert auf Komponentenmodellen, die miteinander verknüpft werden, um ein Gesamtsystem zu bilden.
Schauen wir uns einige dieser Komponenten genauer an.
=#
nw[VIndex(30)]
# also metadata like
nw[VIndex(30)].metadata[:equations]
# inspect the initial state
dump_initial_state(nw[VIndex(30)])

#=
## Leistungsflussberechnung

Bevor wir dynamische Simulationen durchführen können, müssen wir zunächst einen stabilen 
Arbeitspunkt finden. Dies geschieht durch die Leistungsflussberechnung.
=#
OpPoDyn.solve_powerflow!(nw)

# now we have our "boundaries" defined
dump_initial_state(nw[VIndex(39)])

#=
## Initialisierung der Komponenten

Nach der Leistungsflussberechnung müssen alle dynamischen Komponenten initialisiert werden,
damit sie im berechneten Arbeitspunkt im Gleichgewicht sind.
=#

findall(nw[VIndex(31)].metadata[:observed]) do eq
    contains(repr(eq.lhs), "u_r")
end
nw[VIndex(31)].metadata[:observed][30]

nw[VIndex(31)]
dump_initial_state(nw[VIndex(31)])

nw[VIndex(31)].metadata[:observed][2]
nw[VIndex(31)].metadata[:observed][18]
nw[VIndex(31)].metadata[:observed][24]
nw[VIndex(31)].metadata[:observed][25]
nw[VIndex(31)].metadata[:observed][30]



v31_mag = norm(get_initial_state(nw, VIndex(31, [:busbar₊u_r, :busbar₊u_i])))
v39_mag = norm(get_initial_state(nw, VIndex(39, [:busbar₊u_r, :busbar₊u_i])))
set_default!(nw, VIndex(31,:load₊Vset), v31_mag)
set_default!(nw, VIndex(39,:load₊Vset), v39_mag)
OpPoDyn.initialize!(nw)

#=
## Definition einer Störung im Netzwerk

Nun definieren wir eine Störung, um die dynamische Reaktion des Systems zu untersuchen.
Hier simulieren wir einen Kurzschluss auf einer Leitung, gefolgt vom Abschalten dieser Leitung.
=#
const cb_verbose = Ref(true)
_enable_short = ComponentAffect([], [:pibranch₊shortcircuit]) do u, p, ctx
    ## Meldung ausgeben wenn Kurzschluss aktiviert wird
    cb_verbose[] && @info "Aktiviere Kurzschluss auf Leitung $(ctx.src)=>$(ctx.dst) bei t = $(ctx.t)"
    p[:pibranch₊shortcircuit] = 1
end
_disable_line = ComponentAffect([], [:pibranch₊active]) do u, p, ctx
    ## Meldung ausgeben wenn Leitung deaktiviert wird
    cb_verbose[] && @info "Deaktiviere Leitung $(ctx.src)=>$(ctx.dst) bei t = $(ctx.t)"
    p[:pibranch₊active] = 0
end
shortcircuit_cb = PresetTimeComponentCallback(0.1, _enable_short)
deactivate_cb = PresetTimeComponentCallback(0.2, _disable_line)

affected_edge = 11
add_callback!(nw[EIndex(11)], shortcircuit_cb)
add_callback!(nw[EIndex(11)], deactivate_cb)
nw[EIndex(11)]



#=
## Dynamische Simulation

Jetzt führen wir die eigentliche Simulation durch, um zu sehen, wie das System auf die 
definierte Störung reagiert.
=#
u0 = NWState(nw)
prob = ODEProblem(nw, uflat(u0), (0,15), pflat(u0); callback=get_callbacks(nw))
sol = solve(prob, Rodas5P())

#=
## Visualisierung der Simulationsergebnisse

Nach der Simulation analysieren wir die Ergebnisse mit verschiedenen Plots.

### Leistungsfluss in der betroffenen Leitung
=#
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Leistungsfluss in der betroffenen Leitung")
    ts = range(0, 0.28,length=1000)
    lines!(ax, ts, sol(ts; idxs=EIndex(6, :src₊P)).u; label="P (Quellende)")
    lines!(ax, ts, sol(ts; idxs=EIndex(6, :dst₊P)).u; label="P (Zielende)")
    lines!(ax, ts, sol(ts; idxs=@obsex(-EIndex(6, :src₊P)-EIndex(6, :dst₊P))).u; linestyle=:dot, label="P Verlust")
    axislegend(ax)
    fig
end

#=
### Spannungen an benachbarten Bussen
=#

let fig = Figure()
    ax = Axis(fig[1, 1]; title="Spannungen an benachbarten Bussen")
    ts = range(0, 0.3, length=1000)
    lines!(ax, ts, sol(ts; idxs=VIndex(3, :busbar₊u_mag)).u; label="Spannungsbetrag an Bus 3")
    lines!(ax, ts, sol(ts; idxs=VIndex(4, :busbar₊u_mag)).u; label="Spannungsbetrag an Bus 4")
    axislegend(ax, position=:rb)
    fig
end

#=
### Spannungsbeträge im gesamten Netzwerk
=#

let fig = Figure()
    ax = Axis(fig[1, 1]; title="Spannungsbeträge im gesamten Netzwerk")
    ts = range(0, 15, length=1000)
    for i in 1:39
        lines!(ax, ts, sol(ts; idxs=VIndex(i, :busbar₊u_mag)).u)
    end
    fig
end

#=
### Frequenzen an den Generatoren
=#

vidxs(nw, 30, "ω")
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Frequenzen an den Generatoren")
    ts = range(0, 15, length=1000)
    for i in 30:39
        lines!(ax, ts, sol(ts; idxs=only(vidxs(nw, i, r"machine₊ω$"))).u)
    end
    fig
end

#=
## Modifikation des Netzwerks - Integration eines Wechselrichters

Im nächsten Schritt modifizieren wir unser Netzwerk, indem wir einen Wechselrichter mit 
Droop-Regelung hinzufügen. Dies demonstriert die Flexibilität von OpPoDyn.jl beim 
Erstellen und Anpassen von Modellen.

Der Droop-Wechselrichter basiert auf folgenden Gleichungen:

**Leistungsmessung:**
$P_{meas} = u_r \cdot i_r + u_i \cdot i_i$
$Q_{meas} = u_r \cdot i_i - u_i \cdot i_r$

**Leistungsfilterung:**
$\tau \cdot \frac{dP_{filt}}{dt} = P_{meas} - P_{filt}$
$\tau \cdot \frac{dQ_{filt}}{dt} = Q_{meas} - Q_{filt}$

**Droop-Regelung:**
$\omega = \omega_0 - K_p \cdot (P_{filt} - P_{set})$
$V = V_{set} - K_q \cdot (Q_{filt} - Q_{set})$

**Spannungswinkel:**
$\frac{d\delta}{dt} = \omega - \omega_0$

**Spannungsausgang:**
$u_r = V \cdot \cos(\delta)$
$u_i = V \cdot \sin(\delta)$

Diese Gleichungen implementieren eine Frequenz-Wirkleistungs-Kopplung (f-P) und eine Spannungs-Blindleistungs-Kopplung (V-Q),
die typisch für das Droop-Verfahren ist.
=#
vertexms = [nw[VIndex(i)] for i in 1:nv(nw)];
edgems = [nw[EIndex(i)] for i in 1:ne(nw)];

@mtkmodel DroopInverter begin
    @components begin
        terminal = Terminal()
    end
    @parameters begin
        Pset, [description="Wirkleistungs-Sollwert", guess=1]
        Qset, [description="Blindleistungs-Sollwert", guess=0]
        Vset, [description="Spannungs-Sollwert", guess=1]
        ω₀=1, [description="Nennfrequenz"]
        Kp=1.0, [description="Wirkleistungs-Droop-Koeffizient"]
        Kq=0.01, [description="Blindleistungs-Droop-Koeffizient"]
        τ = 0.1, [description="Zeitkonstante des Leistungsfilters"]
    end
    @variables begin
        Pmeas(t), [description="Wirkleistungsmessung", guess=1]
        Qmeas(t), [description="Blindleistungsmessung", guess=0]
        Pfilt(t), [description="Gefilterte Wirkleistung", guess=1]
        Qfilt(t), [description="Gefilterte Blindleistung", guess=1]
        ω(t), [description="Frequenz"]
        δ(t), [description="Spannungswinkel", guess=0]
        V(t), [description="Spannungsbetrag"]
    end
    @equations begin
        Pmeas ~ terminal.u_r*terminal.i_r + terminal.u_i*terminal.i_i
        Qmeas ~ terminal.u_r*terminal.i_i - terminal.u_i*terminal.i_r
        τ * Dt(Pfilt) ~ Pmeas - Pfilt
        τ * Dt(Qfilt) ~ Qmeas - Qfilt
        ω ~ ω₀ - Kp * (Pfilt - Pset) ## Frequenz senken, wenn P höher als Sollwert
        V ~ Vset - Kq * (Qfilt - Qset) ## Spannung senken, wenn Q höher als Sollwert
        Dt(δ) ~ ω - ω₀
        terminal.u_r ~ V*cos(δ)
        terminal.u_i ~ V*sin(δ)
    end
end

@named inverter = DroopInverter()
mtkbus = MTKBus(inverter)

DROOP_IDX = 32
pfmodel = vertexms[DROOP_IDX].metadata[:pfmodel]
droopbus = Bus(mtkbus; pf=pfmodel, vidx=DROOP_IDX, name=:DroopInverter)
vertexms[DROOP_IDX] = droopbus

nw_droop = Network(vertexms, edgems)

pf = solve_powerflow!(nw_droop)
set_default!(nw_droop, VIndex(31,:load₊Vset), pf."vm [pu]"[31])
set_default!(nw_droop, VIndex(39,:load₊Vset), pf."vm [pu]"[39])
set_default!(nw_droop, VIndex(DROOP_IDX,:inverter₊Vset),  pf."vm [pu]"[DROOP_IDX])
OpPoDyn.initialize!(nw_droop)

dump_initial_state(nw_droop[VIndex(DROOP_IDX)])

u0_droop = NWState(nw_droop)
prob_droop = ODEProblem(nw_droop, copy(uflat(u0_droop)), (0,15), copy(pflat(u0_droop)); callback=get_callbacks(nw_droop))
sol_droop = solve(prob_droop, Rodas5P())
#=
## Simulation mit Wechselrichter und Vergleich

Nun simulieren wir das modifizierte Netzwerk und vergleichen die Ergebnisse mit der 
ursprünglichen Simulation.
=#
u0_droop = NWState(nw_droop)
prob_droop = ODEProblem(nw_droop, copy(uflat(u0_droop)), (0,15), copy(pflat(u0_droop)); callback=get_callbacks(nw_droop))
sol_droop = solve(prob_droop, Rodas5P())
let fig = Figure()
    ts = range(0.3, 15, length=1000)
    ax = Axis(fig[1, 1]; title="Spannungsbetrag an Bus $DROOP_IDX")
    lines!(ax, ts, sol(ts; idxs=VIndex(DROOP_IDX, :busbar₊u_mag)).u; label="Referenzlösung", linestyle=:dash)
    lines!(ax, ts, sol_droop(ts; idxs=VIndex(DROOP_IDX, :busbar₊u_mag)).u; label="Droop-Lösung")
    axislegend(ax)
    fig
end

#=
## Parameteroptimierung für den Wechselrichter (fortgeschrittenes Thema)

Als erweitertes Beispiel optimieren wir die Parameter des Wechselrichters, 
um das Systemverhalten zu verbessern.

Wir definieren eine Verlustfunktion, die die Abweichung zwischen der Original-Systemantwort 
und der Antwort des modifizierten Systems mit Wechselrichter misst:

$L(p) = \sum_{i,t} |x_{ref}(t)_i - x(t;p)_i|^2$

Wobei:
- $p = [K_p, K_q, \tau]$ die zu optimierenden Parameter sind
- $x_{ref}(t)$ die Referenzlösung des ursprünglichen Systems 
- $x(t;p)$ die Lösung des modifizierten Systems mit den Parametern $p$

Ziel ist es, Parameter $p$ zu finden, die diese Verlustfunktion minimieren.
=#
opt_ref = sol(0.3:0.1:10, idxs=[VIndex(1:39, :busbar₊u_r), VIndex(1:39, :busbar₊u_i)])
tunable_parameters = [:inverter₊Kp, :inverter₊Kq, :inverter₊τ]
tp_idx = SII.parameter_index(sol_droop, VIndex(DROOP_IDX, tunable_parameters))

cb_verbose[] = false
function loss(p)
    ## Berechnet die Verlustfunktion für einen gegebenen Parametersatz
    allp = similar(p, length(u0_droop.p))
    allp .= pflat(u0_droop.p)
    allp[tp_idx] .= p
    _sol = solve(prob_droop, Rodas5P(autodiff=true);
        p = allp, saveat = 0.01, tspan=(0.0, opt_ref.t[end]),
        initializealg = SciMLBase.NoInit(), 
    )
    SciMLBase.successful_retcode(_sol) || return Inf

    x = _sol(opt_ref.t; idxs=[VIndex(1:39, :busbar₊u_r), VIndex(1:39, :busbar₊u_i)])
    res = opt_ref.u - x.u
    return sum(abs2, reduce(vcat, res))
end

function plot_pset(this_p)
    ## Funktion zum Visualisieren der Systemantwort mit gegebenen Parametern
    if !(this_p isa Observable)
        this_p = Observable(this_p)
    end
    fig = Figure(size=(1000,500))
    busses = [3,4,25,DROOP_IDX]
    cols = 2
    rows = ceil(Int, length(busses) / cols)
    ts = range(0, 10, length=1000)
    ## Parameter aus dem letzten Optimierungszustand verwenden
    p_opt = @lift let
        _p = copy(pflat(u0_droop))
        _p[tp_idx] .= $this_p
        _p
    end
    ## Problem mit optimierten Parametern erstellen und lösen
    sol_opt = @lift solve(prob_droop, Rodas5P(); p=$p_opt)

    for (i, bus) in enumerate(busses)
        row, col = divrem(i-1, cols) .+ (0, 1)
        ax = Axis(fig[row+1, col]; title="Spannungsbetrag an Bus $bus")
        ylims!(ax, 0.9, 1.15)
        lines!(ax, ts, sol(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Referenz", linestyle=:solid, color=:blue)
        lines!(ax, ts, sol_droop(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Initiale Droop-Einstellung", linestyle=:dash, color=:red)
        dat = @lift $sol_opt(ts; idxs=VIndex(bus, :busbar₊u_mag)).u
        lines!(ax, ts, dat; label="Optimierte Droop-Einstellung", color=:green)
        i == 1 && axislegend(ax; position=:rb)
    end
    fig
end

p0 = sol_droop(sol_droop.t[begin], idxs=collect(VIndex(DROOP_IDX, tunable_parameters)))
optf = Optimization.OptimizationFunction((x, p) -> loss(x), Optimization.AutoForwardDiff())

pobs = Observable(p0)
plot_pset(pobs)
states = Any[]
callback = function (state, l)
    ## Callback-Funktion für den Optimierungsprozess
    push!(states, state)
    pobs[] = state.u
    println(l)
    return false
end
optprob = Optimization.OptimizationProblem(optf, p0; callback)
optsol = Optimization.solve(optprob, OptimizationPolyalgorithms.Optimisers.Adam(0.1), maxiters = 7)

fig = plot_pset(pobs)
record(fig, "droop_optimization.mp4", states; framerate=3) do s
    pobs[] = s.u
    fig
end

inspect(sol_droop)
