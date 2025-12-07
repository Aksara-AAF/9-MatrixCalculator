library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all;

entity multiply_matrix is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        enable  : in std_logic;
        mat_A   : in matrix_5x5;
        mat_B   : in matrix_5x5;
        mat_Res : out matrix_5x5;
        done    : out std_logic
    );
end multiply_matrix;

architecture Behavioral of multiply_matrix is
    signal result_reg : matrix_5x5 := (others => (others => (others => '0')));
begin
    
    process(clk)
        variable sum : signed(31 downto 0); -- Penampung besar
        variable mult_val : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            -- 1. Reset Logic
            if rst = '1' then
                result_reg <= (others => (others => (others => '0')));
                done <= '0';
            
            -- 2. Logic Perkalian
            elsif enable = '1' then
                
                -- Triple Loop (Baris, Kolom, Dot-Product)
                for i in 0 to MAX_SIZE-1 loop
                    for j in 0 to MAX_SIZE-1 loop
                        
                        sum := (others => '0'); 
                        
                        for k in 0 to MAX_SIZE-1 loop
                            -- A[i,k] * B[k,j]
                            mult_val := mat_A(i,k) * mat_B(k,j);
                            sum := sum + resize(mult_val, 32);
                        end loop;
                        
                        -- Saturasi Output
                        if sum > 127 then
                            result_reg(i,j) <= to_signed(127, 8);
                        elsif sum < -128 then
                            result_reg(i,j) <= to_signed(-128, 8);
                        else
                            result_reg(i,j) <= resize(sum, 8);
                        end if;
                        
                    end loop;
                end loop;
                
                done <= '1'; -- Selesai dalam 1 clock
            else
                done <= '0';
            end if;
        end if;
    end process;
    
    mat_Res <= result_reg;

end Behavioral;