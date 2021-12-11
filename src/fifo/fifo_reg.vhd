---------------------------------------------------------------------------
-- Component: 
--     Register Primitive
-- Purpose:
--    Register primitive for FIFO Registers
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

entity fifo_reg is
	generic (
		reg_width : natural := 8
	);
	port (
		-- System Control
		clk : in    std_logic;
		rst : in    std_logic;

		-- FIFO Control
		write_en : in    std_logic;

		-- Data
		data_in  : in    std_logic_vector(reg_width - 1 downto 0);
		data_out : out   std_logic_vector(reg_width - 1 downto 0)
	);
end entity fifo_reg;

architecture impl of fifo_reg is

	-- Instantiate register
	signal reg_data : std_logic_vector(reg_width - 1 downto 0);

begin
	
	write_proc : process (clk, rst) is
	begin

		if (rst = '1') then
			reg_data <= (others => '0');
		elsif (rising_edge (clk)) then
			if (write_en = '1') then
				reg_data <= data_in;
			else
				reg_data <= reg_data;
			end if;
		end if;

	end process write_proc;

	data_out <= reg_data;

end architecture impl;
