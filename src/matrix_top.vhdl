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
    -- Signal nama tetap 'sys' (system/systolic) tidak masalah, atau mau diubah jadi 'mul' juga boleh
    -- Di sini saya biarkan w_en_sys agar tidak perlu ubah Control Unit.
    signal w_en_alu, w_en_sys, w_sys_rst : std_logic := '0';
    signal w_done_alu, w_done_sys : std_logic := '0';
    
    signal res_mul : matrix_5x5 := (others => (others => (others => '0'))); -- Ganti nama signal biar rapi
    signal res_alu : matrix_5x5 := (others => (others => (others => '0')));

    signal int_error : std_logic_vector(3 downto 0) := "0000";
    signal int_busy : std_logic := '0';

begin
    -- 1. CONTROL UNIT
    U_CTRL : entity work.control_unit port map (
        clk => clk, rst => rst, start => start, opcode => opcode,
        rows_A => dim_rows_A, cols_A => dim_cols_A,
        rows_B => dim_rows_B, cols_B => dim_cols_B,
        en_alu => w_en_alu, en_sys => w_en_sys, sys_rst => w_sys_rst,
        error_code => int_error, busy => int_busy,
        done_alu => w_done_alu, done_sys => w_done_sys
    );

    -- 2. ALU COMMON
    U_ALU : entity work.alu_common port map (
        clk => clk, opcode => opcode, enable => w_en_alu,
        rows => dim_rows_A, cols => dim_cols_A,
        mat_A => in_mat_A, mat_B => in_mat_B,
        mat_Res => res_alu, det_val => out_det, done => w_done_alu
    );

    -- 3. MULTIPLY MATRIX (Komponen Baru)
    -- Kita hubungkan sinyal kontrol 'sys' ke modul ini
    U_MUL : entity work.multiply_matrix port map (
        clk     => clk, 
        rst     => w_sys_rst, 
        enable  => w_en_sys,
        mat_A   => in_mat_A, 
        mat_B   => in_mat_B,
        mat_Res => res_mul, 
        done    => w_done_sys
    );

    out_error <= int_error;
    
    -- Mux Output (Pilih hasil Multiplier atau ALU)
    out_mat_Res <= res_mul when opcode = OP_MUL else res_alu;
    
    -- Done Logic
    out_done <= '1' when (w_done_alu = '1' or w_done_sys = '1') else
                '1' when (int_busy = '1' and int_error /= "0000") else 
                '0';

end Structural;