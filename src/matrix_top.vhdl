library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all;

entity matrix_processor_top is
    port (
        clk, rst               : in std_logic;
        start                  : in std_logic;
        opcode                 : in std_logic_vector(3 downto 0);
        dim_rows_A, dim_cols_A : in integer;
        dim_rows_B, dim_cols_B : in integer;
        in_mat_A, in_mat_B     : in matrix_5x5;

        out_mat_Res : out matrix_5x5;
        out_det     : out signed(7 downto 0);
        out_error   : out std_logic_vector(3 downto 0);
        out_done    : out std_logic
    );
end matrix_processor_top;

architecture Structural of matrix_processor_top is
    -- Signals Declaration
    signal w_en_alu, w_en_sys, w_sys_rst : std_logic;
    signal w_done_alu, w_done_sys : std_logic;
    signal res_sys, res_alu : matrix_5x5;

    -- Internal signal untuk membaca error dan busy dari CU
    signal int_error : std_logic_vector(3 downto 0);
    signal int_busy : std_logic;

begin
    -- Strucutural (Component Instantiation)
    U_CTRL : entity work.control_unit port map (
        clk => clk, rst => rst, start => start, opcode => opcode,
        rows_A => dim_rows_A, cols_A => dim_cols_A,
        rows_B => dim_rows_B, cols_B => dim_cols_B,
        en_alu => w_en_alu, en_sys => w_en_sys, sys_rst => w_sys_rst,
        error_code => int_error, busy => int_busy,
        done_alu => w_done_alu, done_sys => w_done_sys
        );

    U_ALU : entity work.alu_common port map (
        clk => clk, opcode => opcode, enable => w_en_alu,
        rows => dim_rows_A, cols => dim_cols_A,
        mat_A => in_mat_A, mat_B => in_mat_B,
        mat_Res => res_alu, det_val => out_det, done => w_done_alu
        );

    U_SYS : entity work.systolic_array port map (
        clk => clk, rst => w_sys_rst, enable => w_en_sys,
        mat_A => in_mat_A, mat_B => in_mat_B,
        mat_Res => res_sys, done => w_done_sys
        );

    out_error <= int_error;

    -- Logic Output Matrix: Pilih ALU atau Systolic
    out_mat_Res <= res_sys when opcode = OP_MUL else
        res_alu;

    -- Done jika ALU/Sys selesai, ATAU jika ada Error (dari CU)
    out_done <= '1' when (w_done_alu = '1' or w_done_sys = '1') else
        '1' when (int_busy = '1' and int_error /= "0000") else
        '0';

end Structural;