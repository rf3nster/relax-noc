# Compilation Order
This document provides the order of compilation and dependence for the reference mesh implementation, which may serve to be useful if you use a simulator other than Modelsim or Questasim from Mentor Graphics or wish to write your own scripts.
> _Note_: Please compile all files into a library called **work**  and as **VHDL-2008** code.

1. OSVVM Packages (Non-synthesizable)
    1. ``./osvvm/NamePkg.vhd``
    2. ``./osvvm/OsvvmGlobalPkg.vhd``
    3. ``./src/osvvm/OsvvmContext.vhd``
    4. ``./src/osvvm/TextUtilPkg.vhd``
    5. ``./src/osvvm/TranscriptPkg.vhd``
    6. ``./src/osvvm/AlertLogPkg.vhd``
    7. ``./src/osvvm/SortListPkg_int.vhd``
    8.  ``./src/osvvm/RandomBasePkg.vhd``
    9. ``./src/osvvm/RandomPkg.vhd``
2. Shared Configuration Package
    1. ``./shared/noc_parameterspkg.vhd``
3. FIFOs Package
    1. ``./fifo/fifo_componentspkg.vhd``
    2. ``/fifo/fifo_dualoutput.vhd``
    3. ``./fifo/fifo_dualpop.vhd``
    4. ``./fifo/fifo_dualwrite.vhd``
    5. ``./fifo/fifo_duplicatewrite.vhd``
    6. ``./fifo/fifo_normal.vhd``
    7. ``./fifo/fifo_reg.vhd``
4. Network Interface Receiver Package
    1. ``./rx/rx_componentspkg.vhd``
    2. ``./rx/rx_readfsm.vhd``
    3. ``./rx/rx_top.vhd``
    4. ``./rx/rx_writefsm.vhd``
5. Network Interface Transmitter Package
    1. ``./tx/tx_componentspkg.vhd``
    2. ``./tx/tx_readfsm.vhd``
    3. ``./tx/tx_top.vhd``
    4. ``./tx/tx_writefsm.vhd``
6. Processing Element Package
    1. ``./pe/pe_componentspkg.vhd``
    2. ``./pe/pe_ejectiondriver.vhd`` (Non-synthesizable)
    3. ``./pe/pe_ejectionfsm.vhd``
    4. ``./pe/pe_ejectionport.vhd``
    5. ``./pe/pe_injectiondriver.vhd`` (Non-synthesizable)
    6. ``./pe/pe_injectionfsm.vhd``
    7. ``./pe/pe_injectionport.vhd``
7. Mesh Router Crossbar Package
    1. ``./xbar/xbar_componentspkg.vhd``
    2. ``./xbar/xbar_comb.vhd``
    3. ``./xbar/xbar_fsm.vhd``
    4. ``./xbar/xbar_top.vhd``
8. Mesh Router Package
    1. ``./router_componentspkg.vhd``
    2. ``./router_top.vhd``
9. Mesh Tile Package
    1. ``./tile/tile_componentspkg.vhd``
    2. ``./tile/tile_synth_top.vhd``
    3. ``./tile/tile_top.vhd`` (Non-synthesizable)
10. Mesh Network Top-Level (Non-synthesizable)
    1. ``./top/noc_test.vhd`` 

