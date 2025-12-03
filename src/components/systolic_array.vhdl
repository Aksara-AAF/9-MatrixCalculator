library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.matrix_pkg.all;

entity systolic_array is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        enable : in STD_LOGIC; -- Sinyal Start dari Control Unit
        
        -- Input Matriks Utuh (5x5)
        mat_A : in matrix_5x5;
        mat_B : in matrix_5x5;
        
        -- Output Hasil
        mat_Res : out matrix_5x5;
        done : out STD_LOGIC
    );
end systolic_array;

architecture Structural of systolic_array is

    -- Panggil Komponen PE
    component processing_element is
        Port ( 
            clk, rst : in STD_LOGIC;
            in_a, in_b : in signed(7 downto 0);
            out_a, out_b, result : out signed(7 downto 0)
        );
    end component;

    -- Kabel Grid (Ukuran 6x6 agar ada sisa untuk pinggiran/boundary)
    type wire_grid is array (0 to MAX_SIZE, 0 to MAX_SIZE) of signed(7 downto 0);
    signal w_horiz : wire_grid; -- Kabel Horizontal (Data A)
    signal w_vert  : wire_grid; -- Kabel Vertikal (Data B)
    
    -- Counter untuk mengatur jadwal masuk data (Timing)
    signal tick_counter : integer range 0 to 63 := 0;

begin

    -- 1. Generate Grid 5x5
    -- Loop Baris
    GEN_ROW: for i in 0 to MAX_SIZE-1 generate
        -- Loop Kolom
        GEN_COL: for j in 0 to MAX_SIZE-1 generate
            PE_INST: processing_element port map (
                clk => clk,
                rst => rst,
                -- Sambungkan kabel
                in_a => w_horiz(i, j),   -- Input dari kiri
                in_b => w_vert(i, j),    -- Input dari atas
                out_a => w_horiz(i, j+1),-- Output ke kanan
                out_b => w_vert(i+1, j), -- Output ke bawah
                result => mat_Res(i, j)  -- Hasil disimpan ke port output
            );
        end generate GEN_COL;
    end generate GEN_ROW;

    -- 2. Data Feeder (Mengatur Data Masuk Miring/Skewed)
    process(clk, rst)
        variable t : integer;
        variable val_A, val_B : signed(7 downto 0);
    begin
        if rst = '1' then
            tick_counter <= 0;
            done <= '0';
            -- Reset kabel pinggir dengan nilai 0(Boundary conditions)
            for k in 0 to MAX_SIZE loop
                w_horiz(k, 0) <= (others => '0');
                w_vert(0, k) <= (others => '0');
            end loop;
            
        elsif rising_edge(clk) then
            if enable = '1' then
                t := tick_counter;
                
                -- Feeder Logic:
                -- Data A baris 'i' harus masuk pada waktu (t - i)
                -- Data B kolom 'j' harus masuk pada waktu (t - j)
                -- Ini menciptakan efek gelombang diagonal.
                
                for k in 0 to MAX_SIZE-1 loop
                    -- Handle Input A (Horizontal Feed)
                    if (t >= k) and (t < k + MAX_SIZE) then
                        w_horiz(k, 0) <= mat_A(k, t - k); -- Ambil data A geser waktu
                    else
                        w_horiz(k, 0) <= (others => '0'); -- Isi 0 jika data habis
                    end if;

                    -- Handle Input B (Vertical Feed)
                    if (t >= k) and (t < k + MAX_SIZE) then
                        w_vert(0, k) <= mat_B(t - k, k); -- Ambil data B geser waktu
                    else
                        w_vert(0, k) <= (others => '0'); -- Isi 0 jika data habis
                    end if;
                end loop;

                -- Atur kapan selesai
                -- Matriks 5x5 butuh sekitar 3N clock untuk selesai merambat
                if tick_counter < 15 then
                    tick_counter <= tick_counter + 1;
                    done <= '0';
                else
                    done <= '1'; -- Sinyal ke Control Unit bahwa perhitungan kelar
                end if;
            else
                -- Jika tidak enable, counter diam
                done <= '0';
            end if;
        end if;
    end process;

end Structural;