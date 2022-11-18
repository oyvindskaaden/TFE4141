----------------------------------------------------------------------------------
-- Company: Gruppe 2
-- Engineer: TFE4141
-- 
-- Create Date: 11/02/2022 02:07:55 PM
-- Design Name: 
-- Module Name: subtractor_256b_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;



entity exponentiation_256b_tb is
	generic (
		C_block_size : integer := 256
	);
end exponentiation_256b_tb;


architecture expBehave of exponentiation_256b_tb is

	-- Constants
	constant COUNTER_WIDTH : natural := 8;
	constant CLK_PERIOD    : time := 10 ns;
	constant RESET_TIME    : time := 10 ns;
	
	-- Clocks and resets 
  	signal clk            : std_logic := '0';
  	signal reset_n        : std_logic := '0';

	signal message 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal key 			: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal valid_in 	: STD_LOGIC;
	signal ready_in 	: STD_LOGIC;
	signal ready_out 	: STD_LOGIC;
	signal valid_out 	: STD_LOGIC;
	signal result 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal modulus 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	
	signal restart 		: STD_LOGIC;
	
	signal expected     : std_logic_vector(C_block_size-1 downto 0);

begin
	i_exponentiation : entity work.exponentiation
		generic map (
			C_block_size        => C_block_size
		)
		port map (
			message   => message  ,
			key       => key      ,
			valid_in  => valid_in ,
			ready_in  => ready_in ,
			ready_out => ready_out,
			valid_out => valid_out,
			result    => result   ,
			modulus   => modulus  ,
			clk       => clk      ,
			reset_n   => reset_n
		);

	-- Clock generation
	clk <= not clk after CLK_PERIOD/2;

	-- Reset generation
	reset_proc: process
	begin
		wait for RESET_TIME;
		reset_n <= '1';
		wait;
	end process;
	
	-- Stimuli generation
	stimuli_proc: process
	begin
	   ready_out <= '0';

	  	-- Send in first test vector
		wait for 10*CLK_PERIOD;
		message   <= x"0a23232323232323232323232323232323232323232323232323232323232323";
        key       <= x"0000000000000000000000000000000000000000000000000000000000010001";-- std_logic_vector(to_unsigned( 16#10001#, C_block_size));
        modulus   <= x"666dae8c529a9798eac7a157ff32d7edfd77038f56436722b36f298907008973"; --2s complement of 08e7d3131b900529
        --modulus   <= x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
        expected  <= x"85ee722363960779206a2b37cc8b64b5fc12a934473fa0204bbaaf714bc90c01";
        wait for CLK_PERIOD;
        valid_in  <= '1';
        
        wait until ready_in = '1';
        valid_in <= '0';
        wait until valid_out = '1';
        ready_out <= '1';
        
        assert expected = result
            report "Output message differs from the expected result"
            severity Failure;
        
		wait for CLK_PERIOD;
		ready_out <= '0';
		wait for 50*CLK_PERIOD;
		
		-- expected x"85ee722363960779206a2b37cc8b64b5fc12a934473fa0204bbaaf714bc90c01"
		
		
		assert false report "Test done." severity note;
    	wait;

	end process;  
  
  

end expBehave;
