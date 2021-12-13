---------------------------------------------------------------------------
-- Component: 
--    Injection Port Driver
-- Purpose:
--    Drives Injection port, producing random packets to be injected into
--    the network. Has two architectures, one for purely random packets and
--    another for weighted types of mixed packets.
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
	use ieee.std_logic_textio.all;
	use std.textio.all;

library work;
	use work.noc_parameterspkg.all;
	use work.pe_componentspkg.all;
	use work.randompkg.all;
	use work.fifo_componentspkg.all;

entity pe_injectiondriver is
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
end entity pe_injectiondriver;

architecture weighted_impl of pe_injectiondriver is

	-- Transcript file
	file file_packet_transcript : text;

	-- Injection Buffer Control Signals
	signal injbuffer_popen_i   : std_logic;
	signal injbuffer_writeen_i : std_logic;

	-- Injection Buffer Status Signals
	signal injbuffer_fifoempty_i : std_logic;
	signal injbuffer_fifofull_i  : std_logic;

	-- Injection Buffer Data Signals
	signal injbuffer_in_i  : std_logic_vector(addr_width downto 0);
	signal injbuffer_out_i : std_logic_vector(addr_width downto 0);

	-- Injection times
	signal injectiontimes_i : integer_vector(packets_per_period - 1 downto 0);

	-- Current location integer conversion signals
	signal currlocation_int_i   : natural range 0 to (x_size * y_size - 1);
	signal currlocation_slv_i   : std_logic_vector(x_bits + y_bits - 1 downto 0);
	signal currlocation_x_slv_i : std_logic_vector(x_bits - 1 downto 0);
	signal currlocation_y_slv_i : std_logic_vector(y_bits - 1 downto 0);

	-- Clock cycle period tick count
	signal periodtick_i : natural range 0 to packet_period_size;

	-- Injection Count and control
	signal injectedcount_i         : natural range 0 to packet_qty;
	signal expectedinjectedcount_i : natural range 0 to packet_qty;
	signal doinjection_i           : std_logic;

	-- Aliases for injector buffer outputs
	alias injbuffer_destin_i     : std_logic_vector(addr_width - 1 downto 0) is injbuffer_in_i (addr_width downto 1); 
	alias injbuffer_datatypein_i : std_logic is injbuffer_in_i (0);  
           
begin

	-- Cast current location integers
	currlocation_x_slv_i                                   <= std_logic_vector(to_unsigned(x_coord, currlocation_x_slv_i'length));
	currlocation_y_slv_i                                   <= std_logic_vector(to_unsigned(y_coord, currlocation_y_slv_i'length));
	currlocation_slv_i (x_bits + y_bits - 1 downto y_bits) <= currlocation_x_slv_i;
	currlocation_slv_i (y_bits - 1 downto 0)               <= currlocation_y_slv_i;
	currlocation_int_i                                     <= to_integer(unsigned(currlocation_slv_i));

	-------------------------------------------
	----- Injection Buffer Instantiation ------
	-------------------------------------------

	injectionbuffer : component fifo_normal
		generic map (
			fifowidth => (addr_width + 1), fifoDepth => inj_buffer_depth
		)
		port map (
			clk       => clk,
			rst       => rst,
			popen     => injbuffer_popen_i,
			writeen   => injbuffer_writeen_i,
			fifoempty => injbuffer_fifoempty_i,
			fifofull  => injbuffer_fifofull_i,
			dataIn    => injbuffer_in_i,
			dataout   => injbuffer_out_i
		);
		
	-- Generate injection times
	times_gen_proc : process (clk, rst) is

		variable injectiontimes_rand : randomptype;

	begin

		if (rst = '1') then
			report "Generating New Seeds" 
				severity note;
                   injectionTimes_rand.InitSeed(injectionTimes_rand'instance_name & to_string(x_coord)&to_string(y_coord) &"0.7225013680664656");
			injectiontimes_i <= injectiontimes_rand.RandIntV(0, (packet_period_size - 1), packets_per_period, packets_per_period);
		end if;

	end process times_gen_proc;

	-- Injection process
	injection_proc : process (clk, rst) is 

		variable injtime_match_inj_v : boolean;
		variable doinjection_v       : boolean;
		variable randdest            : randomptype;
		variable randtype            : randomptype;
		variable isapx_v             : boolean;

	begin

		if (rst = '1') then
			-- Generate new seeds
			randdest.InitSeed(randdest'instance_name);
                   randType.InitSeed(randDest'instance_name&to_string(x_coord)&to_string(y_coord) &"0.5198078759010308");
			
			-- Reset counters
			periodtick_i            <= 0;
			injectedcount_i         <= 0;
			expectedinjectedcount_i <= 0;
		elsif (rising_edge (clk)) then
			-- Increment or roll over period counter
			isapx_v := randtype.DistBool((acc_data_weight, apx_data_weight));
			if (periodtick_i = packet_period_size - 1) then
				periodtick_i <= 0;
			else
				periodtick_i <= periodtick_i + 1;
			end if;
			
			-- Check if there's a match to see if we need to inject at this cycle
			for i in 0 to packets_per_period - 1 loop
				
				-- Allowed to inject?
				if (periodtick_i = injectiontimes_i(i) and injectionEnable = '1' and expectedinjectedcount_i /= packet_qty) then
					expectedinjectedcount_i <= expectedinjectedcount_i + 1;
					-- -- Increment expected push
					if (injbuffer_fifofull_i = '0') then
						doinjection_v := true;
						injectedcount_i <= injectedcount_i + 1;
					else
						doinjection_v := false;
					end if;
					exit;
				else
					doinjection_v := false;
				end if;

			end loop;

			-- If nothing matches. check and see if there's a deficit
			if (doinjection_v = false and (expectedinjectedcount_i > injectedcount_i) and injbuffer_fifofull_i = '0') then
				doinjection_v := true;
			end if;
				
			-- Now check for the actual injection
			if (doinjection_v = true) then
				injbuffer_destin_i   <= randdest.RandSlv (0, (2 ** x_bits * 2 ** y_bits - 1), (currlocation_int_i, currlocation_int_i), injbuffer_destin_i'length);
				injbuffer_writeen_i  <= '1';
				isapx_v := randtype.DistBool((acc_data_weight, apx_data_weight));
				if (isapx_v  = true and networkmode = '1') then
					injbuffer_datatypein_i <= '1';
				else
					injbuffer_datatypein_i <= '0';
				end if;
			else
				injbuffer_datatypein_i <= '0';
				injbuffer_writeen_i    <= '0';
			end if;
		end if;

	end process injection_proc;

	-- Popping process
	pop_proc : process (injbuffer_fifoempty_i, accfifofull, apxfifofull, injbuffer_out_i(0)) is

	begin

		if (injbuffer_out_i(0) = '0' and accfifofull = '0' and injbuffer_fifoempty_i = '0') then
			injbuffer_popen_i <= '1';
			writeen           <= '1';
		elsif (injbuffer_out_i(0) = '1' and apxfifofull = '0' and injbuffer_fifoempty_i = '0') then
			injbuffer_popen_i <= '1';
			writeen           <= '1';
		else
			injbuffer_popen_i <= '0';
			writeen           <= '0';
		end if;

	end process pop_proc;

	file_write_proc : process (clk) is

		variable buf_line_out : line;

	begin
		if (rst = '1') then 
			-- Clear sent transcript
			file_open(file_packet_transcript, "./transcript_data/transcript_sent_"&INTEGER'IMAGE(x_coord)&"_"&INTEGER'IMAGE(y_coord)&".csv", write_mode);
			file_close(file_packet_transcript);		
		elsif (falling_edge(clk)) then
			if (injbuffer_popen_i = '1') then
				file_open(file_packet_transcript, "./transcript_data/transcript_sent_"&INTEGER'IMAGE(x_coord)&"_"&INTEGER'IMAGE(y_coord)&".csv", append_mode);
				
				-- Write ID
				write(buf_line_out, to_integer(unsigned(dataout (2 * channel_data_size - 1 downto channel_data_size))));
				write(buf_line_out, string'(","));
				
				-- Write Time Injected
				write(buf_line_out, to_integer(unsigned(dataout (2 * channel_data_size - 1 downto (2*channel_data_size - cc_max_width)))));
				write(buf_line_out, string'(","));
				
				-- Write Data Type
				if (datatype = '1') then
					write(buf_line_out, string'("Approximate"));
				else
					write(buf_line_out, string'("Accurate"));
				end if;   
				write(buf_line_out, string'(","));                 
				
				-- Write destination X
				write(buf_line_out, to_integer(unsigned(destout (x_bits + y_bits - 1 downto x_bits))));
				write(buf_line_out, string'(","));                    
				
				-- Write destination Y
				write(buf_line_out, to_integer(unsigned(destout (y_bits - 1 downto 0))));
				write(buf_line_out, string'(","));                        
				writeline(file_packet_transcript, buf_line_out);
				file_close(file_packet_transcript);
			end if;
		end if;

	end process file_write_proc;

	-- Cast signals to output
	datatype                                                                         <= injbuffer_out_i(0);
	destout                                                                          <= injbuffer_out_i (addr_width downto 1);
	dataout(channel_data_size - 1 downto 0)                                          <= (others => '0');
	dataout(2 * channel_data_size - 1 downto (2 * channel_data_size - cc_max_width)) <= std_logic_vector(currenttick);
	dataout(channel_data_size + (x_bits + y_bits - 1) downto channel_data_size)      <= currlocation_slv_i;

end architecture weighted_impl;