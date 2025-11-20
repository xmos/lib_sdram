
extern void sdram_calc_print_info(unsigned f_core);
extern void sdram_calc_timings(unsigned f_core,
                               unsigned clock_divider,
                               unsigned read_delay_clocks,
                               unsigned sample_delay,
                               unsigned pad_delay,
                               unsigned& t_read_min,
                               int&      t_left_margin,
                               unsigned& t_read,
                               int&      t_right_margin,
                               unsigned& t_read_max,
                               unsigned& fit);
