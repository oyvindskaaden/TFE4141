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
	--result <= message xor modulus;
	--ready_in <= ready_out;
	--valid_out <= valid_in;

	-- MultiMod Data in/out ready for partial block
    signal mm_dir_partial : std_logic;
    signal mm_dor_partial : std_logic;
    signal mm_div_partial : std_logic;
    signal mm_dov_partial : std_logic;
    
    -- MultiMod Data in/out ready for chipher block
    signal mm_dir_chipher : std_logic;
    signal mm_dor_chipher : std_logic;
    signal mm_div_chipher : std_logic;
    signal mm_dov_chipher : std_logic;

	signal exponent_lsb	  : std_logic;
	signal exponent_is_0  : std_logic;
	
	
    -- Reg control
    signal partial_reg_sel   : std_logic;
    signal chipher_reg_sel   : std_logic;
    signal exponent_reg_sel  : std_logic;
    
    -- Reg Load Control
    signal partial_reg_load  : std_logic;
    signal chipher_reg_load  : std_logic;
    signal exponent_reg_load : std_logic;
    
    signal mm_reset_n        : std_logic;



begin

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
			mm_div_partial    => mm_div_partial,
			mm_dov_partial    => mm_dov_partial,
			
			-- MultiMod Data in/out ready for chipher block
			mm_dir_chipher    => mm_dir_chipher,
			mm_dor_chipher    => mm_dor_chipher,
			mm_div_chipher    => mm_div_chipher,
			mm_dov_chipher    => mm_dov_chipher,

			-- Exponentiation data
			exponent_lsb	  => exponent_lsb,
			exponent_is_0	  => exponent_is_0,
			
			-- Reg control
            partial_reg_sel   => partial_reg_sel,
            chipher_reg_sel   => chipher_reg_sel,
            exponent_reg_sel  => exponent_reg_sel,

            -- Reg Load Contro 
            partial_reg_load  => partial_reg_load,
            chipher_reg_load  => chipher_reg_load,
            exponent_reg_load => exponent_reg_load,

			mm_reset_n 		  => mm_reset_n
			
	   );
	   
	u_exponentiation_datapath: entity work.exponentiation_datapath
		generic map (
			C_block_size        => C_block_size
		)
        port map (
            clk         => clk,
            reset_n     => reset_n,
            
            --input data
            message 	=> message,
            key 		=> key,
            
            --modulus
            modulus 	=> modulus,
            
            --output data
            result 		=> result,

			-- MultiMod Data in/out ready for partial block
			mm_dir_partial    => mm_dir_partial,
			mm_dor_partial    => mm_dor_partial,
			mm_div_partial    => mm_div_partial,
			mm_dov_partial    => mm_dov_partial,
			
			-- MultiMod Data in/out ready for chipher block
			mm_dir_chipher       => mm_dir_chipher,
			mm_dor_chipher       => mm_dor_chipher,
			mm_div_chipher       => mm_div_chipher,
			mm_dov_chipher       => mm_dov_chipher,
			
			mm_reset_n           => mm_reset_n,

			-- Exponentiation    data
			exponent_lsb	     => exponent_lsb,
			exponent_is_0	     => exponent_is_0,		
			
			-- Reg control
            partial_reg_sel      => partial_reg_sel,
            chipher_reg_sel      => chipher_reg_sel,
            exponent_reg_sel     => exponent_reg_sel,

            -- Reg Load Contro    
            partial_reg_load     => partial_reg_load,
            chipher_reg_load     => chipher_reg_load,
            exponent_reg_load    => exponent_reg_load

	   );

end expBehave;
