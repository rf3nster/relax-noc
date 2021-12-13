---------------------------------------------------------------------------
-- Component:
--    Router Crossbar
-- Purpose:
--    Provides interconnection among receivers and transmitters of router.
--    Passes data from receivers to transmitters or processing elements.
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
	use work.xbar_componentspkg.all;

entity xbar_top is
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
		rx_channela_dataavailable_in : in    xbar_dataavailable_t;
		rx_channelb_dataavailable_in : in    xbar_dataavailable_t;

		-- TX
		tx_channela_dataavailable_out : out   std_logic;
		tx_channelb_dataavailable_out : out   std_logic;

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
end entity xbar_top;

architecture xbar_top_impl of xbar_top is

	-- Direction select signals
	signal acc_rx_select_i      : unsigned (2 downto 0);
	signal apx_rx_select_i      : unsigned (2 downto 0);
	signal channela_rx_select_i : unsigned (2 downto 0);

	-- Data Signals
	signal xbar_channelb_data_i : std_logic_vector(channel_data_size - 1 downto 0);
	signal xbar_channela_data_i : std_logic_vector(channel_data_size - 1 downto 0);

	-- Address signals
	signal xbar_channelb_addr_i : std_logic_vector(addr_data_size - 1 downto 0);
	signal xbar_channela_addr_i : std_logic_vector(addr_data_size - 1 downto 0);
	alias xbar_channelb_dest_i  : std_logic_vector(addr_width - 1 downto 0) is xbar_channelb_addr_i(addr_data_size - 1 downto addr_width);
	alias xbar_channela_dest_i  : std_logic_vector(addr_width - 1 downto 0) is xbar_channela_addr_i(addr_data_size - 1 downto addr_width);

	-- Channel A signaling
	signal tx_channela_sel_i       : xbar_directionselect_t;
	signal rx_channela_sel_i       : xbar_directionselect_t;
	signal tx_channela_dataavailable_i : std_logic;
	signal rx_channela_poprqst_i   : std_logic;

	-- Channel B signaling
	signal tx_channelb_sel_i       : xbar_directionselect_t;
	signal rx_channelb_sel_i       : xbar_directionselect_t;
	signal tx_channelb_dataavailable_i : std_logic;
	signal rx_channelb_poprqst_i   : std_logic;

begin

	--------------------------------------
	-- Processes
	--------------------------------------
		
	-- Switch for which selector
	selector_mux_proc : process (acc_rx_select_i, apx_rx_select_i, networkmode) is 
	begin

		if (networkmode = '1') then
			channela_rx_select_i <= apx_rx_select_i;
		else
			channela_rx_select_i <= acc_rx_select_i;
		end if;
			
	end process selector_mux_proc;

	-- Create packet mux for channel A
	channela_packet_mux_proc : process (rx_pe_packet, rx_north_packet, rx_south_packet, rx_west_packet, rx_east_packet, channela_rx_select_i) is
	begin

		case channela_rx_select_i is

			when "001" =>

				xbar_channela_data_i <= rx_north_packet.dataa;
				xbar_channela_addr_i <= rx_north_packet.addra;
		
			when "010" =>
		
				xbar_channela_data_i <= rx_south_packet.dataa;
				xbar_channela_addr_i <= rx_south_packet.addra;
			
			when "011" =>
			
				xbar_channela_data_i <= rx_west_packet.dataa;
				xbar_channela_addr_i <= rx_west_packet.addra;
			
			when "100" =>
		
				xbar_channela_data_i <= rx_east_packet.dataa;
				xbar_channela_addr_i <= rx_east_packet.addra;
			
			when "101" =>
	
				xbar_channela_data_i <= rx_pe_packet.dataa;
				xbar_channela_addr_i <= rx_pe_packet.addra;                                                                                                
	
			when others =>
				xbar_channela_data_i <= (others => '0');
				xbar_channela_addr_i <= (others => '0');

		end case;
		
	end process channela_packet_mux_proc;

	-- Create packet mux for channel B
	channelb_packet_mux_proc : process (rx_pe_packet, rx_north_packet, rx_south_packet, rx_west_packet, rx_east_packet, acc_rx_select_i) is
	begin

		case acc_rx_select_i is
		
			when "001" =>
		
				xbar_channelb_data_i <= rx_north_packet.datab;
				xbar_channelb_addr_i <= rx_north_packet.addrb;
		
			when "010" =>
		
				xbar_channelb_data_i <= rx_south_packet.datab;
				xbar_channelb_addr_i <= rx_south_packet.addrb;
			
			when "011" =>
		
				xbar_channelb_data_i <= rx_west_packet.datab;
				xbar_channelb_addr_i <= rx_west_packet.addrb;
			
			when "100" =>
		
				xbar_channelb_data_i <= rx_east_packet.datab;
				xbar_channelb_addr_i <= rx_east_packet.addrb;
			
			when "101" =>
		
				xbar_channelb_data_i <= rx_pe_packet.datab;
				xbar_channelb_addr_i <= rx_pe_packet.addrb;                                                                                               
			
			when others =>
		
				xbar_channelb_data_i <= (others => '0');
				xbar_channelb_addr_i <= (others => '0');
			
		end case;
	
	end process channelb_packet_mux_proc;

	-- RX select decoder
	rx_sel_proc : process (acc_rx_select_i, apx_rx_select_i) is
	begin

		case acc_rx_select_i is

			when "001" =>

				rx_channelb_sel_i.north <= '1';
				rx_channelb_sel_i.south <= '0';
				rx_channelb_sel_i.west  <= '0';
				rx_channelb_sel_i.east  <= '0';
				rx_channelb_sel_i.pe    <= '0';
				
			when "010" =>
		
				rx_channelb_sel_i.north <= '0';
				rx_channelb_sel_i.south <= '1';
				rx_channelb_sel_i.west  <= '0';
				rx_channelb_sel_i.east  <= '0';
				rx_channelb_sel_i.pe    <= '0';
			
			when "011" =>
		
				rx_channelb_sel_i.north <= '0';
				rx_channelb_sel_i.south <= '0';
				rx_channelb_sel_i.west  <= '1';
				rx_channelb_sel_i.east  <= '0';
				rx_channelb_sel_i.pe    <= '0';
			
			when "100" =>
			
				rx_channelb_sel_i.north <= '0';
				rx_channelb_sel_i.south <= '0';
				rx_channelb_sel_i.west  <= '0';
				rx_channelb_sel_i.east  <= '1';
				rx_channelb_sel_i.pe    <= '0';
				
			when "101" =>
			
				rx_channelb_sel_i.north <= '0';
				rx_channelb_sel_i.south <= '0';
				rx_channelb_sel_i.west  <= '0';
				rx_channelb_sel_i.east  <= '0';
				rx_channelb_sel_i.pe    <= '1';
				
			when others =>
	
				rx_channelb_sel_i.north <= '0';
				rx_channelb_sel_i.south <= '0';
				rx_channelb_sel_i.west  <= '0';
				rx_channelb_sel_i.east  <= '0';
				rx_channelb_sel_i.pe    <= '0';
			
		end case; 
				
		case apx_rx_select_i is
		
			when "001" =>
		
				rx_channela_sel_i.north <= '1';
				rx_channela_sel_i.south <= '0';
				rx_channela_sel_i.west  <= '0';
				rx_channela_sel_i.east  <= '0';
				rx_channela_sel_i.pe    <= '0';
			
			when "010" =>
			
				rx_channela_sel_i.north <= '0';
				rx_channela_sel_i.south <= '1';
				rx_channela_sel_i.west  <= '0';
				rx_channela_sel_i.east  <= '0';
				rx_channela_sel_i.pe    <= '0';
		
			when "011" =>
			
				rx_channela_sel_i.north <= '0';
				rx_channela_sel_i.south <= '0';
				rx_channela_sel_i.west  <= '1';
				rx_channela_sel_i.east  <= '0';
				rx_channela_sel_i.pe    <= '0';
				
			when "100" =>
			
				rx_channela_sel_i.north <= '0';
				rx_channela_sel_i.south <= '0';
				rx_channela_sel_i.west  <= '0';
				rx_channela_sel_i.east  <= '1';
				rx_channela_sel_i.pe    <= '0';
				
			when "101" =>
			
				rx_channela_sel_i.north <= '0';
				rx_channela_sel_i.south <= '0';
				rx_channela_sel_i.west  <= '0';
				rx_channela_sel_i.east  <= '0';
				rx_channela_sel_i.pe    <= '1';
				
			when others =>
			
				rx_channela_sel_i.north <= '0';
				rx_channela_sel_i.south <= '0';
				rx_channela_sel_i.west  <= '0';
				rx_channela_sel_i.east  <= '0';
				rx_channela_sel_i.pe    <= '0';
				
		end case; 
		
	end process rx_sel_proc;

	--------------------------------------
	-- Instantiation of Sub-Components
	--------------------------------------
	xbar_acc_comb : component xbar_comb
		generic map (
			router_loc_x => router_loc_x, 
			router_loc_y => router_loc_y
		)
		port map (
			enable            => '1',
			destaddr          => xbar_channelb_dest_i,
			txselect          => tx_channelb_sel_i, 
			dataavailable_out => tx_channelb_dataavailable_i,
			rx_dataavailable  => rx_channelb_dataavailable_in,
			rx_select         => acc_rx_select_i,
			rx_poprqst_in     => tx_channelb_poprqst_in,
			rx_poprqst_out    => rx_channelb_poprqst_i
		);

	-- Instance apx combinational logic
	xbar_apx_comb : component xbar_comb
		generic map (
			router_loc_x => router_loc_x, 
			router_loc_y => router_loc_y
		)
		port map (
			enable            => networkmode,
			destaddr          => xbar_channela_dest_i,
			txselect          => tx_channela_sel_i, 
			dataavailable_out => tx_channela_dataavailable_i,
			rx_dataavailable  => rx_channela_dataavailable_in,
			rx_select         => apx_rx_select_i,
			rx_poprqst_in     => tx_channela_poprqst_in,
			rx_poprqst_out    => rx_channela_poprqst_i
		);                
		
	-- Instance Accurate FSM
	xbar_acc_fsm : component xbar_fsm
		port map (
			clk            => clk,
			rst            => rst, 
			secondcycle_en => networkmode,
			dataavailable  => rx_channelb_dataavailable_in,
			enable         => '1',
			fifoselect     => acc_rx_select_i
		);
	
	-- Instance Accurate FSM
	xbar_apx_fsm : component xbar_fsm
		port map (
			clk            => clk,
			rst            => rst,
			secondcycle_en => '0',
			dataavailable  => rx_channela_dataavailable_in,
			enable         => networkmode,
			fifoselect     => apx_rx_select_i
		);

	--------------------------------------
	-- Signal casting
	--------------------------------------

	-- Cast signals for TX Packet
	tx_packet.dataa <= xbar_channela_data_i;
	tx_packet.datab <= xbar_channelb_data_i;
	tx_packet.addra <= xbar_channela_addr_i;
	tx_packet.addrb <= xbar_channelb_addr_i;
		
	-- Cast channel B control signals externally
	tx_channelb_sel           <= tx_channelb_sel_i;
	tx_channelb_dataavailable_out <= tx_channelb_dataavailable_i;
	rx_channelb_poprqst_out   <= rx_channelb_poprqst_i;
	rx_channelb_sel           <= rx_channelb_sel_i;

	--------------------------------------
	-- Chanenl A Multiplexers
	--------------------------------------
	tx_channela_sel           <= tx_channela_sel_i when (networkmode = '1') else
		tx_channelb_sel_i;
	tx_channela_dataavailable_out <= tx_channela_dataavailable_i when (networkmode = '1') else
			tx_channelb_dataavailable_out;
	rx_channela_poprqst_out   <= rx_channela_poprqst_i when (networkmode = '1') else
			rx_channelb_poprqst_i;
	rx_channela_sel           <= rx_channela_sel_i when (networkmode = '1') else
		rx_channelb_sel_i;
		
end architecture xbar_top_impl;