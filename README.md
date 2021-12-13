# RELAX: A REconfigurabLe ApproXimate Network-on-Chip
This is the repository for the source of RELAX: A REconfigurabLe ApproXimate Network-on-Chip, a paper by Rick Fenster and Sébastien Le Beux, published as part of the IEEE 14th International Symposium on Embedded Multicore/Many-core Systems-on-Chip. It includes the RTL description of the network in **VHDL-2008** along with some TCL scripts for Mentor Graphics Modelsim and Python scripts to drive the simulation. 

RELAX aims to provide a network-on-chip that can both transit accurate and approximate data concurrently 
## Requirements

1. VHDL-2008 compatible compiler/simulator
2. Python 3.6 or higher and openpyxl

*Using another simulator requires modifying the Python script to invoke the simulator and its associated script to drive the simulation.*
## Modifying the Network
The following user-configurable parameters can be found in [`./src/shared/noc_parameterspkg.vhd`](https://github.com/rf3nster/relax-noc/blob/main/src/shared/noc_parameterspkg.vhd):

Network X dimension: `x_size`

Network Y dimension: `y_size`

Max number of simulation cycles: `clock_cycle_max`

Number of simulation cycles per period: `packet_period_size`

Number of packets to inject: `packet_qty`

Traffic injector buffer size: `inj_buffer_depth`

Accurate data weight: `acc_data_weight`

Approximate data weight: `apx_data_weight`

FIFO depth/number of slots: `fifo_depth`

## Configuring Simulation Parameters
# Injection Rates
The injection rates are defined in a text file called `injectionrates.dat`. Simply specify the injection rates desired in the text file with only one injection rate per line. Please view [`injectionrates.dat`](https://github.com/rf3nster/relax-noc/blob/main/injectionrates.dat) for a working example.
> Note: Valid values are from 0.000 to 0.999. 

# Data Type Weights
The weighted average of accurate and approximate data generatede in the mixed mode testbench simulation for RELAX is user-controllable. Weights are specified in `weights.dat`. Each line is one combination, with the accurate data specified first and the approximate value separated by a comma.
The percentages determined by:

![ equation](http://www.sciweavers.org/tex2img.php?eq=%5Ctext%7Bapx%7D%20%3D%20%5Cfrac%7Bapx%7D%7Bapx%20%2B%20acc%7D&bc=White&fc=Black&im=jpg&fs=12&ff=modern&edit=0 )
![equation](http://www.sciweavers.org/tex2img.php?eq=%5Ctext%7Bacc%7D%20%3D%20%5Cfrac%7Bacc%7D%7Bapx%20%2B%20acc%7D&bc=White&fc=Black&im=jpg&fs=12&ff=modern&edit=0")
> Note: Values must be positive integers or zero

Please view [`weights.dat`](https://github.com/rf3nster/relax-noc/blob/main/weights.dat) for a working example.


## Usage
Without modification to any scripts, it is assumed that Modelsim is found in `$PATH` (for Linux) or `%PATH%` (for Windows). With the repository's root folder as the working director, simply invoke the `run_mixed_.py` script with Python 3.x for mixed mode, or `run_accurate_only.py` for accurate-only mode. The script will execute a total of passes, defined by the number of weight sets specified. After each pass, the results can be found as a CSV file in `./csv_data`. Results of the pass will be written to Excel (.xlsx) files in a directory called `results` as well. The network topology used is a mesh topology. By default, a 4x4 network will be simulated.

> Note: The Python scripts are designed in such a way that the environment is cleared at launch. Make sure that any desired results have been copied from the directory before re-launching!

## License and Warranty

RELAX is licensed under the Apache 2.0 license. For more information, see [LICENSE.md](https://github.com/rf3nster/relax-noc/blob/main/LICENSE.md). 

>**The design and code contained in this repository comes with absolutely no support or warranty!**

RELAX includes and uses [OSVVM](https://github.com/OSVVM/OSVVM) for simulation, which is distributed under the Apache 2.0 license as well.
