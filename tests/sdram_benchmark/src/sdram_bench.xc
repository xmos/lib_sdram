// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <print.h>
#include <stdio.h>
#include "sdram.h"

//For XS2 (xCORE200) put an SDRAM slice into the 'triangle' slot of tile 0 of the XP-SKC-X200 slice kit
//If using 256Mb slice, then define USE_256Mb below, otherwise leave commented out

#define SDRAM_256Mb   1 //Use IS42S16160D 256Mb or similar
#define SDRAM_128Mb   0 //Use IS42S16800D 128Mb
                        //othewise IS42S16400D 64Mb which is default on XMOS boards
#define CAS_LATENCY   2
#define REFRESH_MS    64
#define CLOCK_DIV     4 //Note clock div 4 gives (500/ (4*2)) = 62.5MHz
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


#pragma unsafe arrays
void application(streaming chanend c_server, s_sdram_state sdram_state) {
#define BUF_WORDS (240)

    unsigned buffer_0[ROW_WORDS];
    unsigned buffer_1[ROW_WORDS];
    unsigned buffer_2[ROW_WORDS];
    unsigned buffer_3[ROW_WORDS];

  unsigned * movable buffer_pointer_0 = buffer_0;
  unsigned * movable buffer_pointer_1 = buffer_1;
  unsigned * movable buffer_pointer_2 = buffer_2;
  unsigned * movable buffer_pointer_3 = buffer_3;

  timer t;
  unsigned time;
#define SECONDS 2
  unsigned words_since_timeout = 0;
  t :> time;
  sdram_read(c_server, sdram_state, 0, ROW_WORDS, move(buffer_pointer_0));
  sdram_read(c_server, sdram_state, 0, ROW_WORDS, move(buffer_pointer_1));
  sdram_read(c_server, sdram_state, 0, ROW_WORDS, move(buffer_pointer_2));
  sdram_read(c_server, sdram_state, 0, ROW_WORDS, move(buffer_pointer_3));
  while(1){
    select {
      case t when timerafter(time + SECONDS*100000000) :> time:
        printintln(words_since_timeout*4/SECONDS);
        words_since_timeout = 0;
        break;
      case sdram_complete(c_server, sdram_state, buffer_pointer_0):{
        words_since_timeout += ROW_WORDS;
        sdram_read(c_server, sdram_state, 0, ROW_WORDS, move(buffer_pointer_0));
        break;
      }
    }
  }
}

void sdram_client(streaming chanend c_server) {
#if SDRAM_256Mb
  printf("Using 256Mb SDRAM\n");
#elif SDRAM_128Mb
  printf("Using 128Mb SDRAM\n");
#else
  printf("Using 64Mb SDRAM\n");
#endif

  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);
  application(c_server, sdram_state);
}

//Triangle slot tile 0 for XU216
#define      SERVER_TILE            0
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16B;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1J;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1I;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1K;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1L;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_2;

int main() {
    streaming chan c_sdram[1];
  par {
        on tile[SERVER_TILE]: sdram_client(c_sdram[0]);
        on tile[SERVER_TILE]: sdram_server(c_sdram, 1,
            sdram_dq_ah,
            sdram_cas,
            sdram_ras,
            sdram_we,
            sdram_clk,
            sdram_cb,
            CAS_LATENCY,
            ROW_WORDS,
            DATA_BITS,
            COL_ADDRESS_BITS,
            ROW_ADDRESS_BITS,
            BANK_ADDRESS_BITS,
            REFRESH_MS,
            REFRESH_CYCLES,
            CLOCK_DIV);
        on tile[0]: par(int i=0;i<6;i++) while(1);
  }
  return 0;
}
