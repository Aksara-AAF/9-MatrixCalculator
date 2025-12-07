library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all; -- Wajib pakai ini untuk fungsi saturate

entity processing_element is
    port (
        clk : in std_logic;
        rst : in std_logic;
        -- Data Input (Dari Kiri dan Atas)
        in_a : in signed(DATA_WIDTH - 1 downto 0);
        in_b : in signed(DATA_WIDTH - 1 downto 0);

        -- Data Output (Oper ke Kanan dan Bawah)
        out_a : out signed(DATA_WIDTH - 1 downto 0);
        out_b : out signed(DATA_WIDTH - 1 downto 0);

        -- Hasil Akumulasi Lokal
        result : out signed(DATA_WIDTH - 1 downto 0)
    );
end processing_element;

architecture Behavioral of processing_element is
    -- Register penyimpan hasil sementara
    signal p_sum : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
begin
    process (clk, rst)
        variable mult_res : signed(DATA_WIDTH * 2 - 1 downto 0); -- 16 bit (8x8)
        variable add_res : signed(DATA_WIDTH * 2 downto 0); -- 17 bit (16+8)
    begin
        if rst = '1' then
            out_a <= (others => '0');
            out_b <= (others => '0');
            p_sum <= (others => '0');
        elsif rising_edge(clk) then
            -- 1. Pass Data (Shift Register)
            out_a <= in_a;
            out_b <= in_b;

            -- 2. Calculate MAC (Multiply-Accumulate)
            mult_res := in_a * in_b;

            -- Resize p_sum ke 17 bit agar bisa dijumlah dengan hasil kali
            add_res := resize(mult_res, 17) + resize(p_sum, 17);

            -- 3. Saturate Result (Cegah Overflow kembali ke 8-bit)
            p_sum <= saturate(add_res);
        end if;
    end process;

    -- Outputkan hasil akumulasi
    result <= p_sum;
end Behavioral;