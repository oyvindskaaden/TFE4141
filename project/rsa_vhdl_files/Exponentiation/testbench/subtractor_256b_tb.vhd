----------------------------------------------------------------------------------
-- Company: 
-- Engineer: T0rje
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
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity subtractor_256b_tb is
--  Port ( );
	generic (
		C_block_size : integer := 256
	);
end subtractor_256b_tb;

architecture Behavioral of subtractor_256b_tb is
	signal A, B_2s, result: std_logic_vector(255 downto 0);
    signal borrow,borrow2 : std_logic;
begin
	DUT: entity work.subtractor_256b
		generic map (
			C_block_size        => C_block_size
		)
    	port map(
			A => A, 
			B_2s => B_2s, 
			result => result, 
			borrow => borrow
		);
        
stimulus: process is
	begin
    	wait for 10 ns ;
    	A <= x"7" ; B_2s <= x"1" ; --7-F = -8(8)
		wait for 10 ns ;
    	A <= x"8" ; B_2s <= x"2" ; --8-E=-6(a)
		wait for 10 ns ;
    	A <= x"2" ; B_2s <= x"3" ; --2-D=-B(5)
		wait for 10 ns ;
    	A <= x"8" ; B_2s <= x"E" ; --8-2=+6(6)
		wait for 10 ns ;
    	A <= x"B" ; B_2s <= x"7" ; --B -9=+2(2)
    	wait for 10 ns ;
    	A <= x"F" ; B_2s <= x"2" ; --F -E= +1
    	wait for 10 ns ;
    	A <= x"E" ; B_2s <= x"1" ; --E -F= -1(F)
    	wait for 10 ns ;
    	A <= x"F" ; B_2s <= x"F" ; --F -1= +E(E)
    	wait for 10 ns ;
    	A <= x"1" ; B_2s <= x"1" ; --1 -F= -E(2)
        
        assert false report "Test done." severity note;
    	wait;
	end process stimulus;


end Behavioral;


