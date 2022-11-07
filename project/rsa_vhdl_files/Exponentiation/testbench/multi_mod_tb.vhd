----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2022 12:29:51 PM
-- Design Name: 
-- Module Name: multi_mod_tb - Behavioral
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

entity multi_mod_tb is
--  Port ( );
    Generic (
		C_block_size : integer := 64
    );
end multi_mod_tb;

architecture Behavioral of multi_mod_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant RESET_TIME : time := 10 ns;

    signal clk                 : std_logic := '0';
    signal reset_n             : std_logic := '0';
     
    signal A_in                : std_logic_vector(C_block_size-1 downto 0);
    signal B_in                : std_logic_vector(C_block_size-1 downto 0);
    signal N_in                : std_logic_vector(C_block_size-1 downto 0);
     
    signal M_out               : std_logic_vector(C_block_size-1 downto 0);
     
     -- MultiMod (mm) data signals
    signal mm_data_in_ready    : std_logic := '0';
    signal mm_data_out_ready   : std_logic;
    
begin
    clk <= not clk after CLK_PERIOD/2;
    
    resec_proc: process
    begin
        wait for RESET_TIME;
        reset_n <= '1';
        wait;
    end process;
    
    DUT : entity work.multi_mod
        port map(  
            clk                 => clk,
            reset_n             => reset_n,
                                
            -- Data in connection
            A_in        => A_in,
			B_in        => B_in,
			N_in        => N_in,

            -- Data out connection
			M_out       => M_out,
                        
            
            -- Data readiness
            mm_data_in_ready    => mm_data_in_ready,
            mm_data_out_ready   => mm_data_out_ready
            
        );
        
    stimulus: process is
	begin

	    wait for 10*CLK_PERIOD;

	   
    	--TESTS
    	A_in <= std_logic_vector(to_unsigned( 16#13#, C_block_size));
    	B_in <= std_logic_vector(to_unsigned( 16#10#, C_block_size));
    	N_in <= x"FFFFFFFFFFFFFF89"; --std_logic_vector(to_unsigned( 16#FFFFFFFFFFFFFF89#, C_block_size)); 
    	mm_data_in_ready <= '1';
    	
    	--OUT = 42
    	wait for 70*CLK_PERIOD;
    	--MORE TESTS
        
        assert false report "Test done." severity note;
    	wait;
	end process stimulus;
	
	



end Behavioral;       
