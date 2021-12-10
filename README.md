# RELAX: A REconfigurabLe ApproXimate Network-on-Chip
This is the repository for the source of RELAX: A REconfigurabLe ApproXimate Network-on-Chip, a paper by Rick Fenster and Sébastien Le Beux, published as part of the IEEE 14th International Symposium on Embedded Multicore/Many-core Systems-on-Chip. It includes the RTL description of the network in **VHDL-2008** along with some TCL scripts for Mentor Graphics Modelsim and Python scripts to drive the simulation. 

RELAX aims to provide a network-on-chip that can both transit accurate and approximate data concurrently 
## Requirements
<ol>
<li>VHDL-2008 compatible compiler/simulator
<li> Python 3.6 or higher and openpyxl
</ol>

## Usage
Without modification to any scripts, it is assumed that Modelsim is found in `$PATH` (for Linux) or `%PATH%` (for Windows). Simply invoke the run_mixed_weighted_test.py script with Python 3.x. Results will written to Excel (.xlsx) files in the root directory.  The network topology used is a mesh topology. By default, a 4x4 network will be simulated.

*Using another simulator requires modifying the Python script to invoke the simulator and its associated script to drive the simulation.*
## Modifying the Network
The following user-configurable parameters can be found in [`./src/shared/noc_parameterspkg.vhd`](https://github.com/rf3nster/relax-noc/src/shared/noc_parameterspkg.vhd):

Network X dimension: `x_size`
Network Y dimension: `y_size`
Max number of simulation cycles: `clock_cycle_max`
Number of simulation cycles per period: `packet_period_size`
Number of packets to inject: `packet_qty`
Traffic injector buffer size: `inj_buffer_depth`
Accurate data weight: `acc_data_weight`
Approximate data weight: `apx_data_weight`
FIFO depth/Number of slots: `fifo_depth`

## License and Warranty

RELAX is licensed under the Apache license version 2.0. For more information, see [LICENSE.md](https://github.com/rf3nster/relax-noc/blob/main/LICENSE.md). **This software comes with absolutely no support or warranty!**

RELAX includes and uses [OSVVM](https://github.com/OSVVM/OSVVM) for simulation, which is distributed under the Apache license version 2.0 as well.
