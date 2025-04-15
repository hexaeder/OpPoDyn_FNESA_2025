#=
# OpPoDyn.jl - Eine Bibliothek für Energiesystemdynamik
## 1 Einführung und Grundlagen
### 1.1 Einführung und Setup

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
using SciMLSensitivity, Optimization, OptimizationOptimisers
using LinearAlgebra
using CairoMakie, DataFrames, Graphs

#=
### 1.2 Laden des Netzwerks

Das zu simulierende IEEE 39-Bus-Netzwerk ist im `WorkshopCompanion`-Paket definiert,
da es hier den Rahmen sprengen würde.

Es handelt sich um ein 39-Bus-System mit 10 Generatoren und 19 Lasten (2 davon an Generator-Bussen).

Es kommen folgende Modelle zum Einsatz:
- Generatoren: 6th Order Sauer-Pai-Machine-Model mit Gov (TGOV1) und AVR (IEEEType1)
- Lasten: ZIP-Lasten
- Statische PI-Lines als Übertragungsleitungen
=#
@time nw = WorkshopCompanion.load_39bus()

#=
### 1.3 Inspektion von Modellkomponenten

OpPoDyn.jl basiert auf Komponentenmodellen, die miteinander verknüpft werden, um ein Gesamtsystem zu bilden.
Schauen wir uns einige dieser Komponenten genauer an.
=#

## inspizieren von modellen und metadaten

nw[VIndex(30)] #norelease
nw[VIndex(30)].metadata[:equations] #norelease
dump_initial_state(nw[VIndex(30)]) #norelease
nw[VIndex(30)].metadata[:pfmodel] #norelease

#=
## 2 Systeminitialisierung und Simulation
### 2.1 Leistungsflussberechnung

Bevor wir dynamische Simulationen durchführen können, müssen wir zunächst einen stabilen
Arbeitspunkt finden. Dies geschieht durch die Leistungsflussberechnung.
=#
OpPoDyn.solve_powerflow!(nw)

#=
Der Leistungsfluss bestimmt die "Interface-Variablen" unserer dynamischen
Simulation, das heißt die Spannungen aller Busse und die Ströme aller Leitungen.
=#

#=
### 2.2 Initialisierung der Komponenten

Durch die Leistungsflussberechnung kennen wir den Arbeitspunkt unseres Netzwerks.
Um dynamische Simulationen durchführen zu können, müssen wir alle dynamischen Komponenten
initialisieren.

Initialisieren bedeutet in diesem Fall, dass sich die dynamischen Modelle im
Arbeitspunkt in einem Gleichgewichtszustand befinden.

Wenn wir uns z.B. den Zustand eines Generators anschauen, sehen wir, dass
einige interne Zustände und Parameter noch nicht festgelegt sind.
=#

dump_initial_state(nw[VIndex(39)]; obs=false)

#=
Wir lösen dieses Problem, indem wir die "Interface"-Variablen Strom und Spannung
aus der Leistungsflussberechnung verwenden und freie interne Zustände $x$ und freie
interne Parameter $p$ so wählen, dass folgende Gleichungen erfüllt sind:

$$
\begin{aligned}
\dot{x} &= f(x, \color{red}i_{dq}\color{black}, p) =\color{red}0\color{black} \\
\color{red}u_{dq}\color{black} &= g(x, \color{red}i_{dq}\color{black}, p)
\end{aligned}
$$

=#
OpPoDyn.initialize!(nw)

#=
### 2.3 Definition einer Störung im Netzwerk

Prinzipiell sind wir jetzt soweit, eine dynamische Simulation durchzuführen.
Allerdings haben wir die internen Zustände und Parameter gerade so gewählt, dass sich
das dynamische System in einem Gleichgewichtszustand befindet, d.h. es passiert nichts.

Um Dynamik zu sehen, muss das System angeregt bzw. gestört werden.
Verschiedene Störungen kommen infrage, z.B.:
- Abschalten einer Leitung (n-1-Kriterium)
- Änderung einer Last
- Kurzschluss einer Leitung
- Abschalten eines Generators

Für diesen Workshop fokussieren wir uns auf den **Kurzschluss einer Leitung**.
Der Kurzschluss tritt entlang einer Leitung auf und wird nach 0,1 Sekunden
"behoben", indem die Leitung abgeschaltet wird.

Zu diesem Zweck hat unsere Leitung zwei zusätzliche interne Parameter:
- `pibranch₊shortcircuit`: Dieser Parameter wird auf 1 gesetzt, wenn ein Kurzschluss auftritt.
- `pibranch₊active`: Dieser Parameter wird auf 0 gesetzt, wenn die Leitung deaktiviert wird.
=#
AFFECTED_LINE = 11
nw[EIndex(AFFECTED_LINE)]
#=
Wir definieren sogenannte "Callbacks", um während der dynamischen Simulation zu vorgegebenen
Zeitpunkten diese Parameter zu ändern.
=#
_enable_short = ComponentAffect([], [:pibranch₊shortcircuit]) do u, p, ctx
    VERBOSE[] && @info "Aktiviere Kurzschluss auf Leitung $(ctx.src)=>$(ctx.dst) bei t = $(ctx.t)"
    p[:pibranch₊shortcircuit] = 1
end
shortcircuit_cb = PresetTimeComponentCallback(0.1, _enable_short)

#-

_disable_line = ComponentAffect([], [:pibranch₊active]) do u, p, ctx
    VERBOSE[] && @info "Deaktiviere Leitung $(ctx.src)=>$(ctx.dst) bei t = $(ctx.t)"
    p[:pibranch₊active] = 0
end
deactivate_cb = PresetTimeComponentCallback(0.2, _disable_line)

#=
Diese Störungen müssen wir nun einer Leitung zuweisen.
=#
set_callback!(nw, EIndex(AFFECTED_LINE),
    (shortcircuit_cb, deactivate_cb)
);

#=
Wir können erneut das entsprechende Line-Modell inspizieren, um den
hinzugefügten Callback zu sehen.
=#
nw[EIndex(AFFECTED_LINE)]

#=
### 2.4 Dynamische Simulation

Jetzt führen wir die eigentliche Simulation durch, um zu sehen, wie das System auf die
definierte Störung reagiert.
=#
u0 = NWState(nw)
prob = ODEProblem(nw, uflat(u0), (0,15), pflat(u0); callback=get_callbacks(nw))
sol = solve(prob, Rodas5P())

#=
### 2.5 Ergebnisanalyse

Nach der Simulation analysieren wir die Ergebnisse mit verschiedenen Plots.

#### Leistungsfluss in der betroffenen Leitung
=#
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Leistungsfluss in der betroffenen Leitung", xlabel="t [s]", ylabel="P [pu]")
    ts = range(0, 0.28,length=1000)
    lines!(ax, ts, sol(ts; idxs=EIndex(AFFECTED_LINE, :dst₊P)).u; label="P")
    axislegend(ax)
    fig
end

#=
#### Spannungen an benachbarten Bussen
=#
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Spannungen an benachbarten Bussen", xlabel="t [s]", ylabel="U mag [pu]")
    ts = range(0, 15, length=1000)
    lines!(ax, ts, sol(ts; idxs=VIndex(5, :busbar₊u_mag)).u; label="Spannungsbetrag an Bus 5")
    lines!(ax, ts, sol(ts; idxs=VIndex(8, :busbar₊u_mag)).u; label="Spannungsbetrag an Bus 8")
    axislegend(ax, position=:rb)
    fig
end

#=
#### Spannungsbeträge im gesamten Netzwerk
=#
let fig = Figure()
    ax = Axis(fig[1, 1]; title="Spannungsbeträge im gesamten Netzwerk")
    ylims!(ax, 0.9, 1.15)
    ts = range(0, 15, length=1000)
    for i in 1:39
        lines!(ax, ts, sol(ts; idxs=VIndex(i, :busbar₊u_mag)).u)
    end
    fig
end

#=
#### Interaktive Visualisierung
=#
## inspect(sol, reset=true, restart=true, display=ServerDisp())

#=
## 3 Integration eines Wechselrichters mit Droop-Regelung

Im nächsten Schritt modifizieren wir unser Netzwerk, indem wir einen Wechselrichter mit
Droop-Regelung hinzufügen. Dies demonstriert die Flexibilität von OpPoDyn.jl beim
Erstellen und Anpassen von Modellen.

Der Droop-Wechselrichter basiert auf folgenden Gleichungen:

**Leistungsmessung:**
$$
\begin{aligned}
P_{meas} &= u_r \cdot i_r + u_i \cdot i_i\\
Q_{meas} &= u_r \cdot i_i - u_i \cdot i_r
\end{aligned}
$$

**Leistungsfilterung:**
$$
\begin{aligned}
\tau \cdot \frac{dP_{filt}}{dt} &= P_{meas} - P_{filt} \\
\tau \cdot \frac{dQ_{filt}}{dt} &= Q_{meas} - Q_{filt}
\end{aligned}
$$

**Droop-Regelung:**
$$
\begin{aligned}
\omega &= \omega_0 - K_p \cdot (P_{filt} - P_{set}) \\
V &= V_{set} - K_q \cdot (Q_{filt} - Q_{set})
\end{aligned}
$$

**Spannungswinkel:**
$$
\begin{aligned}
\frac{d\delta}{dt} &= \omega - \omega_0
\end{aligned}
$$

**Spannungsausgang:**
$$
\begin{aligned}
u_r &= V \cdot \cos(\delta) \\
u_i &= V \cdot \sin(\delta)
\end{aligned}
$$

Diese Gleichungen implementieren eine Frequenz-Wirkleistungs-Kopplung (f-P) und eine Spannungs-Blindleistungs-Kopplung (V-Q),
die typisch für das Droop-Verfahren ist.

### 3.1 Definition einer neuen, dynamischen Netzwerkkomponente

Netzwerkkomponenten in OpPoDyn müssen dem sogenannten "Injector Interface" entsprechen.
Ein "Injector" ist ein "Einspeiser", also ein System mit einem `Terminal`.
```
      ┌───────────┐
(t)   │           │
 o←───┤  Injector │
      │           │
      └───────────┘
```

Die Definition eines neuen Einspeisers erfolgt gleichungsbasiert, die Syntax ähnelt hierbei
Modelica.
=#
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
end;

#=
### 3.2 Definition eines neuen, dynamischen Busmodels

Ein Bus-Modell vereint potentiell mehrere Injectors, beispielsweise einen Generator und einen Wechselrichter.
Im Allgemeinen besteht er aus einer `BusBar` und mehreren Injektoren.

```
 ┌───────────────────────────────────┐
 │ MTKBus             ┌───────────┐  │
 │  ┌──────────┐   ┌──┤ Generator │  │
 │  │          │   │  └───────────┘  │
 │  │  BusBar  ├───o                 │
 │  │          │   │  ┌───────────┐  │
 │  └──────────┘   └──┤ Load      │  │
 │                    └───────────┘  │
 └───────────────────────────────────┘
```

In unserem Fall haben wir nur einen Injektor, den Wechselrichter.
=#
@named inverter = DroopInverter()
mtkbus = MTKBus(inverter)
Bus(mtkbus)

#=
### 3.3 Aufbau eines Netzwerks mit Droop-Wechselrichter

Um den neuen Bus ins Netzwerk einzubauen, erzeugen wir ein neues Netzwerk auf Basis des bisherigen:
=#

DROOP_IDX = 32
vertexms = [nw[VIndex(i)] for i in 1:nv(nw)];
edgems = [nw[EIndex(i)] for i in 1:ne(nw)];
pfmodel = vertexms[DROOP_IDX].metadata[:pfmodel]
droopbus = Bus(mtkbus; pf=pfmodel, vidx=DROOP_IDX, name=:DroopInverter)
vertexms[DROOP_IDX] = droopbus
nw_droop = Network(vertexms, edgems)

#=
Für dieses neue Modell müssen wir die gleichen Initialisierungsschritte durchlaufen:
- Lösen des Leistungsflusses und
- Initialisierung der dynamischen Komponenten anhand des Leistungsfluss-Ergebnisses.
=#

pf = solve_powerflow!(nw_droop)
set_default!(nw_droop, VIndex(DROOP_IDX,:inverter₊Vset),  pf."vm [pu]"[DROOP_IDX])
OpPoDyn.initialize!(nw_droop)

#=
Wie auch bisher können wir die initialisierten Zustände inspizieren.
=#
dump_initial_state(nw_droop[VIndex(DROOP_IDX)]; obs=false)

#=
### 3.4 Simulation des Models mit Wechselrichter

Nun simulieren wir das modifizierte Netzwerk und vergleichen die Ergebnisse mit der
ursprünglichen Simulation.
=#
u0_droop = NWState(nw_droop)
prob_droop = ODEProblem(nw_droop, copy(uflat(u0_droop)), (0,15), copy(pflat(u0_droop)); callback=get_callbacks(nw_droop))
sol_droop = solve(prob_droop, Rodas5P());

#=
Wir können die Ergebnisse des neuen Netzwerks mit dem alten Vergleichen:
=#
let
    fig = Figure(size=(1000,500))
    busses = [3,4,25,DROOP_IDX]
    ts = range(0, 10, length=1000)
    for (i, bus) in enumerate(busses)
        row, col = divrem(i-1, 2) .+ (0, 1)
        ax = Axis(fig[row+1, col]; title="Spannungsbetrag an Bus $bus")
        ylims!(ax, 0.9, 1.15)
        lines!(ax, ts, sol(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Standard Netzwerk", linestyle=:solid, color=:blue)
        lines!(ax, ts, sol_droop(ts; idxs=VIndex(bus, :busbar₊u_mag)).u;
               label="Mit Droop Inverter", color=:green)
        i == 1 && axislegend(ax; position=:rb)
    end
    fig
end

#=
## 4 Parameteroptimierung

Als erweitertes Beispiel optimieren wir die Parameter des Wechselrichters,
um das Systemverhalten zu verbessern.

Wir definieren eine Verlustfunktion (Loss function), die die Abweichung zwischen der Original-Systemantwort
und der Antwort des modifizierten Systems mit Wechselrichter misst:

$$
L(p) = \sum_{i,t} |x_{ref}(t)_i - x(t;p)_i|^2
$$

Wobei:
- $p = [K_p, K_q, \tau]$ die zu optimierenden Parameter sind
- $x_{ref}(t)$ die Referenzlösung des ursprünglichen Systems
- $x(t;p)$ die Lösung des modifizierten Systems mit den Parametern $p$

Ziel ist es, Parameter $p$ zu finden, die diese Verlustfunktion minimieren.
=#
opt_ref = sol(0.3:0.1:10, idxs=[VIndex(1:39, :busbar₊u_r), VIndex(1:39, :busbar₊u_i)])
tunable_parameters = [:inverter₊Kp, :inverter₊Kq, :inverter₊τ]
tp_idx = SII.parameter_index(sol_droop, VIndex(DROOP_IDX, tunable_parameters))
VERBOSE[] = false

function loss(p)
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

p0 = sol_droop(sol_droop.t[begin], idxs=collect(VIndex(DROOP_IDX, tunable_parameters)))
optf = Optimization.OptimizationFunction((x, p) -> loss(x), Optimization.AutoForwardDiff())

states = Any[]
callback = function (state, l)
    push!(states, state)
    println("loss = ", l)
    return false
end
optprob = Optimization.OptimizationProblem(optf, p0; callback)
optsol = Optimization.solve(optprob, Optimisers.Adam(0.1), maxiters = 7)

#=
Als letzten Schritt wollen wir die Ergebnisse der Optimierung anschauen.
=#
pobs = Observable(p0)
function plot_pset(this_p)
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

fig = plot_pset(pobs)
Record(fig, states; framerate=3) do s
    pobs[] = s.u
    fig
end
