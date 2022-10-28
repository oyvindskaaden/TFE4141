----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2022 12:45:02
-- Design Name: 
-- Module Name: exponentiation_control - Behavioral
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

entity exponentiation_control is
    port (
        -- Clock and Reset
        clk         : in    std_logic;
        reset_n     : in    std_logic;
        
        --input controll
        valid_in	: in    std_logic;
        ready_in	: out   std_logic;
        
        --ouput controll
        ready_out	: in    std_logic;
        valid_out	: out   std_logic
    );
end exponentiation_control;

architecture Behavioral of exponentiation_control is

begin

end Behavioral;
