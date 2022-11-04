-- *****************************************************************************
-- Name:     counter_tb.vhd   
-- Created:  03.02.16 @ NTNU   
-- Author:   Jonas Eggen
-- Purpose:  Testbench for a simple counter.
-- *****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
end counter_tb;

architecture tb of counter_tb is  
  -- Constants
  constant COUNTER_WIDTH : natural := 8;
  constant CLK_PERIOD    : time := 10 ns;
  constant RESET_TIME    : time := 10 ns;

  -- Inputs
  signal clk             : std_logic := '0';
  signal reset_n         : std_logic := '0';
  signal cnt_en          : std_logic := '1';

  -- Outputs
  signal y               : std_logic_vector(COUNTER_WIDTH-1 downto 0);

begin
  -- DUT instantiation
  dut: entity work.counter 
    generic map (
      COUNTER_WIDTH => COUNTER_WIDTH)
    port map (
      clk           => clk,
      reset_n       => reset_n,
      cnt_en        => cnt_en,
      y             => y);

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
    wait for 10*CLK_PERIOD;
    cnt_en <= '0';
    wait for 2*CLK_PERIOD;
    cnt_en <= '1';
    wait;
  end process;

end tb;