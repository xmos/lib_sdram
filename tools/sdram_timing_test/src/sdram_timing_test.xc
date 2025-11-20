#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include "sdram.h"

#define VERBOSE_MSG   1
#define ERROR_MSG     0

//For XS2 (xCORE200) put an SDRAM slice into the 'triangle' slot of tile 0 of the XP-SKC-X200 slice kit
//If using 256Mb slice, then define USE_256Mb below, otherwise leave commented out

#define SDRAM_256Mb   1 //Use IS42S16160D 256Mb or similar
#define SDRAM_128Mb   0 //Use IS42S16800D 128Mb
                        //otherwise IS42S16400D 64Mb which is default on XMOS boards

#define CAS_LATENCY   2
#define REFRESH_MS    64
#define DATA_BITS     16

#if SDRAM_256Mb
#define REFRESH_CYCLES 8192
#define COL_ADDRESS_BITS 9
#define ROW_ADDRESS_BITS 13
#define BANK_ADDRESS_BITS 2
#define BANK_COUNT    4
#define ROW_COUNT     8192
#define ROW_WORDS     256
#elif SDRAM_128Mb
#define REFRESH_CYCLES 4096
#define COL_ADDRESS_BITS 9
#define ROW_ADDRESS_BITS 12
#define BANK_ADDRESS_BITS 2
#define BANK_COUNT    4
#define ROW_COUNT     4096
#define ROW_WORDS     256
#else
#define REFRESH_CYCLES 4096
#define COL_ADDRESS_BITS 8
#define ROW_ADDRESS_BITS 12
#define BANK_ADDRESS_BITS 2
#define BANK_COUNT    4
#define ROW_COUNT     4096
#define ROW_WORDS     128
#endif

#if defined(__XS3A__)
// SDRAM test board for XU316
#define SERVER_TILE 1
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1A;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1P;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1M;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_1;
#elif defined(__XS2A__)
//Triangle slot tile 0 for XU216
#define SERVER_TILE 0
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16B;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1J;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1I;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1K;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1L;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_2;
#else
//Square slot on A16 slicekit
#define SERVER_TILE 1
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1B;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1G;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1C;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_2;
#endif

unsigned get_core_frequency()
{
  unsigned pll_ctl_value;

  read_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_PLL_CTL_NUM, pll_ctl_value);

  unsigned OD = (pll_ctl_value >> 23) & 0x7;
  unsigned F  = (pll_ctl_value >>  8) & 0x1FFF;
  unsigned R  = (pll_ctl_value >>  0) & 0x3F;
  unsigned f_osc = 24000000;
  unsigned f_core = (f_osc / 2) * (F+1) / ((R+1) * (OD+1));
  return f_core;
}

unsigned sdram_tester(streaming chanend c_server)
{
#define BUF_WORDS (512)
  unsigned read_buffer[BUF_WORDS];
  unsigned write_buffer[BUF_WORDS];
  unsigned * movable read_buffer_pointer = read_buffer;
  unsigned * movable write_buffer_pointer = write_buffer;

  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);

  // fixed pattern / single r/w test

  for (unsigned i = 0; i < BUF_WORDS; i++)
  {
    write_buffer_pointer[i] = 0xcafebabe;
    read_buffer_pointer[i] = 0; // clear read pointer
  }

  sdram_write(c_server, sdram_state, 0x0, BUF_WORDS, move(write_buffer_pointer));
  sdram_complete(c_server, sdram_state, write_buffer_pointer);

  sdram_read(c_server, sdram_state, 0x0, BUF_WORDS, move(read_buffer_pointer));
  sdram_complete(c_server, sdram_state,  read_buffer_pointer);

  for (unsigned i = 0; i < BUF_WORDS; i++)
  {
    if (read_buffer_pointer[i] != write_buffer_pointer[i])
    {
      if (ERROR_MSG)
      {
        printf("fixed pattern at address 0x%x written %08x read %08x\n",
          i, write_buffer_pointer[i], read_buffer_pointer[i]);
      }
      return 0;
    }
  }

  // walking 1 pattern / single r/w test
  for (unsigned i = 0; i < BUF_WORDS; i++)
  {
    write_buffer_pointer[i] = 1 << i;
    read_buffer_pointer[i] = 0; // clear read pointer
  }

  sdram_write(c_server, sdram_state, 0x0, BUF_WORDS, move(write_buffer_pointer));
  sdram_complete(c_server, sdram_state, write_buffer_pointer);

  sdram_read(c_server, sdram_state, 0x0, BUF_WORDS, move(read_buffer_pointer));
  sdram_complete(c_server, sdram_state,  read_buffer_pointer);

  for (unsigned i = 0; i < BUF_WORDS; i++)
  {
    if (read_buffer_pointer[i] != write_buffer_pointer[i])
    {
      if (ERROR_MSG)
      {
        printf("walking 1 pattern at address 0x%x written %08x read %08x\n",
          i, write_buffer_pointer[i], read_buffer_pointer[i]);
      }
      return 0;
    }
  }

  // random pattern / whole memory test
  for (unsigned i = 0; i < BUF_WORDS; i++)
  {
    write_buffer_pointer[i] = rand();
  }

  for (unsigned address = 0; address < 4096 * BUF_WORDS; address += BUF_WORDS)
  {
    // uncomment to simulate an error
    // unsigned temp;
    // if (address == 1024 * BUF_WORDS) {
    //   temp = write_buffer_pointer[20];
    //   write_buffer_pointer[20] = 0xdeadbeef;
    // }
    sdram_write(c_server, sdram_state, address, BUF_WORDS, move(write_buffer_pointer));
    sdram_complete(c_server, sdram_state, write_buffer_pointer);
    // if (address == 1024 * BUF_WORDS) {
    //   write_buffer_pointer[20] = temp;
    // }
  }

  for (unsigned address = 0; address < 4096 * BUF_WORDS; address += BUF_WORDS)
  {
    // clear read buffer
    for (unsigned i = 0; i < BUF_WORDS; i++)
    {
      read_buffer_pointer[i] = 0;
    }

    sdram_read (c_server, sdram_state, address, BUF_WORDS, move( read_buffer_pointer));
    sdram_complete(c_server, sdram_state,  read_buffer_pointer);
    for (unsigned i = 0; i < BUF_WORDS; i++)
    {
      if (read_buffer_pointer[i] != write_buffer_pointer[i])
      {
        if (ERROR_MSG)
        {
          printf("random pattern at address 0x%x written %08x read %08x\n",
            address + i, write_buffer_pointer[i], read_buffer_pointer[i]);
        }
        return 0;
      }
    }
  }
  return 1;
}

void sdram_test(unsigned clock_divider,
                unsigned read_delay_whole_clocks,
                unsigned sample_delay,
                unsigned pad_delay)
{
  streaming chan c_sdram[1];
  unsigned success;

  par
  {
    {
      set_core_high_priority_on();
      sdram_server_with_delays(c_sdram, 1, sdram_dq_ah, sdram_cas, sdram_ras,
                   sdram_we, sdram_clk, sdram_cb,
                   CAS_LATENCY, ROW_WORDS, DATA_BITS,
                   COL_ADDRESS_BITS, ROW_ADDRESS_BITS, BANK_ADDRESS_BITS,
                   REFRESH_MS, REFRESH_CYCLES,
                   clock_divider, read_delay_whole_clocks, sample_delay, pad_delay);
    }
    {
      set_core_high_priority_on();
      success = sdram_tester(c_sdram[0]);
      sdram_shutdown(c_sdram[0]);
    }
  }
  printf("div: %2d  read: %d sample: %d pad: %d  result: %d\n",
    clock_divider, read_delay_whole_clocks, sample_delay, pad_delay, success);
}

void sdram_test_suite()
{
  if (VERBOSE_MSG)
  {
#if SDRAM_256Mb
    printf("Using 256Mb SDRAM\n");
#elif SDRAM_128Mb
    printf("Using 128Mb SDRAM\n");
#else
    printf("Using 64Mb SDRAM\n");
#endif
    printf("starting SDRAM tests\n");
  }

  unsigned f_core = get_core_frequency();

  for (unsigned clock_divider = 4; clock_divider < 13; clock_divider++)
  {
    if (VERBOSE_MSG)
    {
      unsigned f_core_MHz = f_core / 1000000;
      printf("\nF_core: %d MHz, clock divider: %d, F_clk: %d.%02d MHz\n",
            f_core_MHz, clock_divider,
            f_core_MHz / (2 * clock_divider),
            (f_core_MHz * 50 / clock_divider) % 100);
    }
    for (unsigned read_delay_clocks = 0; read_delay_clocks < 3; read_delay_clocks++)
    {
      for (unsigned sample_delay = 0; sample_delay < 2; sample_delay++)
      {
        for (unsigned i = 0; i < 6; i++)
        {
          unsigned pad_delay = 5 - i;
          sdram_test(clock_divider, read_delay_clocks, sample_delay, pad_delay);
        }
      }
    }
  }
  if (VERBOSE_MSG)
  {
    printf("SDRAM tests finished\n\n");
  }
}

int main()
{
  par
  {
    on tile[SERVER_TILE]: sdram_test_suite();
    on tile[SERVER_TILE]: par(int i=0;i<6;i++) while(1);
  }
  return 0;
}
