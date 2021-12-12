---------------------------------------------------------------------------
-- Component:
--    Tile Router
-- Purpose:
--    Routes data across multiple links for a mesh network configuration.
-- 
-- Requires: VHDL-2008
-- 
-- Written on April 20/2021
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

-- Library defines
library ieee;
library work;

-- Use packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.noc_parametersPkg.all;
use work.xbar_componentsPkg.all;
use work.rx_componentsPkg.all;
use work.tx_componentsPkg.all;

entity router_top is
	generic (
		router_loc_x : integer range 0 to x_size := 0;
		router_loc_y : integer range 0 to y_size := 0
	);
	port (
		-- System control
		clk         : in    std_logic;
		rst         : in    std_logic;
		networkmode : in    std_logic;

		-------------
		-- RX Side --
		-------------
		-- North
		rx_north_packet       : in    packet_t;
		rx_north_channelvalid : in    channelvalid_t;
		rx_north_cleartosend  : out   cleartosend_t;
		-- South
		rx_south_packet       : in    packet_t;
		rx_south_channelvalid : in    channelvalid_t;
		rx_south_cleartosend  : out   cleartosend_t;
		-- West
		rx_west_packet       : in    packet_t;
		rx_west_channelvalid : in    channelvalid_t;
		rx_west_cleartosend  : out   cleartosend_t;
		-- East
		rx_east_packet       : in    packet_t;
		rx_east_channelvalid : in    channelvalid_t;
		rx_east_cleartosend  : out   cleartosend_t;
		-- PE Injection
		rx_pe_packet                 : in    packet_t;
		rx_pe_channela_dataavailable : in    std_logic;
		rx_pe_channelb_dataavailable : in    std_logic;
		rx_pe_channela_poprqst       : out   std_logic;
		rx_pe_channelb_poprqst       : out   std_logic;
		rx_pe_channela_select        : out   std_logic;
		rx_pe_channelb_select        : out   std_logic;

		-------------
		-- TX Side --
		-------------
		-- North
		tx_north_cleartosend  : in    cleartosend_t;
		tx_north_packet       : out   packet_t;
		tx_north_channelvalid : out   channelvalid_t;
		-- South
		tx_south_cleartosend  : in    cleartosend_t;
		tx_south_packet       : out   packet_t;
		tx_south_channelvalid : out   channelvalid_t;
		-- West
		tx_west_cleartosend  : in    cleartosend_t;
		tx_west_packet       : out   packet_t;
		tx_west_channelvalid : out   channelvalid_t;
		-- East
		tx_east_cleartosend  : in    cleartosend_t;
		tx_east_packet       : out   packet_t;
		tx_east_channelvalid : out   channelvalid_t;
		-- PE Ejection
		tx_pe_channela_poprqst       : in    std_logic;
		tx_pe_channelb_poprqst       : in    std_logic; 
		tx_pe_packet                 : out   packet_t;
		tx_pe_channela_dataavailable : out   std_logic;
		tx_pe_channelb_dataavailable : out   std_logic;
		tx_pe_channela_txselect      : out   std_logic;
		tx_pe_channelb_txselect      : out   std_logic     
	);
end entity router_top;

architecture router_top_impl of router_top is

	-- Signals for packets
	signal tx_packet_i       : packet_t;
	signal rx_pe_packet_i    : packet_t;
	signal rx_north_packet_i : packet_t;
	signal rx_south_packet_i : packet_t;
	signal rx_west_packet_i  : packet_t;
	signal rx_east_packet_i  : packet_t;

	-- Signals for data available
	signal rx_channela_dataavailable_i : xbar_dataavailable_t;
	signal rx_channelb_dataavailable_i : xbar_dataavailable_t;

	-- Signals for RX pop request
	signal rx_channela_poprqst_i : std_logic;
	signal rx_channelb_poprqst_i : std_logic;

	-- Signals for RX Select
	signal rx_channela_sel_i : xbar_directionselect_t;
	signal rx_channelb_sel_i : xbar_directionselect_t;

	-- Signals for TX select
	signal tx_channela_sel_i : xbar_directionselect_t;
	signal tx_channelb_sel_i : xbar_directionselect_t;

	-- Signals for TX data available out
	signal tx_channela_dataavailable_i : std_logic;
	signal tx_channelb_dataavailable_i : std_logic;

	-- Signals for TX issued Pop Request
	signal tx_channela_poprqst_i : xbar_poprqst_t;
	signal tx_channelb_poprqst_i : xbar_poprqst_t;
		
begin

	---------------------
	--- Implement RX  ---
	---------------------
	rx_north : component rx_top
		port map (
			clk                    => clk, 
			rst                    => rst,
			networkmode            => networkmode,
			rx_packet_in           => rx_north_packet,
			rx_packet_out          => rx_north_packet_i,
			rx_cleartosend         => rx_north_cleartosend,
			rx_channelvalid        => rx_north_channelvalid,
			channela_dataavailable => rx_channela_dataavailable_i.north,
			channelb_dataavailable => rx_channelb_dataavailable_i.north,
			channela_poprqst       => rx_channela_poprqst_i,
			channelb_poprqst       => rx_channelb_poprqst_i,
			rx_channela_select     => rx_channela_sel_i.north,
			rx_channelb_select     => rx_channelb_sel_i.north
		);
	
	rx_south : component rx_top
		port map (
			clk                    => clk,
			rst                    => rst,  
			networkmode            => networkmode,
			rx_packet_in           => rx_south_packet,
			rx_packet_out          => rx_south_packet_i,
			rx_cleartosend         => rx_south_cleartosend,
			rx_channelvalid        => rx_south_channelvalid,
			channela_dataavailable => rx_channela_dataavailable_i.south,
			channelb_dataavailable => rx_channelb_dataavailable_i.south,
			channela_poprqst       => rx_channela_poprqst_i,
			channelb_poprqst       => rx_channelb_poprqst_i,
			rx_channela_select     => rx_channela_sel_i.south,
			rx_channelb_select     => rx_channelb_sel_i.south
		);

	rx_west : rx_top
		port map (
			clk                    => clk, 
			rst                    => rst, 
			networkmode            => networkmode,
			rx_packet_in           => rx_west_packet,
			rx_packet_out          => rx_west_packet_i,
			rx_cleartosend         => rx_west_cleartosend,
			rx_channelvalid        => rx_west_channelvalid,
			channela_dataavailable => rx_channela_dataavailable_i.west,
			channelb_dataavailable => rx_channelb_dataavailable_i.west,
			channela_poprqst       => rx_channela_poprqst_i,
			channelb_poprqst       => rx_channelb_poprqst_i,
			rx_channela_select     => rx_channela_sel_i.west,
			rx_channelb_select     => rx_channelb_sel_i.west
		);
			
	rx_east : component rx_top
		port map (
			clk                    => clk,
			rst                    => rst, 
			networkmode            => networkmode,
			rx_packet_in           => rx_east_packet,
			rx_packet_out          => rx_east_packet_i,
			rx_cleartosend         => rx_east_cleartosend,
			rx_channelvalid        => rx_east_channelvalid,
			channela_dataavailable => rx_channela_dataavailable_i.east,
			channelb_dataavailable => rx_channelb_dataavailable_i.east,
			channela_poprqst       => rx_channela_poprqst_i,
			channelb_poprqst       => rx_channelb_poprqst_i,
			rx_channela_select     => rx_channela_sel_i.east,
			rx_channelb_select     => rx_channelb_sel_i.east
		);
			
	-- Cast PE Injection signals
	rx_pe_packet_i                 <= rx_pe_packet;
	rx_channela_dataavailable_i.pe <= rx_pe_channela_dataavailable;
	rx_channelb_dataavailable_i.pe <= rx_pe_channelb_dataavailable;
	rx_pe_channela_poprqst         <= rx_channela_poprqst_i;
	rx_pe_channelb_poprqst         <= rx_channelb_poprqst_i;
	rx_pe_channela_select          <= rx_channela_sel_i.pe ;
	rx_pe_channelb_select          <= rx_channelb_sel_i.pe ;
																							
	---------------------
	--- Implement TX  ---
	---------------------
	tx_north : component tx_top
		port map (
			clk                    => clk, 
			rst                    => rst,
			networkmode            => networkmode,
			tx_packet_in           => tx_packet_i,
			tx_packet_out          => tx_north_packet, 
			tx_cleartosend         => tx_north_cleartosend,
			tx_channelvalid        => tx_north_channelvalid,
			channela_dataavailable => tx_channela_dataavailable_i,
			channelb_dataavailable => tx_channelb_dataavailable_i,
			channela_txselect      => tx_channela_sel_i.north,
			channelb_txselect      => tx_channelb_sel_i.north,
			channela_poprqst       => tx_channela_poprqst_i.north,
			channelb_poprqst       => tx_channelb_poprqst_i.north
		);

	tx_south : component tx_top
		port map (
			clk                    => clk,
			rst                    => rst,
			networkmode            => networkmode,
			tx_packet_in           => tx_packet_i,
			tx_packet_out          => tx_south_packet, 
			tx_cleartosend         => tx_south_cleartosend,
			tx_channelvalid        => tx_south_channelvalid,
			channela_dataavailable => tx_channela_dataavailable_i,
			channelb_dataavailable => tx_channelb_dataavailable_i,
			channela_txselect      => tx_channela_sel_i.south,
			channelb_txselect      => tx_channelb_sel_i.south,
			channela_poprqst       => tx_channela_poprqst_i.south,
			channelb_poprqst       => tx_channelb_poprqst_i.south
		);
		
	tx_west : component tx_top
		port map (
			clk                    => clk,
			rst                    => rst, 
			networkmode            => networkmode,
			tx_packet_in           => tx_packet_i,
			tx_packet_out          => tx_west_packet, 
			tx_cleartosend         => tx_west_cleartosend,
			tx_channelvalid        => tx_west_channelvalid,
			channela_dataavailable => tx_channela_dataavailable_i,
			channelb_dataavailable => tx_channelb_dataavailable_i,
			channela_txselect      => tx_channela_sel_i.west,
			channelb_txselect      => tx_channelb_sel_i.west,
			channela_poprqst       => tx_channela_poprqst_i.west,
			channelb_poprqst       => tx_channelb_poprqst_i.west
		);   

	tx_east : component tx_top
		port map (
			clk                    => clk, 
			rst                    => rst,
			 networkmode           => networkmode,
			tx_packet_in           => tx_packet_i,
			tx_packet_out          => tx_east_packet, 
			tx_cleartosend         => tx_east_cleartosend,
			tx_channelvalid        => tx_east_channelvalid,
			channela_dataavailable => tx_channela_dataavailable_i,
			channelb_dataavailable => tx_channelb_dataavailable_i,
			channela_txselect      => tx_channela_sel_i.east,
			channelb_txselect      => tx_channelb_sel_i.east,
			channela_poprqst       => tx_channela_poprqst_i.east,
			channelb_poprqst       => tx_channelb_poprqst_i.east
		);    
		
	-- Cast PE Ejection Signals
	tx_pe_packet                 <= tx_packet_i;
	tx_pe_channela_dataavailable <= tx_channela_dataavailable_i;
	tx_pe_channelb_dataavailable <= tx_channelb_dataavailable_i;
	tx_pe_channela_txselect      <= tx_channela_sel_i.pe;
	tx_pe_channelb_txselect      <= tx_channelb_sel_i.pe;
	tx_channela_poprqst_i.pe     <= tx_pe_channela_poprqst;
	tx_channelb_poprqst_i.pe     <= tx_pe_channelb_poprqst;                

	-- Implement the big kahuna (crossbar)
	router_crossbar : xbar_top
		generic map (
			router_loc_x => router_loc_x, 
			router_loc_y => router_loc_y
		)
		port map (
			clk                       => clk,
			rst                       => rst,
			networkmode               => networkmode,
			rx_north_packet           => rx_north_packet_i,
			rx_south_packet           => rx_south_packet_i,
			rx_west_packet            => rx_west_packet_i,
			rx_east_packet            => rx_east_packet_i,
			rx_pe_packet              => rx_pe_packet_i,
			tx_packet                 => tx_packet_i,
			rx_channela_sel           => rx_channela_sel_i,
			rx_channelb_sel           => rx_channelb_sel_i,
			tx_channela_sel           => tx_channela_sel_i,
			tx_channelb_sel           => tx_channelb_sel_i,
			rx_channela_dataavailable_in  => rx_channela_dataavailable_i,
			rx_channelb_dataavailable_in  => rx_channelb_dataavailable_i,
			tx_channela_dataavailable_out => tx_channela_dataavailable_i,
			tx_channelb_dataavailable_out => tx_channelb_dataavailable_i,
			rx_channela_poprqst_out   => rx_channela_poprqst_i,
			rx_channelb_poprqst_out   => rx_channelb_poprqst_i,
			tx_channela_poprqst_in    => tx_channela_poprqst_i,
			tx_channelb_poprqst_in    => tx_channelb_poprqst_i
		);

end architecture router_top_impl;