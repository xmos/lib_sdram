#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include "sdram_calc.h"
#include "sdram_test.h"
#include "sdram_ports.h"

#define CALC 1 // set to 0 if parameters to calculate are not available
#define TEST 1 // set to 0 if hardware for testing is not available

#define DEFAULT_FCORE 500 // Core clock rate used when TEST is 0

#if !TEST && !CALC
#error "at least one of CALC and TEST should be set to 1"
#endif

#define VERBOSE_MSG   1

void sdram_test_suite()
{
#if TEST
  unsigned f_core = sdram_test_get_core_frequency_MHz();
#else
  unsigned f_core = DEFAULT_FCORE;
#endif

  if (VERBOSE_MSG)
  {
#if TEST
    sdram_test_print_info();
#endif
#if CALC
    sdram_calc_print_info(f_core);
#endif
    printf("starting SDRAM timing\n");
  }

  for (unsigned clock_divider = 4; clock_divider < 13; clock_divider++)
  {
    if (VERBOSE_MSG)
    {
      printf("\nF_core: %d MHz, clock divider: %d, F_clk: %d.%02d MHz\n",
            f_core, clock_divider,
            f_core / (2 * clock_divider),
            (f_core * 50 / clock_divider) % 100);
    }
    for (unsigned read_delay_clocks = 0; read_delay_clocks < 3; read_delay_clocks++)
    {
      for (unsigned sample_delay = 0; sample_delay < 2; sample_delay++)
      {
        for (unsigned i = 0; i < 6; i++)
        {
          unsigned pad_delay = 5 - i;
#if CALC
          unsigned t_read_min;
          int      t_left_margin;
          unsigned t_read;
          int      t_right_margin;
          unsigned t_read_max;
          unsigned fit;
          sdram_calc_timings(f_core, clock_divider,
                             read_delay_clocks, sample_delay, pad_delay,
                             t_read_min, t_left_margin, t_read,
                             t_right_margin, t_read_max, fit);
#endif
#if TEST
          unsigned success = sdram_test_run(clock_divider,
                               read_delay_clocks, sample_delay, pad_delay);
#endif
          printf("div: %2d read: %d sample: %d pad: %d",
                 clock_divider, read_delay_clocks, sample_delay, pad_delay);
#if CALC
          // timing window shown in nanoseconds
          printf(" [%6.3f (%7.3f) %7.3f (%7.3f) %6.3f] calc: %d",
                 (float)t_read_min/1000.0,
                 (float)t_left_margin/1000.0,
                 (float)t_read/1000.0,
                 (float)t_right_margin/1000.0,
                 (float)t_read_max/1000.0,
                 fit);
#endif
#if TEST
          printf(" test: %d", success);
#endif
          printf("\n");
        }
      }
    }
  }
  if (VERBOSE_MSG)
  {
    printf("SDRAM timing finished\n\n");
  }
}

int main()
{
  par
  {
    on tile[SERVER_TILE]: sdram_test_suite();
    on tile[SERVER_TILE]: {
      // - keep other threads busy
      // - the resulting sdram_server thread speed is
      //   Fcore/8, same as the Fclk=FCore/(2*clock_divider)
      //   of the fastest tested clock_divider of 4
      //   500 MHZ -> 63 MIPS/MHz
      //   600 MHz -> 75 MIPS/MHz
      //   800 MHz -> 100 MIPS/MHz
      // - so the processor speed scales with the raising
      //   SDRAM clock speed per clock_divider
      par(int i=0;i<6;i++) {
        { set_core_high_priority_on(); while(1); }
      }
    }
  }
  return 0;
}
