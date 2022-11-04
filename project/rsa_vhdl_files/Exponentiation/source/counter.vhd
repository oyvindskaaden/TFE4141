-- *****************************************************************************
-- Name:     counter.vhd   
-- Created:  03.02.16 @ NTNU   
-- Author:   Jonas Eggen
-- Purpose:  A simple counter.
-- *****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (
    COUNTER_WIDTH : natural := 8);
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    cnt_en  : in  std_logic;
    y       : out std_logic_vector(COUNTER_WIDTH-1 downto 0));
end counter;

architecture rtl of counter is
  signal value : unsigned(COUNTER_WIDTH-1 downto 0);
begin
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      value <= (others => '0');
    elsif (clk'event and clk='1') then
      if (cnt_en = '1') then
        value <= value + 1;
      end if;
    end if;
  end process;
  y <= std_logic_vector(value);
end rtl;