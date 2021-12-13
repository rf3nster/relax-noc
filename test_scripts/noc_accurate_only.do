############################################################################
# Script:
#    Modelsim TCL script to compile and run RELAX testbench in accurate mode 
#
# Requires: VHDL-2008, NON-SYNTHESIZABLE
# 
# Copyright 2021 Rick Fenster
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
############################################################################

# Compile OSVVM Libraries
vcom -2008 -reportprogress 300 -work work ./src/osvvm/NamePkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/OsvvmGlobalPkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/OsvvmContext.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/TextUtilPkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/TranscriptPkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/AlertLogPkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/SortListPkg_int.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/RandomBasePkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/osvvm/RandomPkg.vhd

# Compile dependencies
vcom -2008 -reportprogress 300 -work work ./src/shared/*.vhd
vcom -2008 -reportprogress 300 -work work ./src/fifo/*.vhd
vcom -2008 -reportprogress 300 -work work ./src/rx/*.vhd
vcom -2008 -reportprogress 300 -work work ./src/tx/*.vhd

vcom -2008 -reportprogress 300 -work work ./src/xbar/xbar_componentspkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/xbar/*.vhd
vcom -2008 -reportprogress 300 -work work ./src/router/*.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_componentspkg.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_ejectionfsm.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_ejectionport.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_ejectiondriver.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_injectionfsm.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_injectionport.vhd
vcom -2008 -reportprogress 300 -work work ./src/pe/pe_injectiondriver.vhd

vcom -2008 -reportprogress 300 -work work ./src/tile/*.vhd

# Compile DUT
vcom -2008 -reportprogress 300 -work work ./src/top/noc_tb.vhd
# Start
vsim work.noc_tb

# Disable numeric warnings
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

# Set network mode to accurate only
force networkmode 0

# Run
run 32000 ns
quit