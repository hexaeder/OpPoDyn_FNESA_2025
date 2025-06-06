module WorkshopCompanion

# precompile all packages
using Graphs
using IJulia
using ModelingToolkit
using NetworkDynamics
using NetworkDynamicsInspector
using OpPoDyn
using OpPoDyn.Library
using OrdinaryDiffEqNonlinearSolve
using OrdinaryDiffEqRosenbrock
using PrecompileTools
using WGLMakie
using LinearAlgebra

export VERBOSE
const VERBOSE = Ref(true)

function load_39bus()
    ####
    #### Component Models
    ####

    # basic load model
    zip_load = ZIPLoad(;
        KpZ = 1.0,
        KpC = 0.0,
        KpI = 0.0,
        KqZ = 1.0,
        KqI = 0.0,
        KqC = 0.0,
        name = :load
    )

    # machine wihtoun controllers
    machine = SauerPaiMachine(; vf_input = false, τ_m_input = false, name = :machine)

    # controlled generator (and submodels)
    ctrl_machine = SauerPaiMachine(; name = :machine)
    avr = AVRTypeI(; ceiling_function = :quadratic, name = :avr)
    gov = TGOV1(; name = :gov)
    controlled_generator = CompositeInjector(
        ctrl_machine,
        avr,
        gov;
        name = :ctrld_gen
    )

    ####
    #### Bus models
    ####
    # by calling `Bus` on the mtkbus objects we force the symbolic simplification
    # to happen. later on `Bus(::VertexModel)` will just reconstruct the component
    # this may speed up cosntruction times of the network
    kirchoff_bus = Bus(MTKBus())
    load_bus = Bus(MTKBus(zip_load))
    controlled_gen_bus = Bus(MTKBus(controlled_generator))
    load_controlled_gen_bus = Bus(MTKBus(zip_load, controlled_generator))
    load_machine_bus = Bus(MTKBus(
        zip_load,
        SauerPaiMachine(; vf_input = false, τ_m_input = false, name = :machine)
    ))

    ####
    #### Line Models
    ####
    pi_branch = PiLine_fault(; name = :pibranch)
    pi_line = Line(MTKLine(pi_branch))

    ####
    #### Nodes
    ####
    vertexmodels = [
        Bus(
            kirchoff_bus;
            vidx = 1,
            pf = pfPQ(),
            name = :Bus_01,
        ),
        Bus(
            kirchoff_bus;
            vidx = 2,
            pf = pfPQ(),
            name = :Bus_02,
        ),
        Bus(
            load_bus;
            vidx = 3,
            pf = pfPQ(P = -3.22, Q = -0.024),
            name = :Bus_03,
            load₊Pset = -3.22,
            load₊Qset = -0.024,
        ),
        Bus(
            load_bus;
            vidx = 4,
            pf = pfPQ(P = -5.0, Q = -1.84),
            name = :Bus_04,
            load₊Pset = -5.0,
            load₊Qset = -1.84,
        ),
        Bus(
            kirchoff_bus;
            vidx = 5,
            pf = pfPQ(),
            name = :Bus_05,
        ),
        Bus(
            kirchoff_bus;
            vidx = 6,
            pf = pfPQ(),
            name = :Bus_06,
        ),
        Bus(
            load_bus;
            vidx = 7,
            pf = pfPQ(P = -2.338, Q = -0.84),
            name = :Bus_07,
            load₊Pset = -2.338,
            load₊Qset = -0.84,
        ),
        Bus(
            load_bus;
            vidx = 8,
            pf = pfPQ(P = -5.22, Q = -1.76),
            name = :Bus_08,
            load₊Pset = -5.22,
            load₊Qset = -1.76,
        ),
        Bus(
            kirchoff_bus;
            vidx = 9,
            pf = pfPQ(),
            name = :Bus_09,
        ),
        Bus(
            kirchoff_bus;
            vidx = 10,
            pf = pfPQ(),
            name = :Bus_10,
        ),
        Bus(
            kirchoff_bus;
            vidx = 11,
            pf = pfPQ(),
            name = :Bus_11,
        ),
        Bus(
            load_bus;
            vidx = 12,
            pf = pfPQ(P = -0.075, Q = -0.88),
            name = :Bus_12,
            load₊Pset = -0.075,
            load₊Qset = -0.88,
        ),
        Bus(
            kirchoff_bus;
            vidx = 13,
            pf = pfPQ(),
            name = :Bus_13,
        ),
        Bus(
            kirchoff_bus;
            vidx = 14,
            pf = pfPQ(),
            name = :Bus_14,
        ),
        Bus(
            load_bus;
            vidx = 15,
            pf = pfPQ(P = -3.2, Q = -1.53),
            name = :Bus_15,
            load₊Pset = -3.2,
            load₊Qset = -1.53,
        ),
        Bus(
            load_bus;
            vidx = 16,
            pf = pfPQ(P = -3.29, Q = -0.323),
            name = :Bus_16,
            load₊Pset = -3.29,
            load₊Qset = -0.323,
        ),
        Bus(
            kirchoff_bus;
            vidx = 17,
            pf = pfPQ(),
            name = :Bus_17,
        ),
        Bus(
            load_bus;
            vidx = 18,
            pf = pfPQ(P = -1.58, Q = -0.3),
            name = :Bus_18,
            load₊Pset = -1.58,
            load₊Qset = -0.3,
        ),
        Bus(
            kirchoff_bus;
            vidx = 19,
            pf = pfPQ(),
            name = :Bus_19,
        ),
        Bus(
            load_bus;
            vidx = 20,
            pf = pfPQ(P = -6.28, Q = -1.03),
            name = :Bus_20,
            load₊Pset = -6.28,
            load₊Qset = -1.03,
        ),
        Bus(
            load_bus;
            vidx = 21,
            pf = pfPQ(P = -2.74, Q = -1.15),
            name = :Bus_21,
            load₊Pset = -2.74,
            load₊Qset = -1.15,
        ),
        Bus(
            kirchoff_bus;
            vidx = 22,
            pf = pfPQ(),
            name = :Bus_22,
        ),
        Bus(
            load_bus;
            vidx = 23,
            pf = pfPQ(P = -2.475, Q = -0.846),
            name = :Bus_23,
            load₊Pset = -2.475,
            load₊Qset = -0.846,
        ),
        Bus(
            load_bus;
            vidx = 24,
            pf = pfPQ(P = -3.086, Q = 0.922),
            name = :Bus_24,
            load₊Pset = -3.086,
            load₊Qset = 0.922,
        ),
        Bus(
            load_bus;
            vidx = 25,
            pf = pfPQ(P = -2.24, Q = -0.472),
            name = :Bus_25,
            load₊Pset = -2.24,
            load₊Qset = -0.472,
        ),
        Bus(
            load_bus;
            vidx = 26,
            pf = pfPQ(P = -1.39, Q = -0.17),
            name = :Bus_26,
            load₊Pset = -1.39,
            load₊Qset = -0.17,
        ),
        Bus(
            load_bus;
            vidx = 27,
            pf = pfPQ(P = -2.81, Q = -0.755),
            name = :Bus_27,
            load₊Pset = -2.81,
            load₊Qset = -0.755,
        ),
        Bus(
            load_bus;
            vidx = 28,
            pf = pfPQ(P = -2.06, Q = -0.276),
            name = :Bus_28,
            load₊Pset = -2.06,
            load₊Qset = -0.276,
        ),
        Bus(
            load_bus;
            vidx = 29,
            pf = pfPQ(P = -2.835, Q = -0.269),
            name = :Bus_29,
            load₊Pset = -2.835,
            load₊Qset = -0.269,
        ),
        Bus(
            controlled_gen_bus;
            vidx = 30,
            pf = pfPV(P = 2.5, V = 1.0475),
            name = :Bus_30,
            ctrld_gen₊avr₊E1 = 3.546099,
            ctrld_gen₊avr₊E2 = 4.728132,
            ctrld_gen₊avr₊Ka = 5.0,
            ctrld_gen₊avr₊Ke = -0.0485,
            ctrld_gen₊avr₊Kf = 0.04,
            ctrld_gen₊avr₊Se1 = 0.08,
            ctrld_gen₊avr₊Se2 = 0.26,
            ctrld_gen₊avr₊Ta = 0.06,
            ctrld_gen₊avr₊Te = 0.25,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 4.199999809265137,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 1000.0,
            ctrld_gen₊machine₊T′_d0 = 10.199999809265137,
            ctrld_gen₊machine₊T′_q0 = 2.0,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 1.0,
            ctrld_gen₊machine₊X_ls = 0.125,
            ctrld_gen₊machine₊X_q = 0.6899999976158142,
            ctrld_gen₊machine₊X′_d = 0.3100000023841858,
            ctrld_gen₊machine₊X′_q = 0.5,
            ctrld_gen₊machine₊X″_d = 0.25,
            ctrld_gen₊machine₊X″_q = 0.25,
            ctrld_gen₊machine₊ω_b = 376.99111843077515,
        ),
        Bus(
            load_controlled_gen_bus;
            vidx = 31,
            pf = pfSlack(V = 0.982),
            name = :Bus_31,
            ctrld_gen₊avr₊E1 = 3.036437,
            ctrld_gen₊avr₊E2 = 4.048583,
            ctrld_gen₊avr₊Ka = 6.2,
            ctrld_gen₊avr₊Ke = -0.633,
            ctrld_gen₊avr₊Kf = 0.057,
            ctrld_gen₊avr₊Se1 = 0.66,
            ctrld_gen₊avr₊Se2 = 0.88,
            ctrld_gen₊avr₊Ta = 0.05,
            ctrld_gen₊avr₊Te = 0.405,
            ctrld_gen₊avr₊Tf = 0.5,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 4.328999996185303,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 700.0,
            ctrld_gen₊machine₊T′_d0 = 6.559999942779541,
            ctrld_gen₊machine₊T′_q0 = 1.5,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.065000057220459,
            ctrld_gen₊machine₊X_ls = 0.245,
            ctrld_gen₊machine₊X_q = 1.9739999771118164,
            ctrld_gen₊machine₊X′_d = 0.4878999888896942,
            ctrld_gen₊machine₊X′_q = 1.190000057220459,
            ctrld_gen₊machine₊X″_d = 0.3499999940395355,
            ctrld_gen₊machine₊X″_q = 0.3499999940395355,
            ctrld_gen₊machine₊ω_b = 376.99111843077515,
            load₊KpC = 0.0,
            load₊KpI = 0.0,
            load₊KpZ = 1.0,
            load₊KqC = 0.0,
            load₊KqI = 0.0,
            load₊KqZ = 1.0,
            load₊Pset = -0.09199999809265137,
            load₊Qset = -0.045999999046325686,
            load₊Vset = 0.982, # set to make initialization easier
        ),
        Bus(
            controlled_gen_bus;
            vidx = 32,
            pf = pfPV(P = 6.5, V = 0.9831),
            name = :Bus_32,
            ctrld_gen₊avr₊E1 = 2.342286,
            ctrld_gen₊avr₊E2 = 3.123048,
            ctrld_gen₊avr₊Ka = 5.0,
            ctrld_gen₊avr₊Ke = -0.0198,
            ctrld_gen₊avr₊Kf = 0.08,
            ctrld_gen₊avr₊Se1 = 0.13,
            ctrld_gen₊avr₊Se2 = 0.34,
            ctrld_gen₊avr₊Ta = 0.06,
            ctrld_gen₊avr₊Te = 0.5,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 4.474999904632568,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 800.0,
            ctrld_gen₊machine₊T′_d0 = 5.699999809265137,
            ctrld_gen₊machine₊T′_q0 = 1.5,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 1.996000051498413,
            ctrld_gen₊machine₊X_ls = 0.2432,
            ctrld_gen₊machine₊X_q = 1.8960000276565552,
            ctrld_gen₊machine₊X′_d = 0.42480000853538513,
            ctrld_gen₊machine₊X′_q = 0.7008000016212463,
            ctrld_gen₊machine₊X″_d = 0.36000001430511475,
            ctrld_gen₊machine₊X″_q = 0.36000001430511475,
            ctrld_gen₊machine₊ω_b = 376.99111843077515,
        ),
        Bus(
            controlled_gen_bus;
            vidx = 33,
            pf = pfPV(P = 6.32, V = 0.9972),
            name = :Bus_33,
            ctrld_gen₊avr₊E1 = 2.868069,
            ctrld_gen₊avr₊E2 = 3.824092,
            ctrld_gen₊avr₊Ka = 5.0,
            ctrld_gen₊avr₊Ke = -0.0525,
            ctrld_gen₊avr₊Kf = 0.08,
            ctrld_gen₊avr₊Se1 = 0.08,
            ctrld_gen₊avr₊Se2 = 0.314,
            ctrld_gen₊avr₊Ta = 0.06,
            ctrld_gen₊avr₊Te = 0.5,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 3.5749998092651367,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 800.0,
            ctrld_gen₊machine₊T′_d0 = 5.690000057220459,
            ctrld_gen₊machine₊T′_q0 = 1.5,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.0959999561309814,
            ctrld_gen₊machine₊X_ls = 0.236,
            ctrld_gen₊machine₊X_q = 2.063999891281128,
            ctrld_gen₊machine₊X′_d = 0.34880000352859497,
            ctrld_gen₊machine₊X′_q = 1.3279999494552612,
            ctrld_gen₊machine₊X″_d = 0.2800000011920929,
            ctrld_gen₊machine₊X″_q = 0.2800000011920929,
            ctrld_gen₊machine₊ω_b = 376.99111843077515,
        ),
        Bus(
            controlled_gen_bus;
            vidx = 34,
            pf = pfPV(P = 5.08, V = 1.0123),
            name = :Bus_34,
            ctrld_gen₊avr₊E1 = 3.926702,
            ctrld_gen₊avr₊E2 = 5.235602,
            ctrld_gen₊avr₊Ka = 40.0,
            ctrld_gen₊avr₊Ke = 1.0,
            ctrld_gen₊avr₊Kf = 0.03,
            ctrld_gen₊avr₊Se1 = 0.07,
            ctrld_gen₊avr₊Se2 = 0.91,
            ctrld_gen₊avr₊Ta = 0.02,
            ctrld_gen₊avr₊Te = 0.785,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 10.0,
            ctrld_gen₊avr₊vr_min = -10.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 4.333000183105469,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 600.0,
            ctrld_gen₊machine₊T′_d0 = 5.400000095367432,
            ctrld_gen₊machine₊T′_q0 = 0.4399999976158142,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.009999990463257,
            ctrld_gen₊machine₊X_ls = 0.162,
            ctrld_gen₊machine₊X_q = 1.8600000143051147,
            ctrld_gen₊machine₊X′_d = 0.3959999978542328,
            ctrld_gen₊machine₊X′_q = 0.49799999594688416,
            ctrld_gen₊machine₊X″_d = 0.2669999897480011,
            ctrld_gen₊machine₊X″_q = 0.2669999897480011,
            ctrld_gen₊machine₊ω_b = 376.99111843077515,
        ),
        Bus(
            controlled_gen_bus;
            vidx = 35,
            pf = pfPV(P = 6.5, V = 1.0493),
            name = :Bus_35,
            ctrld_gen₊avr₊E1 = 3.586801,
            ctrld_gen₊avr₊E2 = 4.782401,
            ctrld_gen₊avr₊Ka = 5.0,
            ctrld_gen₊avr₊Ke = -0.0419,
            ctrld_gen₊avr₊Kf = 0.0754,
            ctrld_gen₊avr₊Se1 = 0.064,
            ctrld_gen₊avr₊Se2 = 0.251,
            ctrld_gen₊avr₊Ta = 0.02,
            ctrld_gen₊avr₊Te = 0.471,
            ctrld_gen₊avr₊Tf = 1.246,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 4.349999904632568,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 800.0,
            ctrld_gen₊machine₊T′_d0 = 7.300000190734863,
            ctrld_gen₊machine₊T′_q0 = 0.4000000059604645,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.0320000648498535,
            ctrld_gen₊machine₊X_ls = 0.1792,
            ctrld_gen₊machine₊X_q = 1.9279999732971191,
            ctrld_gen₊machine₊X′_d = 0.4000000059604645,
            ctrld_gen₊machine₊X′_q = 0.651199996471405,
            ctrld_gen₊machine₊X″_d = 0.3199999928474426,
            ctrld_gen₊machine₊X″_q = 0.3199999928474426,
            ctrld_gen₊machine₊ω_b = 376.99111843077515
        ),
        Bus(
            controlled_gen_bus;
            vidx = 36,
            pf = pfPV(P = 5.6, V = 1.0635),
            name = :Bus_36,
            ctrld_gen₊avr₊E1 = 2.801724,
            ctrld_gen₊avr₊E2 = 3.735632,
            ctrld_gen₊avr₊Ka = 40.0,
            ctrld_gen₊avr₊Ke = 1.0,
            ctrld_gen₊avr₊Kf = 0.03,
            ctrld_gen₊avr₊Se1 = 0.53,
            ctrld_gen₊avr₊Se2 = 0.74,
            ctrld_gen₊avr₊Ta = 0.02,
            ctrld_gen₊avr₊Te = 0.73,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 6.5,
            ctrld_gen₊avr₊vr_min = -6.5,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 3.7710001468658447,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 700.0,
            ctrld_gen₊machine₊T′_d0 = 5.659999847412109,
            ctrld_gen₊machine₊T′_q0 = 1.5,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.065000057220459,
            ctrld_gen₊machine₊X_ls = 0.2254,
            ctrld_gen₊machine₊X_q = 2.0439999103546143,
            ctrld_gen₊machine₊X′_d = 0.34299999475479126,
            ctrld_gen₊machine₊X′_q = 1.3020000457763672,
            ctrld_gen₊machine₊X″_d = 0.30799999833106995,
            ctrld_gen₊machine₊X″_q = 0.30799999833106995,
            ctrld_gen₊machine₊ω_b = 376.99111843077515
        ),
        Bus(
            controlled_gen_bus;
            vidx = 37,
            pf = pfPV(P = 5.4, V = 1.0278),
            name = :Bus_37,
            ctrld_gen₊avr₊E1 = 3.191489,
            ctrld_gen₊avr₊E2 = 4.255319,
            ctrld_gen₊avr₊Ka = 5.0,
            ctrld_gen₊avr₊Ke = -0.047,
            ctrld_gen₊avr₊Kf = 0.0854,
            ctrld_gen₊avr₊Se1 = 0.072,
            ctrld_gen₊avr₊Se2 = 0.282,
            ctrld_gen₊avr₊Ta = 0.02,
            ctrld_gen₊avr₊Te = 0.528,
            ctrld_gen₊avr₊Tf = 1.26,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 1.0,
            ctrld_gen₊avr₊vr_min = -1.0,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 3.4710001945495605,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 700.0,
            ctrld_gen₊machine₊T′_d0 = 6.699999809265137,
            ctrld_gen₊machine₊T′_q0 = 0.4099999964237213,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.0299999713897705,
            ctrld_gen₊machine₊X_ls = 0.196,
            ctrld_gen₊machine₊X_q = 1.9600000381469727,
            ctrld_gen₊machine₊X′_d = 0.39899998903274536,
            ctrld_gen₊machine₊X′_q = 0.6377000212669373,
            ctrld_gen₊machine₊X″_d = 0.3149999976158142,
            ctrld_gen₊machine₊X″_q = 0.3149999976158142,
            ctrld_gen₊machine₊ω_b = 376.99111843077515
        ),
        Bus(
            controlled_gen_bus;
            vidx = 38,
            pf = pfPV(P = 8.3, V = 1.0265),
            name = :Bus_38,
            ctrld_gen₊avr₊E1 = 4.256757,
            ctrld_gen₊avr₊E2 = 5.675676,
            ctrld_gen₊avr₊Ka = 40.0,
            ctrld_gen₊avr₊Ke = 1.0,
            ctrld_gen₊avr₊Kf = 0.03,
            ctrld_gen₊avr₊Se1 = 0.62,
            ctrld_gen₊avr₊Se2 = 0.85,
            ctrld_gen₊avr₊Ta = 0.02,
            ctrld_gen₊avr₊Te = 1.4,
            ctrld_gen₊avr₊Tf = 1.0,
            ctrld_gen₊avr₊Tr = 0.01,
            ctrld_gen₊avr₊vr_max = 10.5,
            ctrld_gen₊avr₊vr_min = -10.5,
            ctrld_gen₊gov₊DT = 0,
            ctrld_gen₊gov₊R = 0.05,
            ctrld_gen₊gov₊T1 = 0.5,
            ctrld_gen₊gov₊T2 = 2.1,
            ctrld_gen₊gov₊T3 = 7.2,
            ctrld_gen₊gov₊V_max = 1.0,
            ctrld_gen₊gov₊V_min = 0.0,
            ctrld_gen₊gov₊ω_ref = 1,
            ctrld_gen₊machine₊D = 0,
            ctrld_gen₊machine₊H = 3.450000047683716,
            ctrld_gen₊machine₊R_s = 0.0,
            ctrld_gen₊machine₊S_b = 100,
            ctrld_gen₊machine₊Sn = 1000.0,
            ctrld_gen₊machine₊T′_d0 = 4.789999961853027,
            ctrld_gen₊machine₊T′_q0 = 1.9600000381469727,
            ctrld_gen₊machine₊T″_d0 = 0.05000000074505806,
            ctrld_gen₊machine₊T″_q0 = 0.03500000014901161,
            ctrld_gen₊machine₊V_b = 16.5,
            ctrld_gen₊machine₊Vn = 16.5,
            ctrld_gen₊machine₊X_d = 2.1059999465942383,
            ctrld_gen₊machine₊X_ls = 0.298,
            ctrld_gen₊machine₊X_q = 2.049999952316284,
            ctrld_gen₊machine₊X′_d = 0.5699999928474426,
            ctrld_gen₊machine₊X′_q = 0.5870000123977661,
            ctrld_gen₊machine₊X″_d = 0.44999998807907104,
            ctrld_gen₊machine₊X″_q = 0.44999998807907104,
            ctrld_gen₊machine₊ω_b = 376.99111843077515
        ),
        Bus(
            load_machine_bus;
            vidx = 39,
            pf = pfPV(P = -1.04, V = 1.03),
            name = :Bus_39,
            machine₊D = 0,
            machine₊H = 5.0,
            machine₊R_s = 0.0,
            machine₊S_b = 100,
            machine₊Sn = 10000.0,
            machine₊T′_d0 = 7.0,
            machine₊T′_q0 = 0.699999988079071,
            machine₊T″_d0 = 0.05000000074505806,
            machine₊T″_q0 = 0.03500000014901161,
            machine₊V_b = 345.0,
            machine₊Vn = 345.0,
            machine₊X_d = 2.0,
            machine₊X_ls = 0.3,
            machine₊X_q = 1.899999976158142,
            machine₊X′_d = 0.6000000238418579,
            machine₊X′_q = 0.800000011920929,
            machine₊X″_d = 0.4000000059604645,
            machine₊X″_q = 0.4000000059604645,
            machine₊ω_b = 376.99111843077515,
            load₊KpC = 0.0,
            load₊KpI = 0.0,
            load₊KpZ = 1.0,
            load₊KqC = 0.0,
            load₊KqI = 0.0,
            load₊KqZ = 1.0,
            load₊Pset = -11.04,
            load₊Qset = -2.5,
            load₊Vset = 1.03, # set to make initialization easier
        )
    ]

    edgemodels = [
        Line(
            pi_line;
            src = 1, dst = 2,
            name = :Line_01_02,
            pibranch₊B_dst = 0.34934980775013186,
            pibranch₊B_src = 0.34934980775013186,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0035000008081267795,
            pibranch₊X = 0.041100002833102334,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 1, dst = 39,
            name = :Line_01_39,
            pibranch₊B_dst = 0.37500083737865836,
            pibranch₊B_src = 0.37500083737865836,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.001000000008692344,
            pibranch₊X = 0.025000000993410747,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 2, dst = 3,
            name = :Line_02_03,
            pibranch₊B_dst = 0.12859993746580536,
            pibranch₊B_src = 0.12859993746580536,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0012999997427097568,
            pibranch₊X = 0.015100000184657953,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 2, dst = 25,
            name = :Line_02_25,
            pibranch₊B_dst = 0.07299967653043317,
            pibranch₊B_src = 0.07299967653043317,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.006999999645050112,
            pibranch₊X = 0.008600000003290073,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 2, dst = 30,
            name = :Line_02_30,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0,
            pibranch₊X = 0.01810000091791153,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9756097560975611,
        ),

        Line(
            pi_line;
            src = 3, dst = 4,
            name = :Line_03_04,
            pibranch₊B_dst = 0.11069922581586487,
            pibranch₊B_src = 0.11069922581586487,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0013000000512187267,
            pibranch₊X = 0.021300001215596744,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 3, dst = 18,
            name = :Line_03_18,
            pibranch₊B_dst = 0.10689967736603885,
            pibranch₊B_src = 0.10689967736603885,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0010999999777895828,
            pibranch₊X = 0.013300000474651278,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 4, dst = 5,
            name = :Line_04_05,
            pibranch₊B_dst = 0.06710000454913279,
            pibranch₊B_src = 0.06710000454913279,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0008000000380388057,
            pibranch₊X = 0.01280000060862089,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 4, dst = 14,
            name = :Line_04_14,
            pibranch₊B_dst = 0.0690997502600336,
            pibranch₊B_src = 0.0690997502600336,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0007999999450699972,
            pibranch₊X = 0.01290000096642154,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 5, dst = 6,
            name = :Line_05_06,
            pibranch₊B_dst = 0.02170006756413536,
            pibranch₊B_src = 0.02170006756413536,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.00019999997696545915,
            pibranch₊X = 0.002600000168695795,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 5, dst = 8,
            name = :Line_05_08,
            pibranch₊B_dst = 0.07380036891452198,
            pibranch₊B_src = 0.07380036891452198,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0007999999671506447,
            pibranch₊X = 0.011200000652729084,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 6, dst = 7,
            name = :Line_06_07,
            pibranch₊B_dst = 0.05650008418231701,
            pibranch₊B_src = 0.05650008418231701,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0006000000992521584,
            pibranch₊X = 0.009200000227121108,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 6, dst = 11,
            name = :Line_06_11,
            pibranch₊B_dst = 0.06945033397823791,
            pibranch₊B_src = 0.06945033397823791,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0007000001105582384,
            pibranch₊X = 0.008200000495060337,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 6, dst = 31,
            name = :Line_06_31,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0,
            pibranch₊X = 0.024999999574252536,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9345794392523364,
        ),

        Line(
            pi_line;
            src = 7, dst = 8,
            name = :Line_07_08,
            pibranch₊B_dst = 0.03900006961213349,
            pibranch₊B_src = 0.03900006961213349,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0004000000471277332,
            pibranch₊X = 0.004600000113560554,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 8, dst = 9,
            name = :Line_08_09,
            pibranch₊B_dst = 0.19020092997037732,
            pibranch₊B_src = 0.19020092997037732,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0022999994613120225,
            pibranch₊X = 0.036300001042454046,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 9, dst = 39,
            name = :Line_09_39,
            pibranch₊B_dst = 0.6000004503542706,
            pibranch₊B_src = 0.6000004503542706,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.001000000008692344,
            pibranch₊X = 0.025000000993410747,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 10, dst = 11,
            name = :Line_10_11,
            pibranch₊B_dst = 0.03645007677249099,
            pibranch₊B_src = 0.03645007677249099,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0004000000361641648,
            pibranch₊X = 0.0043000000016450365,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 10, dst = 13,
            name = :Line_10_13,
            pibranch₊B_dst = 0.03645007677249099,
            pibranch₊B_src = 0.03645007677249099,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0004000000361641648,
            pibranch₊X = 0.0043000000016450365,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 10, dst = 32,
            name = :Line_10_32,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0,
            pibranch₊X = 0.019999999552965164,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9345794392523364,
        ),

        Line(
            pi_line;
            src = 12, dst = 11,
            name = :Line_12_11,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.001599999920775493,
            pibranch₊X = 0.043499981363614396,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9940357850526872,
        ),

        Line(
            pi_line;
            src = 12, dst = 13,
            name = :Line_12_13,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.001599999920775493,
            pibranch₊X = 0.043499981363614396,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9940357850526872,
        ),

        Line(
            pi_line;
            src = 13, dst = 14,
            name = :Line_13_14,
            pibranch₊B_dst = 0.08615023233953206,
            pibranch₊B_src = 0.08615023233953206,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0008999999092163725,
            pibranch₊X = 0.010100000562867662,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 14, dst = 15,
            name = :Line_14_15,
            pibranch₊B_dst = 0.18299926773667938,
            pibranch₊B_src = 0.18299926773667938,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0017999998116882212,
            pibranch₊X = 0.021700000723826482,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 15, dst = 16,
            name = :Line_15_16,
            pibranch₊B_dst = 0.08550016573713853,
            pibranch₊B_src = 0.08550016573713853,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0008999998318071515,
            pibranch₊X = 0.009399999981235977,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 16, dst = 17,
            name = :Line_16_17,
            pibranch₊B_dst = 0.06710031027017067,
            pibranch₊B_src = 0.06710031027017067,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0007000001127483577,
            pibranch₊X = 0.00890000011520559,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 16, dst = 19,
            name = :Line_16_19,
            pibranch₊B_dst = 0.1519991827766055,
            pibranch₊B_src = 0.1519991827766055,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0015999997404123638,
            pibranch₊X = 0.019500000544103637,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 16, dst = 21,
            name = :Line_16_21,
            pibranch₊B_dst = 0.1274000549668954,
            pibranch₊B_src = 0.1274000549668954,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.000800000084957908,
            pibranch₊X = 0.013500000228766145,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 16, dst = 24,
            name = :Line_16_24,
            pibranch₊B_dst = 0.03400016003740206,
            pibranch₊B_src = 0.03400016003740206,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.000300000054881718,
            pibranch₊X = 0.00590000043828006,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 17, dst = 18,
            name = :Line_17_18,
            pibranch₊B_dst = 0.06594968328342747,
            pibranch₊B_src = 0.06594968328342747,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0007000001105582384,
            pibranch₊X = 0.008200000495060337,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 17, dst = 27,
            name = :Line_17_27,
            pibranch₊B_dst = 0.16079999806656406,
            pibranch₊B_src = 0.16079999806656406,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0012999998392540593,
            pibranch₊X = 0.017300000364380796,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 19, dst = 20,
            name = :Line_19_20,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0006999999284744263,
            pibranch₊X = 0.013799998164176942,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9433962264150942,
        ),

        Line(
            pi_line;
            src = 19, dst = 33,
            name = :Line_19_33,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.000699999975040555,
            pibranch₊X = 0.014199993573129177,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9345794392523364,
        ),

        Line(
            pi_line;
            src = 20, dst = 34,
            name = :Line_20_34,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0009000000233451525,
            pibranch₊X = 0.01800000046690305,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.991080277736662,
        ),

        Line(
            pi_line;
            src = 21, dst = 22,
            name = :Line_21_22,
            pibranch₊B_dst = 0.1282504022879528,
            pibranch₊B_src = 0.1282504022879528,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0008000001171756499,
            pibranch₊X = 0.01400000009479653,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 22, dst = 23,
            name = :Line_22_23,
            pibranch₊B_dst = 0.09230039064711089,
            pibranch₊B_src = 0.09230039064711089,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0006000000435523298,
            pibranch₊X = 0.009600000696837276,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 22, dst = 35,
            name = :Line_22_35,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0,
            pibranch₊X = 0.014299999922513962,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9756097560975611,
        ),

        Line(
            pi_line;
            src = 23, dst = 24,
            name = :Line_23_24,
            pibranch₊B_dst = 0.18050128030143106,
            pibranch₊B_src = 0.18050128030143106,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.002199999725987236,
            pibranch₊X = 0.03500000215996419,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 23, dst = 36,
            name = :Line_23_36,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0004999999489103045,
            pibranch₊X = 0.02720000488417489,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1.0,
        ),

        Line(
            pi_line;
            src = 25, dst = 26,
            name = :Line_25_26,
            pibranch₊B_dst = 0.2564997461504503,
            pibranch₊B_src = 0.2564997461504503,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0031999999126759646,
            pibranch₊X = 0.03230000211421096,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 25, dst = 37,
            name = :Line_25_37,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0005999999786061899,
            pibranch₊X = 0.023200001035417826,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9756097560975611,
        ),

        Line(
            pi_line;
            src = 26, dst = 27,
            name = :Line_26_27,
            pibranch₊B_dst = 0.11979967705921879,
            pibranch₊B_src = 0.11979967705921879,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0014000001078834552,
            pibranch₊X = 0.014700000676428217,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 26, dst = 28,
            name = :Line_26_28,
            pibranch₊B_dst = 0.3900985890418224,
            pibranch₊B_src = 0.3900985890418224,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.004299999919858043,
            pibranch₊X = 0.04740000037589605,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 26, dst = 29,
            name = :Line_26_29,
            pibranch₊B_dst = 0.5144984478217224,
            pibranch₊B_src = 0.5144984478217224,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.00569999994089206,
            pibranch₊X = 0.06250000248352687,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 28, dst = 29,
            name = :Line_28_29,
            pibranch₊B_dst = 0.12450040614505094,
            pibranch₊B_src = 0.12450040614505094,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.0014000000258129486,
            pibranch₊X = 0.015100000184657953,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 1,
        ),

        Line(
            pi_line;
            src = 29, dst = 38,
            name = :Line_29_38,
            pibranch₊B_dst = 0.0,
            pibranch₊B_src = 0.0,
            pibranch₊G_dst = 0.0,
            pibranch₊G_src = 0.0,
            pibranch₊R = 0.000800000037997961,
            pibranch₊X = 0.015600000321865082,
            pibranch₊active = 1,
            pibranch₊r_dst = 1,
            pibranch₊r_src = 0.9756097560975611,
        )
    ]
    nw = Network(vertexmodels, edgemodels)
end

@compile_workload begin
    nw = WorkshopCompanion.load_39bus()
    OpPoDyn.solve_powerflow!(nw)
    v31_mag = norm(get_initial_state(nw, VIndex(31, [:busbar₊u_r, :busbar₊u_i])))
    v39_mag = norm(get_initial_state(nw, VIndex(39, [:busbar₊u_r, :busbar₊u_i])))
    set_default!(nw, VIndex(31,:load₊Vset), v31_mag)
    set_default!(nw, VIndex(39,:load₊Vset), v39_mag)
    OpPoDyn.initialize!(nw; verbose=false)
    # Setup and solve the system for a short simulation
    u0 = NWState(nw)
    prob = ODEProblem(nw, uflat(u0), (0, 0.1), pflat(u0))
    solve(prob, Rodas5P())
end

end # module WorkshopCompanion
