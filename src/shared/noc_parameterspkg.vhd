---------------------------------------------------------------------------
-- Package:
--    Shared Parameters Library for NoC
-- Purpose:
--    Defines all necessary parameters and constants for the NoC
--
-- Requires: VHDL-2008
--
-- Copyright 2021 Rick Fenster
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
---------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;

package noc_parameterspkg is

	------------------------------------
	-- User Configurable Settings
	------------------------------------
	-- Max number of clock cycles
	constant clock_cycle_max : integer := 262144;

	-- Number of packets to be distributed
	constant packet_qty : integer := 1000;

	-- Number of clock cycles per period
	constant packet_period_size : integer := 1000;

	-- Network X width
	constant x_size : natural := 4;

	-- Network Y width
	constant y_size : natural := 4;

	-- Channel Width
	constant channel_data_size : integer := 22;

	-- FIFO Depth
	constant fifo_depth : integer := 96;

	-- Traffic Injector Buffer Depth
	constant inj_buffer_depth : integer := 1024;

	-- Weights for accurate and approximate data transmission
	-- Percentage weight = Defined Weight of Data Type / Sum of defined weights
	-- To keep things simple, make sure total is 100
    constant acc_data_weight : natural := 50;
    constant apx_data_weight : natural := 50;

	------------------------------------
	-- Config-Dependent Values
	------------------------------------
	-- Number of bits for X width
	constant x_bits : natural := integer(log2(real(x_size)));

	-- Number of bits for Y width
	constant y_bits : natural := integer(log2(real(y_size)));

	-- Address width constant
	constant addr_width : integer := x_bits + y_bits;

	-- Address Data Size
	constant addr_data_size : integer := addr_width * 2;

	-- Number of bits for max number of clock cycles
	constant cc_max_width : integer := integer(log2(real(clock_cycle_max)));

	-- Number of packets required per period (Injection Rate = packets_per_period / packet_period_size)
    constant packets_per_period : integer := 100;

	------------------------------------
	-- Records
	------------------------------------
	-- Packet

	type packet_t is record
		dataa : std_logic_vector(channel_data_size - 1 downto 0);
		datab : std_logic_vector(channel_data_size - 1 downto 0);
		addra : std_logic_vector(addr_data_size - 1 downto 0);
		addrb : std_logic_vector(addr_data_size - 1 downto 0);
	end record;

	-- Clear to Send

	type cleartosend_t is record
		cleartosenda : std_logic;
		cleartosendb : std_logic;
	end record;

	-- Channel Valid

	type channelvalid_t is record
		channelvalida : std_logic;
		channelvalidb : std_logic;
	end record;

	-- Encompassing link definition

	type link_t is record
		packet       : packet_t;
		cleartosend  : cleartosend_t;
		channelvalid : channelvalid_t;
	end record;

end package noc_parameterspkg;
