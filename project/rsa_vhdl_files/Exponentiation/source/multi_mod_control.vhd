----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/18/2022 11:26:16 AM
-- Design Name: 
-- Module Name: multi_mod_control - Behavioral
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

entity multi_mod_control is
    Port (


        -- Datapath control logic
        A_reg_load  : out std_logic;
        B_reg_load  : out std_logic;
        M_reg_load  : out std_logic;
        n_reg_load  : out std_logic;

        B_reg_sel   : out std_logic;

        mod_sel     : out std_logic_vector(1 downto 0);

        -- Borrow signals
        borrow_1n   : in std_logic;
        borrow_2n   : in std_logic;

        -- Reset and Clock
        reset_n     : in std_logic;
        clk         : in std_logic;
    );
end multi_mod_control;

architecture Behavioral of multi_mod_control is

begin


end Behavioral;
