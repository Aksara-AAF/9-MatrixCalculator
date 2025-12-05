library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.matrix_pkg.all;

entity tb_matrix_processor is
end tb_matrix_processor;

architecture sim of tb_matrix_processor is

    signal clk, rst, start        : std_logic := '0';
    signal opcode                 : std_logic_vector(3 downto 0) := (others => '0');
    signal dim_rows_A, dim_cols_A : integer := 5;
    signal dim_rows_B, dim_cols_B : integer := 5;

    signal in_mat_A, in_mat_B : matrix_5x5 := (others => (others => (others => '0')));

    signal out_mat_Res : matrix_5x5;
    signal out_det     : signed(7 downto 0);
    signal out_error   : std_logic_vector(3 downto 0);
    signal out_done    : std_logic;

    -- file IO
    file f_in  : text open read_mode is "input_matrix.txt";
    file f_out : text open write_mode is "output_result.txt";

begin
    -- DUT Instance
    DUT: entity work.matrix_processor_top
        port map (
            clk => clk, rst => rst, start => start,
            opcode => opcode,
            dim_rows_A => dim_rows_A, dim_cols_A => dim_cols_A,
            dim_rows_B => dim_rows_B, dim_cols_B => dim_cols_B,
            in_mat_A => in_mat_A, in_mat_B => in_mat_B,
            out_mat_Res => out_mat_Res,
            out_det => out_det,
            out_error => out_error,
            out_done => out_done
        );

    -- CLOCK
    clk_process : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    -- TEST PROCESS
    stim : process
        variable L : line;
        variable val : integer;
    begin
        rst <= '1'; wait for 20 ns;
        rst <= '0'; wait for 20 ns;

        -- load matrix A from file
        for i in 0 to 4 loop
            for j in 0 to 4 loop
                readline(f_in, L);
                read(L, val);
                in_mat_A(i,j) <= to_signed(val,8);
            end loop;
        end loop;

        -- load matrix B
        for i in 0 to 4 loop
            for j in 0 to 4 loop
                readline(f_in, L);
                read(L, val);
                in_mat_B(i,j) <= to_signed(val,8);
            end loop;
        end loop;

        opcode <= "0001"; -- contoh ADD
        start <= '1';
        wait for 10 ns;
        start <= '0';

        wait until out_done = '1';

        -- write output
        for i in 0 to 4 loop
            for j in 0 to 4 loop
                write(L, to_integer(out_mat_Res(i,j)));
                writeline(f_out, L);
            end loop;
        end loop;

        wait;
    end process;

end sim;
