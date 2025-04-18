library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIR_Filter is
    Port (
        clk         : in  std_logic;
        data_in     : in  std_logic_vector(15 downto 0);
        data_out    : out std_logic_vector(31 downto 0)
    );
end FIR_Filter;

architecture Behavioral of FIR_Filter is

    -- ========== Type Declarations ==========
    type signed11_array_t  is array (0 to 31) of signed(10 downto 0);
    type integer_array_t   is array (0 to 31) of integer;
    type delay_array_t     is array (0 to 31) of signed(15 downto 0);
    type product_array_t   is array (0 to 31) of signed(26 downto 0);
    type sum16_array_t     is array (0 to 15) of signed(27 downto 0);
    type sum8_array_t      is array (0 to 7)  of signed(28 downto 0);
    type sum4_array_t      is array (0 to 3)  of signed(29 downto 0);
    type sum2_array_t      is array (0 to 1)  of signed(30 downto 0);

    -- ========== Coefficients as Integers ==========
    constant coeff_values : integer_array_t := (
        -17,-20,-26,-31,-29,-15,20,82,174,294,437,591,741,873,971,1023,1023,971,873,741,591,437,294,174,82,20,-15,-29,-31,-26,-20,-17
    );

    -- ========== Coefficients Converted to Signed ==========
    constant coeffs : signed11_array_t := (
        to_signed(coeff_values(0), 11),  to_signed(coeff_values(1), 11),
        to_signed(coeff_values(2), 11),  to_signed(coeff_values(3), 11),
        to_signed(coeff_values(4), 11),  to_signed(coeff_values(5), 11),
        to_signed(coeff_values(6), 11),  to_signed(coeff_values(7), 11),
        to_signed(coeff_values(8), 11),  to_signed(coeff_values(9), 11),
        to_signed(coeff_values(10), 11), to_signed(coeff_values(11), 11),
        to_signed(coeff_values(12), 11), to_signed(coeff_values(13), 11),
        to_signed(coeff_values(14), 11), to_signed(coeff_values(15), 11),
        to_signed(coeff_values(16), 11), to_signed(coeff_values(17), 11),
        to_signed(coeff_values(18), 11), to_signed(coeff_values(19), 11),
        to_signed(coeff_values(20), 11), to_signed(coeff_values(21), 11),
        to_signed(coeff_values(22), 11), to_signed(coeff_values(23), 11),
        to_signed(coeff_values(24), 11), to_signed(coeff_values(25), 11),
        to_signed(coeff_values(26), 11), to_signed(coeff_values(27), 11),
        to_signed(coeff_values(28), 11), to_signed(coeff_values(29), 11),
        to_signed(coeff_values(30), 11), to_signed(coeff_values(31), 11)
    );

    -- ========== Signals ==========
    signal delay_line  : delay_array_t := (others => (others => '0'));
    signal products    : product_array_t := (others => (others => '0'));
    signal sum_stage1  : sum16_array_t := (others => (others => '0'));
    signal sum_stage2  : sum8_array_t := (others => (others => '0'));
    signal sum_stage3  : sum4_array_t := (others => (others => '0'));
    signal sum_stage4  : sum2_array_t := (others => (others => '0'));
    signal final_sum   : signed(31 downto 0) := (others => '0');

begin

    -- ===============================================
    -- Delay Line: Shifts input samples through the buffer
    -- Each new input moves the existing samples one stage down
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 31 downto 1 loop
                delay_line(i) <= delay_line(i - 1);
            end loop;
            delay_line(0) <= signed(data_in);
        end if;
    end process;

    -- ===============================================
    -- Multiply Stage: Multiplies each delayed sample with its coefficient
    -- Produces 32 parallel product values for summing
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 31 loop
                products(i) <= delay_line(i) * coeffs(i);
            end loop;
        end if;
    end process;

    -- ===============================================
    -- Sum Stage 1: Adds 32 products pairwise into 16 values
    -- This begins the summation tree to reduce complexity
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 15 loop
                sum_stage1(i) <= resize(products(2*i) + products(2*i + 1), 28);
            end loop;
        end if;
    end process;

    -- ===============================================
    -- Sum Stage 2: Adds 16 values pairwise into 8 results
    -- Continues reducing the total number of partial sums
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 7 loop
                sum_stage2(i) <= resize(sum_stage1(2*i) + sum_stage1(2*i + 1), 29);
            end loop;
        end if;
    end process;

    -- ===============================================
    -- Sum Stage 3: Adds 8 values pairwise into 4 results
    -- This hierarchical structure balances pipeline stages
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 3 loop
                sum_stage3(i) <= resize(sum_stage2(2*i) + sum_stage2(2*i + 1), 30);
            end loop;
        end if;
    end process;

    -- ===============================================
    -- Sum Stage 4: Adds 4 values pairwise into 2 results
    -- This is the second to last addition stage
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 1 loop
                sum_stage4(i) <= resize(sum_stage3(2*i) + sum_stage3(2*i + 1), 31);
            end loop;
        end if;
    end process;

    -- ===============================================
    -- Final Summation: Adds the last 2 values into 1
    -- Produces the final FIR filter output sample
    -- ===============================================
    process(clk)
    begin
        if rising_edge(clk) then
            final_sum <= resize(sum_stage4(0) + sum_stage4(1), 32);
        end if;
    end process;

    -- ===============================================
    -- Output Assignment: Converts final result to std_logic_vector
    -- This is the final output of the FIR filter
    -- ===============================================
    data_out <= std_logic_vector(final_sum);

end Behavioral;
