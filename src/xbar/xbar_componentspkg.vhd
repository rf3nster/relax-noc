---------------------------------------------------------------------------
-- Package:
--    Router Crossbar Component and Types Declaration Package
-- Purpose:
--    Provides all component and types declarations for router 
--    crossbar components.
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

library work;
	use work.noc_parameterspkg.all;

package xbar_componentspkg is

	--------------------------------------
	-- Records
	--------------------------------------

	type xbar_poprqst_t is record
		north : std_logic;
		south : std_logic;
		west  : std_logic;
		east  : std_logic;
		pe    : std_logic;
	end record;      

	type xbar_dataavailable_t is record
		north : std_logic;
		south : std_logic;
		west  : std_logic;
		east  : std_logic;
		pe    : std_logic;
	end record;

	type xbar_directionselect_t is record
		north : std_logic;
		south : std_logic;
		west  : std_logic;
		east  : std_logic;
		pe    : std_logic;
	end record;   
	
	--------------------------------------
	-- Components
	--------------------------------------
	
	component xbar_comb is
		generic (
			router_loc_x : integer range 0 to x_size := 0;
			router_loc_y : integer range 0 to y_size := 0
		);
		port (
			-- System control
			enable : in    std_logic;

			-- Destination
			destaddr : in    std_logic_vector(addr_width - 1 downto 0);

			-- Data signaling
			rx_dataavailable  : in    xbar_dataavailable_t;
			rx_poprqst_in     : in    xbar_poprqst_t;
			rx_select         : in    unsigned (2 downto 0);
			txselect          : out   xbar_directionselect_t;
			dataavailable_out : out   std_logic;
			rx_poprqst_out    : out   std_logic
		);
	end component;

	component xbar_fsm is
		port (
			-- System control
			clk            : in    std_logic;
			rst            : in    std_logic;
			secondcycle_en : in    std_logic;
			enable         : in    std_logic;

			-- Data signaling
			dataavailable : in    xbar_dataavailable_t;
			fifoselect    : out   unsigned (2 downto 0)
		);
	end component;

	component xbar_top is
		generic (
			router_loc_x : integer range 0 to x_size := 0;
			router_loc_y : integer range 0 to y_size := 0
		);
		port (
			--------------------------------------
			-- System control
			--------------------------------------
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;
	
			--------------------------------------
			-- Packets
			--------------------------------------
			-- Receiving side
			rx_pe_packet    : in    packet_t;
			rx_north_packet : in    packet_t;
			rx_south_packet : in    packet_t;
			rx_west_packet  : in    packet_t;
			rx_east_packet  : in    packet_t;
			
			-- Transmitting side
			tx_packet : out   packet_t;
		  
			--------------------------------------
			-- Selects
			--------------------------------------
			-- RX
			rx_channela_sel : out   xbar_directionselect_t;
			rx_channelb_sel : out   xbar_directionselect_t;
			
			-- TX
			tx_channela_sel : out   xbar_directionselect_t;
			tx_channelb_sel : out   xbar_directionselect_t;
	
			--------------------------------------
			-- Data Available
			--------------------------------------
			-- RX
			rx_channela_dataavail_in : in    xbar_dataavailable_t;
			rx_channelb_dataavail_in : in    xbar_dataavailable_t;

			-- TX
			tx_channela_dataavail_out : out   std_logic;
			tx_channelb_dataavail_out : out   std_logic;
	
			--------------------------------------
			-- Pop Request
			--------------------------------------
			-- RX
			rx_channela_poprqst_out : out   std_logic;
			rx_channelb_poprqst_out : out   std_logic;

			-- TX
			tx_channela_poprqst_in : in    xbar_poprqst_t;
			tx_channelb_poprqst_in : in    xbar_poprqst_t      
		);
	end component;

end package xbar_componentspkg;