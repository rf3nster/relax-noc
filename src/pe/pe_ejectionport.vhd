---------------------------------------------------------------------------
-- Component:
--    Processing Element Ejection Port
-- Purpose:
--    Top level of Ejection port to processing element. Passes data from 
--    router crossbar and passes to the processing element. 
--    Has two modes:
--      Mode 0: Accurate data across two 
--          channels. (2x 16 bit) 
--      Mode 1: Accurate data on one channel
--          transmitted over two cycles
--          and other channel is approx
--          data (16 bit) over one.
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
	use work.fifo_componentspkg.all;
	use work.noc_parameterspkg.all;
	use work.tx_componentspkg.all;

entity pe_ejectionport is 
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
end entity pe_ejectionport;

architecture pe_ejectionport_impl_new of pe_ejectionport is

	-- Signals for Channel A FIFO Data
	signal channela_datain_i  : std_logic_vector(channel_data_size + addr_data_size - 1 downto 0);
	signal channela_dataout_i : std_logic_vector(channel_data_size + addr_data_size - 1 downto 0);

	-- Signals for Channel A FIFO Control and Status
	signal channela_popen_i     : std_logic;
	signal channela_writeen_i   : std_logic;
	signal channela_fifofull_i  : std_logic;
	signal channela_fifoempty_i : std_logic;

	-- Signals for Channel A FIFO Data
	signal channelb_dataout_i : std_logic_vector(2 * channel_data_size - 1 downto 0);
	signal channelb_addrout_i : std_logic_vector(addr_data_size - 1 downto 0);

	-- Signals for Channel B FIFO Control and Status	
	signal channelb_writeen_i   : std_logic;
	signal channelb_popen_i     : std_logic;
	signal channelb_fifofull_i  : std_logic;
	signal channelb_fifoempty_i : std_logic;

begin
	
	-- Signal assignments for channel A data input
	channela_datain_i (channel_data_size + addr_data_size - 1 downto addr_data_size) <= packet_in.dataa;
	channela_datain_i (addr_data_size - 1 downto 0)                                  <= packet_in.addra;

	-- Signal assignments for multiplexing data available signals to processing element
	apxavailable <= '0' when (networkmode = '0') else
		not(channela_fifoempty_i) when (networkmode = '1');
	accavailable <= not(channelb_fifoempty_i);

	-- Data Valid
	datavalid <= '1' when  ((channelb_fifoempty_i = '0' and datatype = '0' and datarqst = '1') or (networkmode = '1' and datatype = '1' and datarqst = '1' and channela_fifoempty_i = '0')) else
			'0';

	-- Data Out Upper
	dataout(2 * channel_data_size - 1 downto channel_data_size) <= channela_dataout_i (channel_data_size + addr_data_size - 1 downto addr_data_size) when (networkmode = '0' or (networkmode = '1' and datatype = '1')) else
		channelb_dataout_i (2 * channel_data_size - 1 downto channel_data_size); 

	-- Data Out Lower
	dataout (channel_data_size - 1 downto 0) <= (others => '0') when (networkmode = '1' and datatype = '1') else
			channelb_dataout_i (channel_data_size - 1 downto 0); 

	-- Origin Out
	originout <= channela_dataout_i (addr_width - 1 downto 0) when (networkmode = '1' and datatype = '1') else
		channelb_addrout_i (addr_width - 1 downto 0); 

	-- Channel A Pop Logic
	channela_popen_i <= '1' when (channela_fifoempty_i = '0' and datarqst = '1' and (networkmode = '0' or (networkmode = '1' and datatype = '1'))) else
		'0';   
			
	-- Channel B Pop Logic
	channelb_popen_i <= '1' when (channelb_fifoempty_i = '0' and datarqst = '1' and datatype = '0') else
		'0';        

	-------------------------------------------
	---------- FIFO Instantiations ------------
	-------------------------------------------

	channela_fifo : component fifo_normal
		generic map (
			fifowidth => channel_data_size + addr_data_size,
			fifodepth => fifo_depth
		)
		port map (
			clk       => clk, 
			rst       => rst,
			writeen   => channela_writeen_i,
			popen     => channela_popen_i,
			datain    => channela_datain_i,
			dataout   => channela_dataout_i,
			fifoempty => channela_fifoempty_i,
			fifofull  => channela_fifofull_i
		);

	channelb_addrfifo : component fifo_dualpop
		generic map (
			fifowidth => addr_data_size,
			fifodepth => fifo_depth
		)
		port map (
			clk       => clk, 
			rst       => rst,
			dualpopen => networkmode,
			writeen   => channelb_writeen_i,
			popen     => channelb_popen_i,
			datain    => packet_in.addrb,
			dataout   => channelb_addrout_i
		);    

	channelb_datafifo : component fifo_dualoutput
		generic map (
			fifowidth => channel_data_size,
			fifodepth => fifo_depth
		)
		port map (
			clk          => clk, 
			rst          => rst,
			dualoutputen => networkmode,
			writeen      => channelb_writeen_i,
			popen        => channelb_popen_i,
			datain       => packet_in.datab,
			dataout      => channelb_dataout_i,
			fifoempty    => channelb_fifoempty_i,
			fifofull     => channelb_fifofull_i
		); 

	-------------------------------------------
	-------- Write FSM Instantiations ---------
	-------------------------------------------

	channela_writefsm : component tx_writefsm
		port map (
			clk              => clk,
			rst              => rst,
			fifo_full        => channela_fifofull_i,
			tx_select        => channela_txselect,
			rx_poprqst       => channela_poprqst,
			fifo_writeen     => channela_writeen_i,
			rx_dataavailable => channela_dataavailable
		);

	channelb_writefsm : component tx_writefsm
		port map (
			clk              => clk,
			rst              => rst,
			fifo_full        => channelb_fifofull_i,
			tx_select        => channelb_txselect,
			rx_poprqst       => channelb_poprqst,
			fifo_writeen     => channelb_writeen_i,
			rx_dataavailable => channelb_dataavailable
		);            
				   
end architecture pe_ejectionport_impl_new;