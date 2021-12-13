---------------------------------------------------------------------------
-- Component:
--    Testbench/DUT
-- Purpose:
--    Mesh topology RELAX network with random traffic generation
-- 
-- Requires: VHDL-2008, NON-SYNTHESIZABLE
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
	use work.tile_componentspkg.all;

entity noc_tb is
end entity noc_tb;

architecture testbench of noc_tb is

	signal rst           : std_logic;
	signal rst_triggered : std_logic;
	signal clk           : std_logic;
	signal networkmode   : std_logic;

	signal currenttick : natural range 0 to clock_cycle_max;
	-- Generate horizontal arrays

	type cleartosend_horiz_t is array (2 * (x_size - 1) * (y_size)  - 1 downto 0) of cleartosend_t;

	type channelvalid_horiz_t is array (2 * (x_size - 1) * (y_size)  - 1 downto 0) of channelvalid_t;  
	
	type packet_horiz_t is array (2 * (x_size - 1) * (y_size)  - 1 downto 0) of packet_t;  

	signal cleartosend_horiz  : cleartosend_horiz_t;
	signal channelvalid_horiz : channelvalid_horiz_t;
	signal packet_horiz       : packet_horiz_t;    

	-- Generate vertical arrays

	type cleartosend_vert_t is array (2 * (y_size - 1) * (x_size)  - 1 downto 0) of cleartosend_t;

	type channelvalid_vert_t is array (2 * (y_size - 1) * (x_size)  - 1 downto 0) of channelvalid_t;  
	
	type packet_vert_t is array (2 * (y_size - 1) * (x_size)  - 1 downto 0) of packet_t;  

	signal cleartosend_vert  : cleartosend_vert_t;
	signal channelvalid_vert : channelvalid_vert_t;
	signal packet_vert       : packet_vert_t;   
	
	signal currenttick_slv : unsigned (cc_max_width - 1 downto 0);

begin

	currenttick_slv <= to_unsigned(currenttick, currenttick_slv'length);

	gen_col : for current_x in 0 to x_size - 1 generate

		gen_row : for current_y in 0 to y_size - 1 generate

			top_left : if (current_x = 0 and current_y = 0) generate
			
				tl_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
						
						-- Tick Count
						currenttick => currenttick_slv,
						
						-- North Inbound
						northpacket_in.dataa               => (others => '0'),
						northpacket_in.datab               => (others => '0'),
						northpacket_in.addra               => (others => '0'),
						northpacket_in.addrb               => (others => '0'),
						northchannelvalid_in.channelvalida => '0',
						northchannelvalid_in.channelvalidb => '0',
			
						-- North Outbound
						northcleartosend_in.cleartosenda => '0',			
						northcleartosend_in.cleartosendb => '0',
			
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
			
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
			
						-- West Inbound
						westpacket_in.dataa               => (others => '0'),
						westpacket_in.datab               => (others => '0'),
						westpacket_in.addra               => (others => '0'),
						westpacket_in.addrb               => (others => '0'),
						westchannelvalid_in.channelvalida => '0',
						westchannelvalid_in.channelvalidb => '0',
			
						-- West Outbound
						westcleartosend_in.cleartosenda => '0',			
						westcleartosend_in.cleartosendb => '0',
			
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
			
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);
    
			end generate top_left;

			top_wall : if (current_x /= 0 and current_x /= x_size - 1 and current_y = 0) generate

				tw_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
						
						-- Tick Count
						currenttick => currenttick_slv,
						
						-- North Inbound
						northpacket_in.dataa               => (others => '0'),
						northpacket_in.datab               => (others => '0'),
						northpacket_in.addra               => (others => '0'),
						northpacket_in.addrb               => (others => '0'),
						northchannelvalid_in.channelvalida => '0',
						northchannelvalid_in.channelvalidb => '0',
			
						-- North Outbound
						northcleartosend_in.cleartosenda => '0',			
						northcleartosend_in.cleartosendb => '0',
			
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
			
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
			
						-- West Inbound
						westpacket_in       => packet_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westchannelvalid_in => channelvalid_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westcleartosend_out => cleartosend_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
			
						-- West Outbound
						westcleartosend_in   => cleartosend_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westpacket_out       => packet_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westchannelvalid_out => channelvalid_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
			
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
			
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);  
					
			end generate top_wall;

			top_right : if (current_x = x_size - 1 and current_y = 0) generate

				tr_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
						
						-- Tick Count
						currenttick => currenttick_slv,
						
						-- North Inbound
						northpacket_in.dataa               => (others => '0'),
						northpacket_in.datab               => (others => '0'),
						northpacket_in.addra               => (others => '0'),
						northpacket_in.addrb               => (others => '0'),
						northchannelvalid_in.channelvalida => '0',
						northchannelvalid_in.channelvalidb => '0',
			
						-- North Outbound
						northcleartosend_in.cleartosenda => '0',			
						northcleartosend_in.cleartosendb => '0',
			
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
			
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
			
						-- West Inbound
						westpacket_in       => packet_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westchannelvalid_in => channelvalid_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westcleartosend_out => cleartosend_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
			
						-- West Outbound
						westcleartosend_in   => cleartosend_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westpacket_out       => packet_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westchannelvalid_out => channelvalid_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
			
						-- East Inbound
						eastpacket_in.dataa               => (others => '0'),
						eastpacket_in.datab               => (others => '0'),
						eastpacket_in.addra               => (others => '0'),
						eastpacket_in.addrb               => (others => '0'),
						eastchannelvalid_in.channelvalida => '0',
						eastchannelvalid_in.channelvalidb => '0',
			
						-- East Outbound
						eastcleartosend_in.cleartosenda => '0',			
						eastcleartosend_in.cleartosendb => '0'    
					);    

			end generate top_right;

			middle : if (current_x /= 0 and current_x /= x_size - 1 and current_y /= 0 and current_y /= y_size - 1) generate

				m_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
					
						-- Tick Count
						currenttick => currenttick_slv,
					
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
		
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
		
						-- West Inbound
						westpacket_in.dataa               => (others => '0'),
						westpacket_in.datab               => (others => '0'),
						westpacket_in.addra               => (others => '0'),
						westpacket_in.addrb               => (others => '0'),
						westchannelvalid_in.channelvalida => '0',
						westchannelvalid_in.channelvalidb => '0',
			
						-- West Outbound
						westcleartosend_in.cleartosenda => '0',			
						westcleartosend_in.cleartosendb => '0',  
		
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
		
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);  

			end generate middle;

			left_wall : if (current_x = 0 and current_y /= 0 and current_y /= y_size - 1) generate

				lw_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
					
						-- Tick Count
						currenttick => currenttick_slv,
					
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
		
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
		
						-- West Inbound
						westpacket_in       => packet_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westchannelvalid_in => channelvalid_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westcleartosend_out => cleartosend_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
		
						-- West Outbound
						westcleartosend_in   => cleartosend_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westpacket_out       => packet_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westchannelvalid_out => channelvalid_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
		
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
		
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);  

			end generate left_wall;

			right_wall : if (current_x = x_size - 1 and current_y /= 0 and current_y /= y_size - 1) generate

				rw_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
					
						-- Tick Count
						currenttick => currenttick_slv,
					
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in       => packet_vert((2 * (current_x + (x_size * current_y))) + 1),
						southchannelvalid_in => channelvalid_vert((2 * (current_x + (x_size * current_y))) + 1),
						southcleartosend_out => cleartosend_vert((2 * (current_x + (x_size * current_y))) + 1),
		
						-- South Outbound
						southcleartosend_in   => cleartosend_vert(2 * (current_x + (x_size * current_y))),
						southpacket_out       => packet_vert(2 * (current_x + (x_size * current_y))),
						southchannelvalid_out => channelvalid_vert(2 * (current_x + (x_size * current_y))),
		
						-- West Inbound
						westpacket_in.dataa               => (others => '0'),
						westpacket_in.datab               => (others => '0'),
						westpacket_in.addra               => (others => '0'),
						westpacket_in.addrb               => (others => '0'),
						westchannelvalid_in.channelvalida => '0',
						westchannelvalid_in.channelvalidb => '0',
			
						-- West Outbound
						westcleartosend_in.cleartosenda => '0',			
						westcleartosend_in.cleartosendb => '0',  
		
						-- East Inbound
						eastpacket_in.dataa               => (others => '0'),
						eastpacket_in.datab               => (others => '0'),
						eastpacket_in.addra               => (others => '0'),
						eastpacket_in.addrb               => (others => '0'),
						eastchannelvalid_in.channelvalida => '0',
						eastchannelvalid_in.channelvalidb => '0',
		
						-- East Outbound
						eastcleartosend_in.cleartosenda => '0',			
						eastcleartosend_in.cleartosendb => '0'       
					);  

			end generate right_wall;

			bottom_wall : if (current_x /= 0 and current_x /= x_size - 1 and current_y = y_size - 1) generate

				bw_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
					
						-- Tick Count
						currenttick => currenttick_slv,
					
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in.dataa               => (others => '0'),
						southpacket_in.datab               => (others => '0'),
						southpacket_in.addra               => (others => '0'),
						southpacket_in.addrb               => (others => '0'),
						southchannelvalid_in.channelvalida => '0',
						southchannelvalid_in.channelvalidb => '0',
		
						-- South Outbound
						southcleartosend_in.cleartosenda => '0',			
						southcleartosend_in.cleartosendb => '0',
		
						-- West Inbound
						westpacket_in       => packet_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westchannelvalid_in => channelvalid_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westcleartosend_out => cleartosend_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
		
						-- West Outbound
						westcleartosend_in   => cleartosend_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westpacket_out       => packet_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westchannelvalid_out => channelvalid_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
		
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
		
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);  

			end generate bottom_wall;		

			bottom_left : if (current_x = 0 and current_y = y_size - 1) generate

				bl_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',
					
						-- Tick Count
						currenttick => currenttick_slv,
					
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in.dataa               => (others => '0'),
						southpacket_in.datab               => (others => '0'),
						southpacket_in.addra               => (others => '0'),
						southpacket_in.addrb               => (others => '0'),
						southchannelvalid_in.channelvalida => '0',
						southchannelvalid_in.channelvalidb => '0',
		
						-- South Outbound
						southcleartosend_in.cleartosenda => '0',			
						southcleartosend_in.cleartosendb => '0',
					
						-- West Inbound
						westpacket_in.dataa               => (others => '0'),
						westpacket_in.datab               => (others => '0'),
						westpacket_in.addra               => (others => '0'),
						westpacket_in.addrb               => (others => '0'),
						westchannelvalid_in.channelvalida => '0',
						westchannelvalid_in.channelvalidb => '0',
		
						-- West Outbound
						westcleartosend_in.cleartosenda => '0',			
						westcleartosend_in.cleartosendb => '0',  
		
						-- East Inbound
						eastpacket_in       => packet_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastchannelvalid_in => channelvalid_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
						eastcleartosend_out => cleartosend_horiz(2 * ((current_y * (x_size - 1)) + current_x)),
		
						-- East Outbound
						eastcleartosend_in   => cleartosend_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastpacket_out       => packet_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1),  
						eastchannelvalid_out => channelvalid_horiz((2 * ((current_y * (x_size - 1)) + current_x)) + 1)       
					);  

			end generate bottom_left;

			bottom_right : if (current_x = x_size - 1 and current_y = y_size - 1) generate

				br_tile : component tile_top
					generic map (
						x_coord => current_x,
						y_coord => current_y
					)
					port map (
						-- System Control
						clk             => clk,
						rst             => rst,
						networkmode     => networkmode,
						injectionenable => '1',

						-- Tick Count
						currenttick => currenttick_slv,
						
						-- North Inbound
						northpacket_in       => packet_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northchannelvalid_in => channelvalid_vert(2 * (current_x + ((current_y - 1) * x_size))),
						northcleartosend_out => cleartosend_vert(2 * (current_x + ((current_y - 1) * x_size))),
		
						-- North Outbound
						northcleartosend_in   => cleartosend_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),			
						northpacket_out       => packet_vert((2 * (current_x + ((current_y - 1) * x_size))) + 1),
						northchannelvalid_out => channelvalid_vert(((2 * (current_x + (current_y - 1) * x_size))) + 1),
		
						-- South Inbound
						southpacket_in.dataa               => (others => '0'),
						southpacket_in.datab               => (others => '0'),
						southpacket_in.addra               => (others => '0'),
						southpacket_in.addrb               => (others => '0'),
						southchannelvalid_in.channelvalida => '0',
						southchannelvalid_in.channelvalidb => '0',
		
						-- South Outbound
						southcleartosend_in.cleartosenda => '0',			
						southcleartosend_in.cleartosendb => '0',
		
						-- West Inbound
						westpacket_in       => packet_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westchannelvalid_in => channelvalid_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),
						westcleartosend_out => cleartosend_horiz(2 * (current_y * (x_size - 1) + (current_x - 1))),

						-- West Outbound
						westcleartosend_in   => cleartosend_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westpacket_out       => packet_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
						westchannelvalid_out => channelvalid_horiz((2 * (current_y * (x_size - 1) + (current_x - 1))) + 1),
		
						-- East Inbound
						eastpacket_in.dataa               => (others => '0'),
						eastpacket_in.datab               => (others => '0'),
						eastpacket_in.addra               => (others => '0'),
						eastpacket_in.addrb               => (others => '0'),
						eastchannelvalid_in.channelvalida => '0',
						eastchannelvalid_in.channelvalidb => '0',
		
						-- East Outbound
						eastcleartosend_in.cleartosenda => '0',			
						eastcleartosend_in.cleartosendb => '0'     
					);  
					
			end generate bottom_right;

		end generate gen_row;
				
	end generate gen_col;
	
	tb_proc : process is
	begin

		if (rst_triggered /= '1') then
			rst           <= '1';
			rst_triggered <= '1';
			clk           <= '0';
			wait for 1 ns;
		else
			rst <= '0';
			
			for i in 1 to clock_cycle_max loop

				clk <= not clk;
				wait for 1 ns;
				clk <= not clk;
				wait for 1 ns;

			end loop;

			wait;
		end if;

	end process tb_proc;

	currenttick_proc : process (clk, rst) is
	begin

		if (rst = '1') then
			currenttick <= 0;
		elsif (rising_edge(clk)) then
			currenttick <= currenttick + 1;
		end if;

	end process currenttick_proc;

end architecture testbench;