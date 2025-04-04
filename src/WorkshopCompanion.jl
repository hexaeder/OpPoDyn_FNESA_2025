module WorkshopCompanion

# precompile all packages
using Graphs
using IJulia
using ModelingToolkit
using NetworkDynamics
using NetworkDynamicsInspector
using OpPoDyn
using OrdinaryDiffEqNonlinearSolve
using OrdinaryDiffEqRosenbrock
using PrecompileTools
using WGLMakie

function load_ieee39_bus()

  # KirchhoffBus:
  #   CONSTRUCTOR: MTKBus

  # ZIPLoad:
  #   CONSTRUCTOR: ZIPLoad
  #   KpZ: 1.0
  #   KpC: 0.0
  #   KpI: 0.0
  #   KqZ: 1.0
  #   KqI: 0.0
  #   KqC: 0.0
  #   # Pset defined in bus
  #   name: :load

  # LoadBus:
  #   CONSTRUCTOR: MTKBus
  #   ARGS:
  #     - Models.ZIPLoad

  # ## Base Machine model
  # Machine:
  #   CONSTRUCTOR: SauerPaiMachine
  #   name: :machine

  # AVRTypeI:
  #   CONSTRUCTOR: AVRTypeI
  #   ceiling_function: :quadratic
  #   name: :avr

  # TGOV1:
  #   CONSTRUCTOR: TGOV1
  #   name: :gov

  # ControlledGenerator:
  #   CONSTRUCTOR: CompositeInjector
  #   ARGS:
  #     - Models.Machine
  #     - Models.AVRTypeI
  #     - Models.TGOV1
  #   name: :ctrld_gen

  # ControlledGenBus:
  #   CONSTRUCTOR: MTKBus
  #   ARGS:
  #     - Models.ControlledGenerator

  # LoadControlledGenBus:
  #   CONSTRUCTOR: MTKBus
  #   ARGS:
  #     - Models.ZIPLoad
  #     - Models.ControlledGenerator

  # LoadMachineBus:
  #   CONSTRUCTOR: MTKBus
  #   ARGS:
  #     - Models.ZIPLoad
  #     - MODEL: Models.Machine
  #       vf_input: false
  #       τ_m_input: false
    
    # Define model components

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
    kirchoff_bus = MTKBus()
    load_bus = MTKBus(zip_load)
    controlled_gen_bus = MTKBus(controlled_generator)
    load_controlled_gen_bus = MTKBus(zip_load, controlled_generator)
    load_machine_bus = MTKBus(
        zip_load,
        SauerPaiMachine(; vf_input = false, τ_m_input = false, name = :machine)
    )

    ####
    #### Line Models
    ####
    pi_branch = PiLine_fault(; name = :pibranch)
    pi_line = MTKLine(pi_branch)

    ####
    #### Nodes
    ####

  # 1:
  #   CONSTRUCTOR: Bus
  #   ARGS:
  #     - MODEL: Models.KirchhoffBus
  #   pf: Models.PF_PQ
  #   name: :Bus_01
  # 2:
  #   CONSTRUCTOR: Bus
  #   ARGS:
  #     - MODEL: Models.KirchhoffBus
  #   pf: Models.PF_PQ
  #   name: :Bus_02
  # 3:
  #   CONSTRUCTOR: Bus
  #   ARGS:
  #     - MODEL: Models.LoadBus
  #       ARGS[1].Pset: -3.22
  #       ARGS[1].Qset: -0.024
  #   pf:
  #      MODEL: Models.PF_PQ
  #      P: -3.22
  #      Q: -0.024
  #   name: :Bus_03
    vertexmodels = [
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_01,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_02,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -3.22, Q = -0.024),
            name = :Bus_03,
            load₊Pset = -3.22,
            load₊Qset = -0.024,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -5.0, Q = -1.84),
            name = :Bus_04,
            load₊Pset = -5.0,
            load₊Qset = -1.84,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_05,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_06,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.338, Q = -0.84),
            name = :Bus_07,
            load₊Pset = -2.338,
            load₊Qset = -0.84,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -5.22, Q = -1.76),
            name = :Bus_08,
            load₊Pset = -5.22,
            load₊Qset = -1.76,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_09,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_10,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_11,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -0.075, Q = -0.88),
            name = :Bus_12,
            load₊Pset = -0.075,
            load₊Qset = -0.88,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_13,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_14,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -3.2, Q = -1.53),
            name = :Bus_15,
            load₊Pset = -3.2,
            load₊Qset = -1.53,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -3.29, Q = -0.323),
            name = :Bus_16,
            load₊Pset = -3.29,
            load₊Qset = -0.323,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_17,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -1.58, Q = -0.3),
            name = :Bus_18,
            load₊Pset = -1.58,
            load₊Qset = -0.3,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_19,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -6.28, Q = -1.03),
            name = :Bus_20,
            load₊Pset = -6.28,
            load₊Qset = -1.03,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.74, Q = -1.15),
            name = :Bus_21,
            load₊Pset = -2.74,
            load₊Qset = -1.15,
        ),
        Bus(
            kirchoff_bus;
            pf = pfPQ(),
            name = :Bus_22,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.475, Q = -0.846),
            name = :Bus_23,
            load₊Pset = -2.475,
            load₊Qset = -0.846,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -3.086, Q = 0.922),
            name = :Bus_24,
            load₊Pset = -3.086,
            load₊Qset = 0.922,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.24, Q = -0.472),
            name = :Bus_25,
            load₊Pset = -2.24,
            load₊Qset = -0.472,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -1.39, Q = -0.17),
            name = :Bus_26,
            load₊Pset = -1.39,
            load₊Qset = -0.17,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.81, Q = -0.755),
            name = :Bus_27,
            load₊Pset = -2.81,
            load₊Qset = -0.755,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.06, Q = -0.276),
            name = :Bus_28,
            load₊Pset = -2.06,
            load₊Qset = -0.276,
        ),
        Bus(
            load_bus;
            pf = pfPQ(P = -2.835, Q = -0.269),
            name = :Bus_29,
            load₊Pset = -2.835,
            load₊Qset = -0.269,
        )
    ];
    length(vertexmodels)

    # Generator buses
    [
        Bus(
            controlled_gen_bus;
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
        )
        Bus(
            controlled_gen_bus;
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
  35: # Machine with AVR/Gov
    CONSTRUCTOR: Bus
    ARGS:
      - MODEL: Models.ControlledGenBus
    name: :Bus_35
    ctrld_gen₊avr₊E1: 3.586801
    ctrld_gen₊avr₊E2: 4.782401
    ctrld_gen₊avr₊Ka: 5.0
    ctrld_gen₊avr₊Ke: -0.0419
    ctrld_gen₊avr₊Kf: 0.0754
    ctrld_gen₊avr₊Se1: 0.064
    ctrld_gen₊avr₊Se2: 0.251
    ctrld_gen₊avr₊Ta: 0.02
    ctrld_gen₊avr₊Te: 0.471
    ctrld_gen₊avr₊Tf: 1.246
    ctrld_gen₊avr₊Tr: 0.01
    ctrld_gen₊avr₊vr_max: 1.0
    ctrld_gen₊avr₊vr_min: -1.0
    ctrld_gen₊gov₊DT: 0
    ctrld_gen₊gov₊R: 0.05
    ctrld_gen₊gov₊T1: 0.5
    ctrld_gen₊gov₊T2: 2.1
    ctrld_gen₊gov₊T3: 7.2
    ctrld_gen₊gov₊V_max: 1.0
    ctrld_gen₊gov₊V_min: 0.0
    ctrld_gen₊gov₊ω_ref: 1
    ctrld_gen₊machine₊D: 0
    ctrld_gen₊machine₊H: 4.349999904632568
    ctrld_gen₊machine₊R_s: 0.0
    ctrld_gen₊machine₊S_b: 100
    ctrld_gen₊machine₊Sn: 800.0
    ctrld_gen₊machine₊T′_d0: 7.300000190734863
    ctrld_gen₊machine₊T′_q0: 0.4000000059604645
    ctrld_gen₊machine₊T″_d0: 0.05000000074505806
    ctrld_gen₊machine₊T″_q0: 0.03500000014901161
    ctrld_gen₊machine₊V_b: 16.5
    ctrld_gen₊machine₊Vn: 16.5
    ctrld_gen₊machine₊X_d: 2.0320000648498535
    ctrld_gen₊machine₊X_ls: 0.1792
    ctrld_gen₊machine₊X_q: 1.9279999732971191
    ctrld_gen₊machine₊X′_d: 0.4000000059604645
    ctrld_gen₊machine₊X′_q: 0.651199996471405
    ctrld_gen₊machine₊X″_d: 0.3199999928474426
    ctrld_gen₊machine₊X″_q: 0.3199999928474426
    ctrld_gen₊machine₊ω_b: 376.99111843077515
    pf:
      MODEL: Models.PF_PV
      P: 6.5
      V: 1.0493

  36: # Machine with AVR/Gov
    CONSTRUCTOR: Bus
    ARGS:
      - MODEL: Models.ControlledGenBus
    name: :Bus_36
    ctrld_gen₊avr₊E1: 2.801724
    ctrld_gen₊avr₊E2: 3.735632
    ctrld_gen₊avr₊Ka: 40.0
    ctrld_gen₊avr₊Ke: 1.0
    ctrld_gen₊avr₊Kf: 0.03
    ctrld_gen₊avr₊Se1: 0.53
    ctrld_gen₊avr₊Se2: 0.74
    ctrld_gen₊avr₊Ta: 0.02
    ctrld_gen₊avr₊Te: 0.73
    ctrld_gen₊avr₊Tf: 1.0
    ctrld_gen₊avr₊Tr: 0.01
    ctrld_gen₊avr₊vr_max: 6.5
    ctrld_gen₊avr₊vr_min: -6.5
    ctrld_gen₊gov₊DT: 0
    ctrld_gen₊gov₊R: 0.05
    ctrld_gen₊gov₊T1: 0.5
    ctrld_gen₊gov₊T2: 2.1
    ctrld_gen₊gov₊T3: 7.2
    ctrld_gen₊gov₊V_max: 1.0
    ctrld_gen₊gov₊V_min: 0.0
    ctrld_gen₊gov₊ω_ref: 1
    ctrld_gen₊machine₊D: 0
    ctrld_gen₊machine₊H: 3.7710001468658447
    ctrld_gen₊machine₊R_s: 0.0
    ctrld_gen₊machine₊S_b: 100
    ctrld_gen₊machine₊Sn: 700.0
    ctrld_gen₊machine₊T′_d0: 5.659999847412109
    ctrld_gen₊machine₊T′_q0: 1.5
    ctrld_gen₊machine₊T″_d0: 0.05000000074505806
    ctrld_gen₊machine₊T″_q0: 0.03500000014901161
    ctrld_gen₊machine₊V_b: 16.5
    ctrld_gen₊machine₊Vn: 16.5
    ctrld_gen₊machine₊X_d: 2.065000057220459
    ctrld_gen₊machine₊X_ls: 0.2254
    ctrld_gen₊machine₊X_q: 2.0439999103546143
    ctrld_gen₊machine₊X′_d: 0.34299999475479126
    ctrld_gen₊machine₊X′_q: 1.3020000457763672
    ctrld_gen₊machine₊X″_d: 0.30799999833106995
    ctrld_gen₊machine₊X″_q: 0.30799999833106995
    ctrld_gen₊machine₊ω_b: 376.99111843077515
    pf:
      MODEL: Models.PF_PV
      P: 5.6
      V: 1.0635

  37: # Machine with AVR/Gov
    CONSTRUCTOR: Bus
    ARGS:
      - MODEL: Models.ControlledGenBus
    name: :Bus_37
    ctrld_gen₊avr₊E1: 3.191489
    ctrld_gen₊avr₊E2: 4.255319
    ctrld_gen₊avr₊Ka: 5.0
    ctrld_gen₊avr₊Ke: -0.047
    ctrld_gen₊avr₊Kf: 0.0854
    ctrld_gen₊avr₊Se1: 0.072
    ctrld_gen₊avr₊Se2: 0.282
    ctrld_gen₊avr₊Ta: 0.02
    ctrld_gen₊avr₊Te: 0.528
    ctrld_gen₊avr₊Tf: 1.26
    ctrld_gen₊avr₊Tr: 0.01
    ctrld_gen₊avr₊vr_max: 1.0
    ctrld_gen₊avr₊vr_min: -1.0
    ctrld_gen₊gov₊DT: 0
    ctrld_gen₊gov₊R: 0.05
    ctrld_gen₊gov₊T1: 0.5
    ctrld_gen₊gov₊T2: 2.1
    ctrld_gen₊gov₊T3: 7.2
    ctrld_gen₊gov₊V_max: 1.0
    ctrld_gen₊gov₊V_min: 0.0
    ctrld_gen₊gov₊ω_ref: 1
    ctrld_gen₊machine₊D: 0
    ctrld_gen₊machine₊H: 3.4710001945495605
    ctrld_gen₊machine₊R_s: 0.0
    ctrld_gen₊machine₊S_b: 100
    ctrld_gen₊machine₊Sn: 700.0
    ctrld_gen₊machine₊T′_d0: 6.699999809265137
    ctrld_gen₊machine₊T′_q0: 0.4099999964237213
    ctrld_gen₊machine₊T″_d0: 0.05000000074505806
    ctrld_gen₊machine₊T″_q0: 0.03500000014901161
    ctrld_gen₊machine₊V_b: 16.5
    ctrld_gen₊machine₊Vn: 16.5
    ctrld_gen₊machine₊X_d: 2.0299999713897705
    ctrld_gen₊machine₊X_ls: 0.196
    ctrld_gen₊machine₊X_q: 1.9600000381469727
    ctrld_gen₊machine₊X′_d: 0.39899998903274536
    ctrld_gen₊machine₊X′_q: 0.6377000212669373
    ctrld_gen₊machine₊X″_d: 0.3149999976158142
    ctrld_gen₊machine₊X″_q: 0.3149999976158142
    ctrld_gen₊machine₊ω_b: 376.99111843077515
    pf:
      MODEL: Models.PF_PV
      P: 5.4
      V: 1.0278

  38: # Machine with AVR/Gov
    CONSTRUCTOR: Bus
    ARGS:
      - MODEL: Models.ControlledGenBus
    name: :Bus_38
    ctrld_gen₊avr₊E1: 4.256757
    ctrld_gen₊avr₊E2: 5.675676
    ctrld_gen₊avr₊Ka: 40.0
    ctrld_gen₊avr₊Ke: 1.0
    ctrld_gen₊avr₊Kf: 0.03
    ctrld_gen₊avr₊Se1: 0.62
    ctrld_gen₊avr₊Se2: 0.85
    ctrld_gen₊avr₊Ta: 0.02
    ctrld_gen₊avr₊Te: 1.4
    ctrld_gen₊avr₊Tf: 1.0
    ctrld_gen₊avr₊Tr: 0.01
    ctrld_gen₊avr₊vr_max: 10.5
    ctrld_gen₊avr₊vr_min: -10.5
    ctrld_gen₊gov₊DT: 0
    ctrld_gen₊gov₊R: 0.05
    ctrld_gen₊gov₊T1: 0.5
    ctrld_gen₊gov₊T2: 2.1
    ctrld_gen₊gov₊T3: 7.2
    ctrld_gen₊gov₊V_max: 1.0
    ctrld_gen₊gov₊V_min: 0.0
    ctrld_gen₊gov₊ω_ref: 1
    ctrld_gen₊machine₊D: 0
    ctrld_gen₊machine₊H: 3.450000047683716
    ctrld_gen₊machine₊R_s: 0.0
    ctrld_gen₊machine₊S_b: 100
    ctrld_gen₊machine₊Sn: 1000.0
    ctrld_gen₊machine₊T′_d0: 4.789999961853027
    ctrld_gen₊machine₊T′_q0: 1.9600000381469727
    ctrld_gen₊machine₊T″_d0: 0.05000000074505806
    ctrld_gen₊machine₊T″_q0: 0.03500000014901161
    ctrld_gen₊machine₊V_b: 16.5
    ctrld_gen₊machine₊Vn: 16.5
    ctrld_gen₊machine₊X_d: 2.1059999465942383
    ctrld_gen₊machine₊X_ls: 0.298
    ctrld_gen₊machine₊X_q: 2.049999952316284
    ctrld_gen₊machine₊X′_d: 0.5699999928474426
    ctrld_gen₊machine₊X′_q: 0.5870000123977661
    ctrld_gen₊machine₊X″_d: 0.44999998807907104
    ctrld_gen₊machine₊X″_q: 0.44999998807907104
    ctrld_gen₊machine₊ω_b: 376.99111843077515
    pf:
      MODEL: Models.PF_PV
      P: 8.3
      V: 1.0265

  39: # Load + Machine w/o Control
    CONSTRUCTOR: Bus
    ARGS:
      - MODEL: Models.LoadMachineBus
    name: :Bus_39
    machine₊D: 0
    machine₊H: 5.0
    machine₊R_s: 0.0
    machine₊S_b: 100
    machine₊Sn: 10000.0
    machine₊T′_d0: 7.0
    machine₊T′_q0: 0.699999988079071
    machine₊T″_d0: 0.05000000074505806
    machine₊T″_q0: 0.03500000014901161
    machine₊V_b: 345.0
    machine₊Vn: 345.0
    machine₊X_d: 2.0
    machine₊X_ls: 0.3
    machine₊X_q: 1.899999976158142
    machine₊X′_d: 0.6000000238418579
    machine₊X′_q: 0.800000011920929
    machine₊X″_d: 0.4000000059604645
    machine₊X″_q: 0.4000000059604645
    machine₊ω_b: 376.99111843077515
    load₊KpC: 0.0
    load₊KpI: 0.0
    load₊KpZ: 1.0
    load₊KqC: 0.0
    load₊KqI: 0.0
    load₊KqZ: 1.0
    load₊Pset: -11.04
    load₊Qset: -2.5
    pf:
      MODEL: Models.PF_PV
      P: -1.04
      V: 1.03

    ]


end

@compile_workload begin
    # include("_precompile_workload.jl")
end

end # module WorkshopCompanion
