
extern unsigned sdram_test_get_core_frequency_MHz();
extern void     sdram_test_print_info();
extern unsigned sdram_test_run(unsigned clock_divider,
                               unsigned read_delay_whole_clocks,
                               unsigned sample_delay,
                               unsigned pad_delay);
