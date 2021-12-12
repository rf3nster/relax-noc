---------------------------------------------------------------------------
-- Component:
--    Processing Element Injection Port
-- Purpose:
--    Top level of Injection port to crossbar. Takes data from processing
--    element and passes to the crossbar for injecting into the network. 
--    Has two modes:
--      Mode 0: Accurate data across two 
--          channels. (2 x N bit) 
--      Mode 1: Accurate data on one channel
--          transmitted over two cycles
--          and other channel is approx
--          data (N bit) over one.
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
	use work.rx_componentspkg.all;
	use work.pe_componentspkg.all;

entity pe_injectionport is 
	generic (
		addresswidth : integer                   := addr_data_size;
		fifowidth    : integer                   := channel_data_size;       
		fifodepth    : integer                   := fifo_depth;
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
end entity pe_injectionport;

architecture pe_injectionport_impl of pe_injectionport is

	attribute dont_touch                       : string;
	attribute dont_touch of channela_fifo     : label is "TRUE";
	attribute dont_touch of channelb_addrfifo : label is "TRUE";
	attribute dont_touch of channelb_datafifo : label is "TRUE";

	-- Address signal generation
	signal router_loc_x_vec : std_logic_vector(x_bits - 1 downto 0);
	signal router_loc_y_vec : std_logic_vector(y_bits - 1 downto 0);
	signal addrfifo_i       : std_logic_vector(addr_data_size - 1 downto 0);

	-- Control and Status signals for Channel A FIFOs
	signal channela_fifoempty_i : std_logic;
	signal channela_fifofull_i  : std_logic;
	signal channela_writeen_i   : std_logic;
	signal channela_popen_i     : std_logic;

	-- Signals for concatenation
	signal rx_channela_fifo_in  : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);
	signal rx_channela_fifo_out : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);    
	
	-- Control and Status signals for Channel B FIFOs
	signal channelb_fifoempty_i : std_logic;
	signal channelb_fifofull_i  : std_logic;
	signal channelb_writeen_i   : std_logic;
	signal channelb_popen_i     : std_logic;

begin 

	-- Concatenate everything (Channel A)
	rx_channela_fifo_in(addr_data_size + channel_data_size - 1 downto addr_data_size) <= datain (2 * channel_data_size - 1 downto channel_data_size);
	rx_channela_fifo_in(addr_data_size - 1 downto 0)                                  <= addrfifo_i;        
	rx_packet_out.dataa                                                               <= rx_channela_fifo_out (addr_data_size + channel_data_size - 1 downto addr_data_size);
	rx_packet_out.addra                                                               <= rx_channela_fifo_out (addr_data_size - 1 downto 0);   

	-------------------------------------------
	---------- FIFO Instantiations ------------
	-------------------------------------------

	-- Channel A
	channela_fifo : component fifo_normal
		generic map (
			fifowidth => (addr_data_size + channel_data_size),
			fifodepth => fifo_depth
		)
		port map (
			clk       => clk,
			rst       => rst,
			popen     => channela_popen_i, 
			writeen   => channela_writeen_i,
			fifofull  => channela_fifofull_i,
			fifoempty => channela_fifoempty_i,
			datain    => rx_channela_fifo_in,
			dataout   => rx_channela_fifo_out
		);
					
	-- Instance Channel B FIFOs
	channelb_addrfifo : component fifo_duplicatewrite
		generic map (
			fifowidth => addr_data_size,
			fifodepth => fifo_depth
		)
		port map (
			clk              => clk,
			rst              => rst,
			popen            => channelb_popen_i,
			writeen          => channelb_writeen_i,
			duplicatewriteen => networkmode,
			datain           => addrfifo_i,
			dataout          => rx_packet_out.addrb
		);

	channelb_datafifo : component fifo_dualwrite
		generic map (
			fifowidth => fifowidth,
			fifodepth => fifo_depth
		)
		port map (
			clk         => clk,
			rst         => rst,
			popen       => channelb_popen_i,
			writeen     => channelb_writeen_i,
			dualwriteen => networkmode,
			fifoempty   => channelb_fifoempty_i,
			fifofull    => channelb_fifofull_i,
			datain      => datain,
			dataout     => rx_packet_out.datab
		);
				
	-------------------------------------------
	-------- Read FSM Instantiations ----------
	-------------------------------------------

	chan_read_fsm : component rx_readfsm
		port map (
			clk           => clk, 
			rst           => rst, 
			fifo_empty    => channela_fifoempty_i, 
			fifo_popen    => channela_popen_i,
			fifo_poprqst  => channela_poprqst,
			dataavailable => channela_dataavailable,
			rx_select     => rx_channela_select
		);

	chanb_read_fsm : component rx_readfsm
		port map (
			clk           => clk, 
			rst           => rst, 
			fifo_empty    => channelb_fifoempty_i, 
			fifo_popen    => channelb_popen_i,
			fifo_poprqst  => channelb_poprqst,
			dataavailable => channelb_dataavailable,
			rx_select     => rx_channelb_select
		);
	
	---------------------------
	---     Processes       ---
	---------------------------
					
	-- Write process
	write_proc : process (networkmode, datatype, writeen, channela_fifofull_i, channelb_fifofull_i) is
	begin
	
		if (writeen = '1' and datatype = '0' and channelb_fifofull_i = '0' and networkmode = '1') then
			channelb_writeen_i <= '1';
			channela_writeen_i <= '0';
		elsif (writeen = '1' and datatype = '0' and channelb_fifofull_i = '0' and networkmode = '0') then
			channelb_writeen_i <= '1';
			channela_writeen_i <= '1';
		elsif (writeen = '1' and datatype = '1' and channela_fifofull_i = '0' and networkmode = '1') then 
			channelb_writeen_i <= '0';
			channela_writeen_i <= '1';
		else
			channelb_writeen_i <= '0';
			channela_writeen_i <= '0';
		end if;
	
	end process write_proc;

	-- Assignments for obtaining the current address and generating address parameters
	router_loc_x_vec <= std_logic_vector(to_unsigned(router_loc_x, router_loc_x_vec'length));
	router_loc_y_vec <= std_logic_vector(to_unsigned(router_loc_y, router_loc_y_vec'length));  
			
	-- Assign origin X   
	addrfifo_i (addr_width - 1 downto addr_width - x_bits) <= router_loc_x_vec;
		
	-- Assign origin Y   
	addrfifo_i (addr_width - x_bits - 1 downto addr_width - x_bits - y_bits) <= router_loc_y_vec;
			
	-- Assign destination X
	addrfifo_i (addr_data_size - 1 downto addr_data_size - x_bits) <= destin (addr_width - 1 downto x_bits);
			
	-- Assign destination Y
	addrfifo_i (addr_data_size - x_bits - 1 downto addr_data_size - x_bits - y_bits) <= destin (y_bits - 1 downto 0);

	-- Cast acc fifo full signal
	accfifofull <= channelb_fifofull_i;     
	
	-- Mux for APX full
	apxfifofull <= channela_fifofull_i when (networkmode = '1') else
		'0';
									  
end architecture pe_injectionport_impl;

