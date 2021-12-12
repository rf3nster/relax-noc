---------------------------------------------------------------------------
-- Component:
--    Router Crossbar Combinational Selector
-- Purpose:
--    Selects the appropriate transmitter to link crossbar with. 
--    Evaluation order is:
--    1) north when X co-ordinate of destination is lesser than current
--    2) south when X co-ordinate of destination is larger than current
--    3) west when Y co-ordinate of destination is lesser than current
--    4) east when Y co-ordinate of destination is greater than current
--    5) pe when X and Y co-ordinates of destination match current
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

entity xbar_comb is
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
end entity xbar_comb;

architecture xbar_comb_impl of xbar_comb is

	-- Channel signaling
	signal txselect_i      : xbar_directionselect_t;
	signal dataavailable_i : std_logic;

	-- X and Y location vectors
	signal router_loc_x_vec : std_logic_vector(x_bits - 1 downto 0);
	signal router_loc_y_vec : std_logic_vector(y_bits - 1 downto 0);
	alias dest_x            : std_logic_vector(x_bits - 1 downto 0) is destaddr (addr_width - 1 downto x_bits);
	alias dest_y            : std_logic_vector(x_bits - 1 downto 0) is destaddr (y_bits - 1 downto 0);

begin
		
	-- Cast x and y location vectors
	router_loc_x_vec <= std_logic_vector(to_unsigned(router_loc_x, router_loc_x_vec'length));
	router_loc_y_vec <= std_logic_vector(to_unsigned(router_loc_y, router_loc_y_vec'length)); 

	-- The great TX enable selector
	txselect <= txselect_i;

	tx_selector_proc : process (destaddr, enable, router_loc_y_vec, router_loc_x_vec, rx_select) is
	begin

		if (enable = '1') then
			-- If idle
			if ((dest_y = router_loc_y_vec) and (dest_x = router_loc_x_vec)) then
				txselect_i.north <= '0';
				txselect_i.south <= '0';
				txselect_i.west  <= '0';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '1';
			
			-- Check if going to 
			elsif (rx_select = "000") then
				txselect_i.north <= '0';
				txselect_i.south <= '0';
				txselect_i.west  <= '0';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '0';
				
			-- Check if going north
			elsif (dest_y < router_loc_y_vec) then
				txselect_i.north <= '1';
				txselect_i.south <= '0';
				txselect_i.west  <= '0';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '0';
				
			-- Check if going south
			elsif (dest_y > router_loc_y_vec) then
				txselect_i.north <= '0';
				txselect_i.south <= '1';
				txselect_i.west  <= '0';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '0';   
				
			-- Check if going west
			elsif (dest_x < router_loc_x_vec) then
				txselect_i.north <= '0';
				txselect_i.south <= '0';
				txselect_i.west  <= '1';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '0';  

			-- Check if going east
			elsif (dest_x > router_loc_x_vec) then
				txselect_i.north <= '0';
				txselect_i.south <= '0';
				txselect_i.west  <= '0';
				txselect_i.east  <= '1';
				txselect_i.pe    <= '0';   

			-- Fall back to inactive    
			else
				txselect_i.north <= '0';
				txselect_i.south <= '0';
				txselect_i.west  <= '0';
				txselect_i.east  <= '0';
				txselect_i.pe    <= '0';  
			end if; 
			
		-- Fall back to inactive                                                                      
		else
			txselect_i.north <= '0';
			txselect_i.south <= '0';
			txselect_i.west  <= '0';
			txselect_i.east  <= '0';
			txselect_i.pe    <= '0';
		end if;

	end process tx_selector_proc;

	-- Pop Request Multiplexer
	pop_rqst_mux_proc : process (txselect_i, rx_poprqst_in, enable) is 
	begin

		if (enable = '0') then
			rx_poprqst_out <= '0';
		elsif (txselect_i.north = '1') then
			rx_poprqst_out <= rx_poprqst_in.north;
		elsif (txselect_i.south = '1') then
			rx_poprqst_out <= rx_poprqst_in.south;
		elsif (txselect_i.west = '1') then
			rx_poprqst_out <= rx_poprqst_in.west;
		elsif (txselect_i.east = '1') then
			rx_poprqst_out <= rx_poprqst_in.east;
		elsif (txselect_i.pe = '1') then
			rx_poprqst_out <= rx_poprqst_in.pe; 
		else
			rx_poprqst_out <= '0';
		end if;

	end process pop_rqst_mux_proc;           

	-- Data Available Multiplexer
	dataavailable_out <= dataavailable_i;

	dataavailable_mux_proc : process (rx_dataavailable, rx_select, enable) is
	begin

		if (enable = '0' or rx_select = "000") then
			dataavailable_i <= '0';
		else
			
			case rx_select is
					
				when "001" =>
					dataavailable_i <= rx_dataavailable.north;
						
				when "010" =>
					dataavailable_i <= rx_dataavailable.south; 
						
				when "011" =>
					dataavailable_i <= rx_dataavailable.west;  
						
				when "100" =>
					dataavailable_i <= rx_dataavailable.east; 
						
				when "101" =>
					dataavailable_i <= rx_dataavailable.pe;
						
				when others =>
					dataavailable_i <= '0';

			end case;

		end if; 
 
	end process dataavailable_mux_proc;    

end architecture xbar_comb_impl;