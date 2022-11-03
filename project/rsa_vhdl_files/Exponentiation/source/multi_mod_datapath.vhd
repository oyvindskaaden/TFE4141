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
use IEEE.STD_LOGIC_SIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multi_mod_datapath is
	generic (
		C_block_size : integer := 256
	);
    port (
        -- Clock and reset
        reset_n     : in std_logic;
        clk         : in std_logic;
        
        mm_reset_n  : in std_logic;
    
        A_in        : in std_logic_vector(C_block_size-1 downto 0);
        B_in        : in std_logic_vector(C_block_size-1 downto 0);
        N_in        : in std_logic_vector(C_block_size-1 downto 0);

        M_out       : out std_logic_vector(C_block_size-1 downto 0);

        A_reg_load  : in std_logic;
        B_reg_load  : in std_logic;
        M_reg_load  : in std_logic;
        N_reg_load  : in std_logic;

        B_reg_sel   : in std_logic;

        borrow_1n   : out std_logic;
        borrow_2n   : out std_logic;

        mod_sel     : in std_logic_vector(1 downto 0)
     );

end multi_mod_datapath;

architecture Behavioral of multi_mod_datapath is
    signal A_r, A_mux : std_logic_vector(C_block_size-1 downto 0);
    signal B_r : std_logic_vector(C_block_size-1 downto 0);
    signal N_r : std_logic_vector(C_block_size-1 downto 0);
    signal M_r : std_logic_vector(C_block_size-1 downto 0);
    
    signal B_msb            : std_logic;

    signal a_reg_sel : std_logic;

    signal partial_sum      : std_logic_vector(C_block_size-1 downto 0);
    signal partial_mod_1n   : std_logic_vector(C_block_size-1 downto 0);
    signal partial_mod_2n   : std_logic_vector(C_block_size-1 downto 0);
    
begin
    
    B_msb <= B_r(255);

    --A Register
    process(clk, reset_n, A_in) begin
        if(reset_n = '0') then
            A_r <= (others => '0');
        elsif(clk'event and clk='1') then
            if(A_reg_load='1') then
                A_r <= A_in;
            end if;
        end if;
    end process;

    --B Register
    process(clk, reset_n, B_in) begin
        if(reset_n = '0') then
            A_r <= (others => '0');
        elsif(clk'event and clk='1' and B_reg_load='1') then
            if(B_reg_sel='0') then
                B_r <= B_in;
            elsif(B_reg_sel='1') then
                B_r <= B_r(254 downto 0) & '0';
            end if;
        end if;
    end process;

    --N Register
    process(clk, reset_n, N_in) begin
        if(reset_n = '0') then
            N_r <= (others => '0');
        elsif(clk'event and clk='1') then
            if(N_reg_load='1') then
                N_r <= N_in;
            end if;
        end if;
    end process;
    
    --M Register
    process(clk, reset_n) begin
        if(reset_n = '0') then
            M_r <= (others => '0');
        elsif(clk'event and clk='1') then
            if(M_reg_load='1') then
                M_r <= M_out;
            end if;
        end if;


    end process;



    --Adders etc
    process(M_r, A_r, B_r(255),N_r, mod_sel) begin
        if(B_r(255)) then
            A_mux <= A_r;
        else
            A_mux <= (others =>'0'); 
        end if;
        
        partial_sum <= (M_r(254 downto 0) & '0') + A_mux;

    end process;
    
    
-- Subtractors
    
--partial_mod_1n <= partial_sum - N_r;
--partial_mod_2n <= partial_sum - (N_r(254 downto 0) & '0');
    
    sub1 : entity work.subtractor_256b
        port map(
            A => partial_sum , 
            B_2s => N_r , 
            result => partial_mod_1n , 
            borrow =>borrow_1n );

    sub2 : entity work.subtractor_256b
        port map(
            A => partial_sum , 
            B_2s => (N_r(254 downto 0) & '0') , 
            result => partial_mod_2n , 
            borrow =>borrow_2n );
  
    -- MUX given mod_sel
    process(mod_sel) begin
        case mod_sel is
            when b"00" =>
                M_out <= partial_sum;
            when b"01" =>
                M_out <= partial_mod_1n;
            when b"10" =>
                M_out <= partial_mod_2n;
            when b"11" =>
                M_out <= (others => '0');
        end case;
        

    end process;

  


end Behavioral;

