#include <stdio.h>
#include <stdlib.h>

// Taking data from SDRAM datasheet
// --------------------------------
//
// CAS latency of 2 * Tclk taken into account separately, not in this tool.
//
// t_ac2 - Access Time From CLK
// t_oh2 - Output Data Hold Time
//
// Showing the clock signal with clock cycle numbers and the SDRAM output data
// corresponding to these clock cycles (..00xx11..11xx22...),
// as given in the datasheet:
//
//    |<-------- Tclk ------->|
// ___1            ___________2            ___________3            -----------
//    |___________|  t_ac2    |___________| t_oh2     |___________|           |___
//                |<------->|             |<-->|
//    000000000000000000xxxx11111111111111111111xxxx22222222222222222222xxxx333333
//                          |<---------------->| output data availability window
//    |                     ^
//    |_____________________|
//
//
// Applying roundtrip latencies (pin dependent, line capacity, XMOS signal resync)
// -------------------------------------------------------------------------------
//
// Since we are only looking at the clock output vs. data input, it is irrelevant
// if latencies are added before or after the signals entering/leaving the SDRAM.
//
// The read window start is defined by the maximum round trip times.
// The read window end is defined by the minimum round trip times.
//
// ___1            ___________2            ___________3            -----------
//    |___________|           |___________|           |___________|           |___
//    |<------- rtt_max ------------>|000000000000000000xxxx11111111111111111111xx
//    |<- rtt_min ->|000000000000000000xxxx11111111111111111111xxxx222222222222222
//                                                       -->|-|<-- read window
//
// rtt_max = LAT_PIN_DEP_MAX + LAT_LINE_CAP_MAX + 5 * Tcore
// rtt_min = LAT_PIN_DEP_MIN + LAT_LINE_CAP_MIN + 4 * Tcore
//
//
// Chosing a read time (t_read) using read_delay_clocks and sample_delay,
// and moving the signal there using pad_delay:
// ----------------------------------------------------------------------
//                                                              t_read
//    |<-Tclk/2-->|<-(read_delay_clocks + sample_delay/2) * Tclk->|
// ___1            ___________2            ___________3            -----------
//    |___________|           |___________|           |___________|           |___
//    |    |<------- rtt_max ------------>|000000000000000000xxxx11111111111111111
//    |    |<- rtt_min ->|000000000000000000xxxx11111111111111111111xxxx2222222222
//    |<-->| pad_delay * Tcore                     t_read_min -->|-|<-- t_read_max
//
// read_delay_clocks = 0, 1, 2, ...
// sample_delay = 0 | 1
// pad_delay = 0...5
//
// t_read = Tclk/2 + (read_delay_clocks + sample_delay / 2) * Tclk
// t_read_min =  Tclk/2 + t_ac2 + rtt_max + pad_delay * Tcore
// t_read_max = 3Tclk/2 + t_oh2 + rtt_min + pad_delay * Tcore


// all values in picoseconds and MHz

//----------------------------------------------------------------------------------------
// Values for a xcore-ai/600 MHz onboard SDRAM case
//----------------------------------------------------------------------------------------
// processor clock
#define FCORE  600
#define TCORE (1000000/FCORE)

// I/O timing for xcore_ai, A.2, p.19, X1D00..X1D71
#define LAT_PIN_DEP_MIN   400
#define LAT_PIN_DEP_MAX  4500

// I/O timing for xcore_ai, A.3, p.20, 3.3V 5pF 4mA
// - address/data lines are short, IS45S16400J has an input capacity of 3.5pF
#define LAT_LINE_CAP_MIN 1700
#define LAT_LINE_CAP_MAX 9000

// I/O timing for xcore_ai, 4.1, p.13
#define LAT_RESYNC_MIN  (4*TCORE)
#define LAT_RESYNC_MAX  (5*TCORE)

// IS45S16400J Datasheet p.16
#define SDRAM_T_AC2      5400
#define SDRAM_T_OH2      2500

#if 0
//----------------------------------------------------------------------------------------
// Values for the XS2/500 MHz slicekit
//----------------------------------------------------------------------------------------
// processor clock
#define FCORE  500
#define TCORE (1000000/FCORE)

// I/O timing for xCORE200, p.18, all pins
#define LAT_PIN_DEP_MIN   3000
#define LAT_PIN_DEP_MAX  11300

// 1.4 ns of PCB round trip delay (correct for XCORE200 slicekit)
#define LAT_LINE_CAP_MIN 1400
#define LAT_LINE_CAP_MAX 1400

// I/O timing for xcore_ai, 4.1, p.13
#define LAT_RESYNC_MIN  (4*TCORE)
#define LAT_RESYNC_MAX  (5*TCORE)

// IS45S16400D Datasheet p.14
#define SDRAM_T_AC2      6000
#define SDRAM_T_OH2      2500

#endif

//----------------------------------------------------------------------------------------

int main()
{
  printf("SDRAM input read timing\n");
  printf("-----------------------\n");

  unsigned rtt_min = LAT_PIN_DEP_MIN + LAT_LINE_CAP_MIN + LAT_RESYNC_MIN;
  unsigned rtt_max = LAT_PIN_DEP_MAX + LAT_LINE_CAP_MAX + LAT_RESYNC_MAX;
  printf("\nRound trip time min: %d ps, max: %d ps\n", rtt_min, rtt_max);

  for (unsigned clock_divider = 4; clock_divider < 13; clock_divider++)
  {
    printf("\nF_core: %d MHz, clock divider: %d, F_clk: %d.%02d MHz\n",
           FCORE, clock_divider, FCORE / (2 * clock_divider), (FCORE * 50 / clock_divider) % 100);

    for (unsigned read_delay_clocks = 0; read_delay_clocks < 3; read_delay_clocks++)
    {
      for (unsigned sample_delay = 0; sample_delay < 2; sample_delay++)
      {
        // t_read = Tclk/2 + (read_delay_clocks + sample_delay / 2) * Tclk
        // Tclk = Tcore * clock_divider * 2
        unsigned t_read = TCORE * clock_divider * (read_delay_clocks * 2 + 1 + sample_delay);
        for (unsigned i = 0; i < 6; i++)
        {
          unsigned pad_delay = 5 - i;
          unsigned t_read_min = (clock_divider + pad_delay) * TCORE + SDRAM_T_AC2 + rtt_max;
          unsigned t_read_max = (3 * clock_divider + pad_delay) * TCORE + SDRAM_T_OH2 + rtt_min;
          unsigned success = (t_read_min < t_read && t_read < t_read_max);
          printf("div: %2d  read: %d sample: %d pad: %d  result: %d [%5d ..(%6d).. %5d ..(%6d).. %5d] ps\n",
            clock_divider, read_delay_clocks, sample_delay, pad_delay, success,
            t_read_min, t_read - t_read_min, t_read, t_read_max - t_read, t_read_max);
        }
      }
    }
  }

  return 0;
}
