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
--use IEEE.STD_LOGIC_SIGNED.ALL;

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
        clk         : in std_logic;
        reset_n     : in std_logic;
        
        -- Data inn
        A_in        : in std_logic_vector(C_block_size-1 downto 0);
        B_in        : in std_logic_vector(C_block_size-1 downto 0);
        N_in        : in std_logic_vector(C_block_size-1 downto 0);

        -- Data out
        M_out       : out std_logic_vector(C_block_size-1 downto 0);

        -- Register load signals
        A_reg_load  : in std_logic;
        B_reg_load  : in std_logic;
        M_reg_load  : in std_logic;

        -- Source selction for the B register
        B_reg_sel   : in std_logic;

        -- Borrow signals
        borrow_1n   : out std_logic;
        borrow_2n   : out std_logic;

        -- Selection of correct calculation result
        mod_sel     : in std_logic_vector(1 downto 0)
     );

end multi_mod_datapath;

architecture Behavioral of multi_mod_datapath is
    signal A_r, A_mux   : std_logic_vector(C_block_size-1 downto 0);
    signal B_r          : std_logic_vector(C_block_size-1 downto 0);
    -- signal N_r : std_logic_vector(C_block_size-1 downto 0);
    signal M_r          : std_logic_vector(C_block_size-1 downto 0);

    --signal a_reg_sel : std_logic;

    -- Partial sum is 257 bits, to accommodate adding 2 256 bit numbers
    signal partial_sum      : std_logic_vector(C_block_size downto 0);

    -- The output from subtractors cant be larger than 256 
    -- bits, trunkate result
    signal partial_mod_1n   : std_logic_vector(C_block_size-1 downto 0);
    signal partial_mod_2n   : std_logic_vector(C_block_size-1 downto 0);
    signal M_mux_out        : std_logic_vector(C_block_size-1 downto 0);

    
begin
    
    -- Connect output to M reg
    M_out <= M_r;

    --A Register
    process(clk, reset_n) begin
        if(reset_n = '0') then
            A_r <= (others => '0');
        elsif(clk'event and clk='1') then
            if(A_reg_load='1') then
                A_r <= A_in;
            else
                A_r <= A_r;
            end if;
        end if;
    end process;

    --B Register
    process(clk, reset_n, B_reg_load) begin
        if(reset_n = '0') then
            B_r <= (others => '0');
        elsif(clk'event and clk='1' and B_reg_load='1') then
            if(B_reg_sel='1') then
                B_r <= B_r(C_block_size-2 downto 0) & '0';
            else
                B_r <= B_in;
            end if;
        end if;
    end process;
    
    --M Register
    process(clk, reset_n) begin
        if(reset_n = '0') then
            M_r <= (others => '0');
        elsif(clk'event and clk='1') then
            if(M_reg_load='1') then
                M_r <= M_mux_out;
            else
                M_r <= M_r;
            end if;
        end if;
    end process;


    --Adders etc
    process(A_r, B_r) begin
        if(B_r(C_block_size-1) = '1') then
            A_mux <= A_r;
        else
            A_mux <= (others =>'0'); 
        end if;
    end process;
    
    -- First adder, 257 bits
    process(A_mux, M_r) begin
        partial_sum <= std_logic_vector(unsigned(M_r(C_block_size-1 downto 0) & '0') + unsigned('0' & A_mux));
    end process;
    
    
    -- Subtractors
    -- Sub1 subtracts 1 n from partial result, borrow is 1 if result is negative
    -- The subtractor is 258 bits wide
    sub1 : entity work.subtractor_256b
        generic map (
            C_block_size        => C_block_size
        )
        port map(
            A       => partial_sum , 
            B_2s    => ('1' & N_in) , 
            result  => partial_mod_1n , 
            borrow  =>borrow_1n
        );

    -- Sub1 subtracts 2 n from partial result, borrow is 1 if result is negative
    -- The subtractor is 258 bits wide
    sub2 : entity work.subtractor_256b
        generic map (
            C_block_size    => C_block_size
        )
        port map(
            A               => partial_sum , 
            B_2s            => (N_in & '0') , 
            result          => partial_mod_2n , 
            borrow          =>borrow_2n 
        );
  
    -- MUX given mod_sel
    -- The mapping for this is done in control. 
    -- Based on the borrow signals
    process(mod_sel, partial_sum, partial_mod_1n, partial_mod_2n) begin
        case mod_sel is
            when b"00" =>   -- Result is 0 <= result < n
                M_mux_out <= partial_sum(C_block_size-1 downto 0);
            when b"01" =>   -- Result is n <= result < 2n
                M_mux_out <= partial_mod_1n(C_block_size-1 downto 0);
            when b"10" =>   -- Result is 2n <= result < 3n - 3
                M_mux_out <= partial_mod_2n(C_block_size-1 downto 0);
            when others =>  -- Illegal result
                M_mux_out <= (others => '0');
        end case;
    end process;

  


end Behavioral;

