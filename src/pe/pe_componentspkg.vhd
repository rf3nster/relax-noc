---------------------------------------------------------------------------
-- Package:
--    Processing Element Component Package
-- Purpose:
--    Provides component definitions of processing element components. 
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
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.noc_parameterspkg.all;

package pe_componentspkg is

	component pe_ejectionfsm is
		port (
			-- System control
			clk : in    std_logic;
			rst : in    std_logic;
				
			-- FIFO control signals
			fifo_popen   : out   std_logic;
			fifo_writeen : out   std_logic;
															
			-- FIFO State
			fifo_full  : in    std_logic;
			fifo_empty : in    std_logic;
				
			-- Request and status signals
			datavalid : out   std_logic;
			popsrc    : out   std_logic;
			writerqst : in    std_logic;
			datarqst  : in    std_logic
		);
	end component;

	component pe_ejectionport is 
		generic (
			addresswidth : integer := addr_width;
			fifowidth    : integer := channel_data_size;     
			fifodepth    : integer := fifo_depth
		);
		port (
			-- System control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;

			-- Processing Element side
			datarqst     : in    std_logic;
			datatype     : in    std_logic;
			dataout      : out   std_logic_vector(fifowidth * 2 - 1 downto 0);
			originout    : out   std_logic_vector(addresswidth - 1 downto 0);
			apxavailable : out   std_logic;
			accavailable : out   std_logic;
			datavalid    : out   std_logic;

			-- Crossbar Side
			packet_in              : in    packet_t;
			channela_dataavailable : in    std_logic;
			channelb_dataavailable : in    std_logic;
			channela_txselect      : in    std_logic;
			channelb_txselect      : in    std_logic;
			channela_poprqst       : out   std_logic;
			channelb_poprqst       : out   std_logic     
		);
	end component;

	component pe_injectionport is 
		generic (
			addresswidth : integer := addr_data_size;
			fifowidth    : integer := channel_data_size;       
			fifodepth    : integer := fifo_depth;
			router_loc_x : integer range 0 to x_size := 0;
			router_loc_y : integer range 0 to y_size := 0
		);
		port (
			-- System control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;
				
			-- Processing Element side
			destin      : in    std_logic_vector(addr_width - 1 downto 0);
			datain      : in    std_logic_vector(2 * channel_data_size - 1 downto 0);
			writeen     : in    std_logic;
			datatype    : in    std_logic;
			accfifofull : out   std_logic;
			apxfifofull : out   std_logic;

			-- Crossbar side
			channela_poprqst       : in    std_logic;
			channelb_poprqst       : in    std_logic;
			rx_channela_select     : in    std_logic;
			rx_channelb_select     : in    std_logic;				
			rx_packet_out          : out   packet_t;
			channela_dataavailable : out   std_logic;
			channelb_dataavailable : out   std_logic
		);
	end component;

	component pe_injectionfsm is
		port (
			-- System control
			clk : in    std_logic;
			rst : in    std_logic;
			
			-- Crossbar side
			datarqst      : in    std_logic;
			rx_select     : in    std_logic;
			dataavailable : out   std_logic;

			-- FIFO Side
			fifo_empty     : in    std_logic;
			fifo_full      : in    std_logic;
			fifo_writerqst : in    std_logic;
			fifo_popen     : out   std_logic;
			fifo_writeen   : out   std_logic
		);
	end component;

	component pe_ejectiondriver is
		generic (
			x_coord : integer range 0 to x_size := 0;
			y_coord : integer range 0 to y_size := 0
		);
		port (
			-- System Control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;

			-- Tick Count
			currenttick : in    unsigned(cc_max_width - 1 downto 0);

			-- Crossbar Side
			packet_in              : in    packet_t;
			channela_dataavailable : in    std_logic;
			channelb_dataavailable : in    std_logic;
			channela_txselect      : in    std_logic;
			channelb_txselect      : in    std_logic;
			channela_poprqst       : out   std_logic;
			channelb_poprqst       : out   std_logic 
		);    
	end component;    

	component pe_injectiondriver is
		generic (
			x_coord : integer range 0 to x_size - 1 := 0;
			y_coord : integer range 0 to y_size - 1 := 0
		);
		port (
			-- System Control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;
			
			-- Tick Count
			currenttick : in    unsigned(cc_max_width - 1 downto 0);

			-- Processing Element side
			injectionenable : in    std_logic;
			accfifofull     : in    std_logic;
			apxfifofull     : in    std_logic;			
			destout         : out   std_logic_vector(addr_width - 1 downto 0);
			dataout         : out   std_logic_vector(2 * channel_data_size - 1 downto 0);
			writeen         : out   std_logic;
			datatype        : out   std_logic
		);
	end component;

end package pe_componentspkg;