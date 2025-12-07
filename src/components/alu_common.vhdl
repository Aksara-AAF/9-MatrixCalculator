library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all;

entity alu_common is
    port (
        clk          : in std_logic;
        opcode       : in std_logic_vector(3 downto 0);
        enable       : in std_logic;
        rows         : in integer;
        cols         : in integer;
        mat_A, mat_B : in matrix_5x5;
        mat_Res      : out matrix_5x5;
        det_val      : out signed(DATA_WIDTH - 1 downto 0);
        done         : out std_logic
    );
end alu_common;

architecture Behavioral of alu_common is
    -- Determinan 2x2 (Basic Block)
    -- Rumus: ad - bc
    function get_det2(a, b, c, d : signed) return signed is
        variable res : signed(63 downto 0);
    begin
        res := (resize(a, 32) * resize(d, 32)) - (resize(b, 32) * resize(c, 32));
        return res;
    end function;

    -- Determinan 3x3 
    function get_det3(m : matrix_5x5) return signed is
        variable term1, term2, term3, term4, term5, term6 : signed(63 downto 0);
        variable res : signed(63 downto 0);
    begin
        -- Sarrus: (aei + bfg + cdh) - (ceg + bdi + afh)
        term1 := resize(resize(m(0, 0), 20) * resize(m(1, 1), 20) * resize(m(2, 2), 20), 64);
        term2 := resize(resize(m(0, 1), 20) * resize(m(1, 2), 20) * resize(m(2, 0), 20), 64);
        term3 := resize(resize(m(0, 2), 20) * resize(m(1, 0), 20) * resize(m(2, 1), 20), 64);
        term4 := resize(resize(m(0, 2), 20) * resize(m(1, 1), 20) * resize(m(2, 0), 20), 64);
        term5 := resize(resize(m(0, 1), 20) * resize(m(1, 0), 20) * resize(m(2, 2), 20), 64);
        term6 := resize(resize(m(0, 0), 20) * resize(m(1, 2), 20) * resize(m(2, 1), 20), 64);

        res := term1 + term2 + term3 - term4 - term5 - term6;
        return res;
    end function;

    -- Determinan 4x4 
    function get_det4(m : matrix_5x5) return signed is
        variable sub_m : matrix_5x5;
        variable sum : signed(63 downto 0) := (others => '0');
        variable term : signed(63 downto 0);
        variable r_idx, c_idx : integer;
    begin
        for k in 0 to 3 loop
            -- Buat Sub-Matrix 3x3 
            r_idx := 0;
            for i in 1 to 3 loop
                c_idx := 0;
                for j in 0 to 3 loop
                    if j /= k then
                        sub_m(r_idx, c_idx) := m(i, j);
                        c_idx := c_idx + 1;
                    end if;
                end loop;
                r_idx := r_idx + 1;
            end loop;

            term := resize(resize(m(0, k), 32) * resize(get_det3(sub_m), 32), 64);

            -- Tambah/Kurang 
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

    -- Determinan 5x5 
    function get_det5(m : matrix_5x5) return signed is
        variable sub_m : matrix_5x5;
        variable sum : signed(63 downto 0) := (others => '0');
        variable term : signed(63 downto 0);
        variable r_idx, c_idx : integer;
    begin
        for k in 0 to 4 loop
            -- Buat Sub-Matrix 4x4 
            r_idx := 0;
            for i in 1 to 4 loop
                c_idx := 0;
                for j in 0 to 4 loop
                    if j /= k then
                        sub_m(r_idx, c_idx) := m(i, j);
                        c_idx := c_idx + 1;
                    end if;
                end loop;
                r_idx := r_idx + 1;
            end loop;

            term := resize(resize(m(0, k), 32) * resize(get_det4(sub_m), 32), 64);

            -- Tambah/Kurang 
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

    -- Function helper untuk Inverse, Hitung Kofaktor (Determinan sub-matrix)
    function get_cofactor_val(m : matrix_5x5; r_ex, c_ex : integer; size : integer) return signed is
        variable sub_m : matrix_5x5;
        variable r_i, c_i : integer := 0;
        variable res : signed(63 downto 0);
    begin
        r_i := 0;
        for i in 0 to MAX_SIZE - 1 loop
            if i /= r_ex and i < size then
                c_i := 0;
                for j in 0 to MAX_SIZE - 1 loop
                    if j /= c_ex and j < size then
                        sub_m(r_i, c_i) := m(i, j);
                        c_i := c_i + 1;
                    end if;
                end loop;
                r_i := r_i + 1;
            end if;
        end loop;

        -- Hitung determinan sub-matrix
        if size = 3 then
            res := get_det2(sub_m(0, 0), sub_m(0, 1), sub_m(1, 0), sub_m(1, 1)); -- Sub dari 3x3 adalah 2x2
        elsif size = 4 then
            res := get_det3(sub_m);
        elsif size = 5 then
            res := get_det4(sub_m);
        else
            res := (others => '0');
        end if;

        return res;
    end function;

begin
    process (clk)
        variable temp_calc : signed(16 downto 0);
        variable det_temp : signed(63 downto 0);
        variable cofactor : signed(63 downto 0);
        variable adj_val : signed(63 downto 0);
    begin
        if rising_edge(clk) then
            done <= '0';
            if enable = '1' then
                -- Reset Result
                mat_Res <= (others => (others => (others => '0')));

                case opcode is
                    when OP_ADD =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then -- Boundary check
                                    temp_calc := resize(mat_A(i, j), 17) + resize(mat_B(i, j), 17);
                                    mat_Res(i, j) <= saturate(temp_calc);
                                end if;
                            end loop;
                        end loop;
                        done <= '1';

                    when OP_SUB =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then
                                    temp_calc := resize(mat_A(i, j), 17) - resize(mat_B(i, j), 17);
                                    mat_Res(i, j) <= saturate(temp_calc);
                                end if;
                            end loop;
                        end loop;
                        done <= '1';

                    when OP_TRANSPOSE =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then -- Asumsi matrix persegi/sesuai
                                    mat_Res(j, i) <= mat_A(i, j);
                                end if;
                            end loop;
                        end loop;
                        done <= '1';

                    when OP_DET =>
                        if rows = 2 then
                            det_temp := get_det2(mat_A(0, 0), mat_A(0, 1), mat_A(1, 0), mat_A(1, 1));
                        elsif rows = 3 then
                            det_temp := get_det3(mat_A);
                        elsif rows = 4 then
                            det_temp := get_det4(mat_A);
                        elsif rows = 5 then
                            det_temp := get_det5(mat_A);
                        else
                            det_temp := (others => '0');
                        end if;

                        det_val <= saturate(det_temp);
                        done <= '1';

                    when OP_INVERSE =>
                        -- Hitung Determinan
                        if rows = 2 then
                            det_temp := get_det2(mat_A(0, 0), mat_A(0, 1), mat_A(1, 0), mat_A(1, 1));
                        elsif rows = 3 then
                            det_temp := get_det3(mat_A);
                        else
                            det_temp := (others => '0');
                        end if; -- Inverse dibatasi max 3x3

                        -- Cek Singularitas (Det = 0)
                        if det_temp = 0 then
                            -- Error : tidak bisa inverse, return 0
                            mat_Res <= (others => (others => (others => '0')));
                        else
                            -- Hitung Adjugate & Bagi Determinan
                            for i in 0 to 2 loop -- Loop Rows (limit 3)
                                if i < rows then
                                    for j in 0 to 2 loop -- Loop Cols (limit 3)
                                        if j < rows then
                                            -- Hitung Kofaktor C(i,j)
                                            cofactor := get_cofactor_val(mat_A, i, j, rows);

                                            -- Tentukan Tanda (-1)^(i+j)
                                            if ((i + j) mod 2) = 1 then
                                                cofactor := - cofactor;
                                            end if;

                                            -- Adjugate = Transpose Kofaktor = Adj(j,i) = C(i,j)
                                            -- Bagi dengan Determinan
                                            adj_val := cofactor / det_temp;

                                            mat_Res(j, i) <= saturate(resize(adj_val, 8));
                                        end if;
                                    end loop;
                                end if;
                            end loop;
                        end if;
                        done <= '1';

                    when others => null;
                end case;
            end if;
        end if;
    end process;
end Behavioral;