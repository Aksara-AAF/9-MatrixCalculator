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
    -- Internal register untuk hasil
    signal mat_Res_reg : matrix_5x5 := (others => (others => (others => '0')));
    signal det_val_reg : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal done_reg : std_logic := '0';

    -- Determinan Functions
    function get_det2(a, b, c, d : signed) return signed is
        variable res : signed(63 downto 0);
    begin
        res := (resize(a, 32) * resize(d, 32)) - (resize(b, 32) * resize(c, 32));
        return res;
    end function;

    function get_det3(m : matrix_5x5) return signed is
        variable term1, term2, term3, term4, term5, term6 : signed(63 downto 0);
        variable res : signed(63 downto 0);
    begin
        term1 := resize(resize(m(0, 0), 20) * resize(m(1, 1), 20) * resize(m(2, 2), 20), 64);
        term2 := resize(resize(m(0, 1), 20) * resize(m(1, 2), 20) * resize(m(2, 0), 20), 64);
        term3 := resize(resize(m(0, 2), 20) * resize(m(1, 0), 20) * resize(m(2, 1), 20), 64);
        term4 := resize(resize(m(0, 2), 20) * resize(m(1, 1), 20) * resize(m(2, 0), 20), 64);
        term5 := resize(resize(m(0, 1), 20) * resize(m(1, 0), 20) * resize(m(2, 2), 20), 64);
        term6 := resize(resize(m(0, 0), 20) * resize(m(1, 2), 20) * resize(m(2, 1), 20), 64);
        res := term1 + term2 + term3 - term4 - term5 - term6;
        return res;
    end function;

    function get_det4(m : matrix_5x5) return signed is
        variable sub_m : matrix_5x5;
        variable sum : signed(63 downto 0) := (others => '0');
        variable term : signed(63 downto 0);
        variable r_idx, c_idx : integer;
    begin
        for k in 0 to 3 loop
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
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

    function get_det5(m : matrix_5x5) return signed is
        variable sub_m : matrix_5x5;
        variable sum : signed(63 downto 0) := (others => '0');
        variable term : signed(63 downto 0);
        variable r_idx, c_idx : integer;
    begin
        for k in 0 to 4 loop
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
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

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

        if size = 3 then
            res := get_det2(sub_m(0, 0), sub_m(0, 1), sub_m(1, 0), sub_m(1, 1));
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
    -- Output assignment
    mat_Res <= mat_Res_reg;
    det_val <= det_val_reg;
    done <= done_reg;

    process (clk)
        variable temp_calc : signed(16 downto 0);
        variable det_temp : signed(63 downto 0);
        variable cofactor : signed(63 downto 0);
        variable adj_val : signed(63 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            
            if enable = '1' then
                -- Reset Result terlebih dahulu
                mat_Res_reg <= (others => (others => (others => '0')));

                case opcode is
                    when OP_ADD =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then
                                    temp_calc := resize(mat_A(i, j), 17) + resize(mat_B(i, j), 17);
                                    mat_Res_reg(i, j) <= saturate(temp_calc);
                                end if;
                            end loop;
                        end loop;
                        done_reg <= '1';

                    when OP_SUB =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then
                                    temp_calc := resize(mat_A(i, j), 17) - resize(mat_B(i, j), 17);
                                    mat_Res_reg(i, j) <= saturate(temp_calc);
                                end if;
                            end loop;
                        end loop;
                        done_reg <= '1';

                    when OP_TRANSPOSE =>
                        for i in 0 to MAX_SIZE - 1 loop
                            for j in 0 to MAX_SIZE - 1 loop
                                if i < rows and j < cols then
                                    mat_Res_reg(j, i) <= mat_A(i, j);
                                end if;
                            end loop;
                        end loop;
                        done_reg <= '1';

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
                        det_val_reg <= saturate(det_temp);
                        done_reg <= '1';

                    when OP_INVERSE =>
                        if rows = 2 then
                            det_temp := get_det2(mat_A(0, 0), mat_A(0, 1), mat_A(1, 0), mat_A(1, 1));
                        elsif rows = 3 then
                            det_temp := get_det3(mat_A);
                        else
                            det_temp := (others => '0');
                        end if;

                        if det_temp = 0 then
                            mat_Res_reg <= (others => (others => (others => '0')));
                        else
                            for i in 0 to 2 loop
                                if i < rows then
                                    for j in 0 to 2 loop
                                        if j < rows then
                                            cofactor := get_cofactor_val(mat_A, i, j, rows);
                                            if ((i + j) mod 2) = 1 then
                                                cofactor := - cofactor;
                                            end if;
                                            adj_val := cofactor / det_temp;
                                            mat_Res_reg(j, i) <= saturate(resize(adj_val, 8));
                                        end if;
                                    end loop;
                                end if;
                            end loop;
                        end if;
                        done_reg <= '1';

                    when others => 
                        done_reg <= '0';
                end case;
            end if;
        end if;
    end process;
end Behavioral;