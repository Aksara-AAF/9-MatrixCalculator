library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use std.textio.all;
use work.matrix_pkg.all;

entity tb_matrix_processor is
end tb_matrix_processor;

architecture sim of tb_matrix_processor is
    signal clk, rst, start : std_logic := '0';
    signal opcode : std_logic_vector(3 downto 0) := (others => '0');
    signal dim_rows_A, dim_cols_A : integer := 0;
    signal dim_rows_B, dim_cols_B : integer := 0;
    signal in_mat_A, in_mat_B : matrix_5x5 := (others => (others => (others => '0')));

    signal out_mat_Res : matrix_5x5;
    signal out_det : signed(7 downto 0);
    signal out_error : std_logic_vector(3 downto 0);
    signal out_done : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    DUT : entity work.matrix_processor_top
        port map(
            clk         => clk,
            rst         => rst,
            start       => start,
            opcode      => opcode,
            dim_rows_A  => dim_rows_A,
            dim_cols_A  => dim_cols_A,
            dim_rows_B  => dim_rows_B,
            dim_cols_B  => dim_cols_B,
            in_mat_A    => in_mat_A,
            in_mat_B    => in_mat_B,
            out_mat_Res => out_mat_Res,
            out_det     => out_det,
            out_error   => out_error,
            out_done    => out_done
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    process
        file f_in : text open read_mode is "C:\Users\LENOVO\Downloads\Finpro PSD\tb\input.txt";
        file f_out : text open write_mode is "C:\Users\LENOVO\Downloads\Finpro PSD\tb\output.txt";
        variable L_in, L_out : line;
        variable v_op_str : string(1 to 4);
        variable v_val : integer;
        variable v_rA, v_cA, v_rB, v_cB : integer;
        variable limit_r, limit_c : integer;
        variable v_captured_error : std_logic_vector(3 downto 0);
    begin
        -- Reset Sequence
        rst <= '1';
        start <= '0';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        while not endfile(f_in) loop
            -- Baca Opcode
            readline(f_in, L_in);
            read(L_in, v_op_str);
            for i in 1 to 4 loop
                if v_op_str(i) = '1' then
                    opcode(4 - i) <= '1';
                else
                    opcode(4 - i) <= '0';
                end if;
            end loop;

            -- Baca Dimensi A
            readline(f_in, L_in);
            read(L_in, v_rA);
            read(L_in, v_cA);
            dim_rows_A <= v_rA;
            dim_cols_A <= v_cA;

            -- Baca Matriks A
            in_mat_A <= (others => (others => (others => '0')));
            for i in 0 to v_rA - 1 loop
                readline(f_in, L_in);
                for j in 0 to v_cA - 1 loop
                    read(L_in, v_val);
                    in_mat_A(i, j) <= to_signed(v_val, 8);
                end loop;
            end loop;

            -- Baca Dimensi B
            readline(f_in, L_in);
            read(L_in, v_rB);
            read(L_in, v_cB);
            dim_rows_B <= v_rB;
            dim_cols_B <= v_cB;

            -- Baca Matriks B
            in_mat_B <= (others => (others => (others => '0')));
            for i in 0 to v_rB - 1 loop
                readline(f_in, L_in);
                for j in 0 to v_cB - 1 loop
                    read(L_in, v_val);
                    in_mat_B(i, j) <= to_signed(v_val, 8);
                end loop;
            end loop;

            -- Tunggu stable
            wait for CLK_PERIOD;
            
            -- Debug print (optional - untuk console)
            report "Test: opcode=" & v_op_str & 
                   " A=" & integer'image(v_rA) & "x" & integer'image(v_cA) & 
                   " B=" & integer'image(v_rB) & "x" & integer'image(v_cB);
            
            -- Execute - HOLD start HIGH sampai done
            wait until rising_edge(clk);
            start <= '1';
            
            -- Tunggu sampai done (start tetap HIGH!)
            wait until out_done = '1' for 100 us; -- Timeout protection
            
            if out_done /= '1' then
                report "TIMEOUT: Operation did not complete!" severity warning;
            end if;
            
            -- Tambah delay untuk capture hasil yang stabil
            wait for CLK_PERIOD * 2;

            -- Capture error saat done aktif
            v_captured_error := out_error;

            -- Print Output
            write(L_out, string'("Opcode: "));
            write(L_out, v_op_str);
            writeline(f_out, L_out);

            if v_captured_error /= "0000" then
                write(L_out, string'("ERROR CODE: "));
                case v_captured_error is
                    when "0001" => write(L_out, string'("Dimension Mismatch"));
                    when others => write(L_out, string'("Unknown Error"));
                end case;
                writeline(f_out, L_out);
            elsif opcode = OP_DET then
                write(L_out, string'("Determinant: "));
                write(L_out, integer'image(to_integer(out_det)));
                writeline(f_out, L_out);
            else
                write(L_out, string'("Result Matrix:"));
                writeline(f_out, L_out);

                -- Tentukan ukuran output
                if opcode = OP_TRANSPOSE then
                    limit_r := v_cA;
                    limit_c := v_rA;
                elsif opcode = OP_MUL then
                    limit_r := v_rA;
                    limit_c := v_cB;
                else
                    limit_r := v_rA;
                    limit_c := v_cA;
                end if;

                -- Print matrix
                for i in 0 to limit_r - 1 loop
                    for j in 0 to limit_c - 1 loop
                        write(L_out, integer'image(to_integer(out_mat_Res(i, j))));
                        if j < limit_c - 1 then
                            write(L_out, string'(" "));
                        end if;
                    end loop;
                    writeline(f_out, L_out);
                end loop;
            end if;

            write(L_out, string'("--------------------------------"));
            writeline(f_out, L_out);

            -- Reset start dan tunggu done turun
            start <= '0';
            wait until out_done = '0';
            wait for CLK_PERIOD * 3;

        end loop;

        file_close(f_in);
        file_close(f_out);
        
        report "Simulation Complete!" severity note;
        wait;
    end process;

end sim;