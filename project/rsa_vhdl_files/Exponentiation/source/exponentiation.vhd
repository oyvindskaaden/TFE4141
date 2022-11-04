----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/18/2022 11:31:01 AM
-- Design Name: 
-- Module Name: multi_mod_datapath - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in    STD_LOGIC;
		ready_in	: out   STD_LOGIC;
                            
		--input data
		message 	: in    STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in    STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in    STD_LOGIC;
		valid_out	: out   STD_LOGIC;

		--output data
		result 		: out   STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in    STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in    STD_LOGIC;
		reset_n 	: in    STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is
begin
	--result <= message xor modulus;
	--ready_in <= ready_out;
	--valid_out <= valid_in;

	-- MultiMod Data in/out ready for partial block
    signal mm_dir_partial : std_logic;
    signal mm_dor_partial : std_logic;
    
    -- MultiMod Data in/out ready for chipher block
    signal mm_dir_chipher : std_logic;
    signal mm_dor_chipher : std_logic;

	signal exponent_lsb	  : std_logic;
	signal exponent_is_0  : std_logic;

	u_exponentiation_control: entity work.exponentiation_control
	   port map (
	        -- Clock and Reset
            clk         => clk,
            reset_n     => reset_n,
            
            --input controll
            valid_in    => valid_in,
            ready_in    => ready_in,
            
            --ouput controll
            ready_out   => ready_out,
            valid_out   => valid_out,

			-- MultiMod Data in/out ready for partial block
			mm_dir_partial    => mm_dir_partial,
			mm_dor_partial    => mm_dor_partial,
			
			-- MultiMod Data in/out ready for chipher block
			mm_dir_chipher    => mm_dir_chipher,
			mm_dor_chipher    => mm_dor_chipher,

			-- Exponentiation data
			exponent_lsb	  => exponent_lsb,
			exponent_is_0	  => exponent_is_0
	   );
	   
	u_exponentiation_datapath: entity work.exponentiation_datapath
        port map (
            clk         => clk,
            reset_n     => reset_n,
            
            --input data
            message 	=> message,
            key 		=> key,
            
            --modulus
            modulus 	=> modulus,
            
            --output data
            result 		=> result

			-- MultiMod Data in/out ready for partial block
			mm_dir_partial    => mm_dir_partial,
			mm_dor_partial    => mm_dor_partial,
			
			-- MultiMod Data in/out ready for chipher block
			mm_dir_chipher    => mm_dir_chipher,
			mm_dor_chipher    => mm_dor_chipher,

			-- Exponentiation data
			exponent_lsb	  => exponent_lsb,
			exponent_is_0	  => exponent_is_0
	   );

end expBehave;
