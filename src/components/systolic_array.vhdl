library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all;

entity systolic_array is
    port (
        clk    : in std_logic;
        rst    : in std_logic;
        enable : in std_logic; -- Sinyal Start dari Control Unit

        -- Input Matriks Utuh (5x5)
        mat_A : in matrix_5x5;
        mat_B : in matrix_5x5;

        -- Output Hasil
        mat_Res : out matrix_5x5;
        done    : out std_logic
    );
end systolic_array;

architecture Structural of systolic_array is

    -- Panggil Komponen PE
    component processing_element is
        port (
            clk, rst             : in std_logic;
            in_a, in_b           : in signed(7 downto 0);
            out_a, out_b, result : out signed(7 downto 0)
        );
    end component;

    -- Kabel Grid (Ukuran 6x6 agar ada sisa untuk pinggiran/boundary)
    type wire_grid is array (0 to MAX_SIZE, 0 to MAX_SIZE) of signed(7 downto 0);
    signal w_horiz : wire_grid; -- Kabel Horizontal (Data A)
    signal w_vert : wire_grid; -- Kabel Vertikal (Data B)

    -- Counter untuk mengatur jadwal masuk data (Timing)
    signal tick_counter : integer range 0 to 63 := 0;

begin

    -- 1. Generate Grid 5x5
    -- Loop Baris
    GEN_ROW : for i in 0 to MAX_SIZE - 1 generate
        -- Loop Kolom
        GEN_COL : for j in 0 to MAX_SIZE - 1 generate
            PE_INST : processing_element port map(
                clk => clk,
                rst => rst,
                -- Sambungkan kabel
                in_a   => w_horiz(i, j),     -- Input dari kiri
                in_b   => w_vert(i, j),      -- Input dari atas
                out_a  => w_horiz(i, j + 1), -- Output ke kanan
                out_b  => w_vert(i + 1, j),  -- Output ke bawah
                result => mat_Res(i, j)      -- Hasil disimpan ke port output
            );
        end generate GEN_COL;
    end generate GEN_ROW;

    -- 2. Data Feeder (Mengatur Data Masuk Miring/Skewed)
    process (clk, rst)
        variable t : integer;
    begin
        if rst = '1' then
            tick_counter <= 0;
            done <= '0';
            for k in 0 to MAX_SIZE loop
                w_horiz(k, 0) <= (others => '0');
                w_vert(0, k) <= (others => '0');
            end loop;

        elsif rising_edge(clk) then
            if enable = '1' then
                t := tick_counter;

                -- Feed Matrix A (Horizontal) - dengan skew
                for i in 0 to MAX_SIZE - 1 loop
                    if t >= i and (t - i) < MAX_SIZE then
                        w_horiz(i, 0) <= mat_A(i, t - i);
                    else
                        w_horiz(i, 0) <= (others => '0');
                    end if;
                end loop;

                -- Feed Matrix B (Vertical) - dengan skew
                for j in 0 to MAX_SIZE - 1 loop
                    if t >= j and (t - j) < MAX_SIZE then
                        w_vert(0, j) <= mat_B(t - j, j);
                    else
                        w_vert(0, j) <= (others => '0');
                    end if;
                end loop;

                -- Counter increment
                if tick_counter < 63 then
                    tick_counter <= tick_counter + 1;
                end if;

                -- Done setelah semua data melewati array
                -- Butuh waktu: (MAX_SIZE * 2 - 1) + beberapa cycle untuk propagasi
                if tick_counter >= (MAX_SIZE * 3) then
                    done <= '1';
                else
                    done <= '0';
                end if;

            else
                -- Tidak enable, reset counter
                tick_counter <= 0;
                done <= '0';
                for k in 0 to MAX_SIZE loop
                    w_horiz(k, 0) <= (others => '0');
                    w_vert(0, k) <= (others => '0');
                end loop;
            end if;
        end if;
    end process;

end Structural;