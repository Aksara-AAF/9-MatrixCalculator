library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.matrix_pkg.all;

entity alu_common is
    Port ( 
        clk : in STD_LOGIC;
        opcode : in STD_LOGIC_VECTOR(3 downto 0);
        enable : in STD_LOGIC;
        rows : in INTEGER; 
        mat_A, mat_B : in matrix_5x5;
        mat_Res : out matrix_5x5;
        det_val : out signed(DATA_WIDTH-1 downto 0);
        done : out STD_LOGIC
    );
end alu_common;

architecture Behavioral of alu_common is
    -- Level 1: Determinan 2x2 (Basic Block)
    -- Rumus: ad - bc
    function get_det2(a, b, c, d : signed) return signed is
        variable res : signed(31 downto 0);
    begin
        res := (resize(a, 32) * resize(d, 32)) - (resize(b, 32) * resize(c, 32));
        return resize(res, 64); 
    end function;

    -- Level 2: Determinan 3x3 
    function get_det3(m : matrix_5x5) return signed is
        variable term1, term2, term3, term4, term5, term6 : signed(47 downto 0);
        variable res : signed(63 downto 0);
    begin
        -- Sarrus: (aei + bfg + cdh) - (ceg + bdi + afh)
        term1 := resize(m(0,0),48) * resize(m(1,1),48) * resize(m(2,2),48);
        term2 := resize(m(0,1),48) * resize(m(1,2),48) * resize(m(2,0),48);
        term3 := resize(m(0,2),48) * resize(m(1,0),48) * resize(m(2,1),48);
        
        term4 := resize(m(0,2),48) * resize(m(1,1),48) * resize(m(2,0),48);
        term5 := resize(m(0,1),48) * resize(m(1,0),48) * resize(m(2,2),48);
        term6 := resize(m(0,0),48) * resize(m(1,2),48) * resize(m(2,1),48);
        
        res := resize(term1 + term2 + term3 - term4 - term5 - term6, 64);
        return res;
    end function;

    -- Level 3: Determinan 4x4 
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
       
            term := resize(m(0,k), 64) * get_det3(sub_m);

            -- Tambah/Kurang 
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

    -- Level 4: Determinan 5x5 
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

            term := resize(m(0,k), 64) * get_det4(sub_m);

            -- Tambah/Kurang 
            if (k rem 2) = 0 then
                sum := sum + term;
            else
                sum := sum - term;
            end if;
        end loop;
        return sum;
    end function;

begin
    process(clk)
        variable temp_calc : signed(16 downto 0);
        variable det_temp : signed(63 downto 0); 
    begin
        if rising_edge(clk) then
            done <= '0';
            if enable = '1' then
                case opcode is
                    when OP_ADD =>
                        for i in 0 to MAX_SIZE-1 loop
                            for j in 0 to MAX_SIZE-1 loop
                                temp_calc := resize(mat_A(i,j),17) + resize(mat_B(i,j),17);
                                mat_Res(i,j) <= saturate(temp_calc);
                            end loop;
                        end loop;
                        done <= '1';

                    when OP_SUB =>
                        for i in 0 to MAX_SIZE-1 loop
                            for j in 0 to MAX_SIZE-1 loop
                                temp_calc := resize(mat_A(i,j),17) - resize(mat_B(i,j),17);
                                mat_Res(i,j) <= saturate(temp_calc);
                            end loop;
                        end loop;
                        done <= '1';
                    
                    when OP_TRANSPOSE =>
                        for i in 0 to MAX_SIZE-1 loop
                            for j in 0 to MAX_SIZE-1 loop
                                mat_Res(j,i) <= mat_A(i,j);
                            end loop;
                        end loop;
                        done <= '1';
                        
                    when OP_DET =>
                        if rows = 2 then
                            det_temp := get_det2(mat_A(0,0), mat_A(0,1), mat_A(1,0), mat_A(1,1));
                        elsif rows = 3 then
                            det_temp := get_det3(mat_A);
                        elsif rows = 4 then
                            det_temp := get_det4(mat_A);
                        elsif rows = 5 then
                            det_temp := get_det5(mat_A); 
                        else
                            det_temp := (others => '0');
                        end if;
                        
                        det_val <= saturate(resize(det_temp, 8)); 
                        done <= '1';
                        
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end Behavioral;