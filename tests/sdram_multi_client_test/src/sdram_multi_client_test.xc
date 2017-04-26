// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <stdio.h>
#include "sdram.h"

//For XS2 (xCORE200) put an SDRAM slice into the 'triangle' slot of tile 0 of the XP-SKC-X200 slice kit
//If using 256Mb slice, then define USE_256Mb below, otherwise leave commented out

#define SDRAM_256Mb   1 //Use IS42S16160D 256Mb
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

#define MAX_BUFFER_WORDS    ROW_WORDS

#define TOTAL_MEMORY_WORDS (ROW_WORDS*ROW_COUNT*BANK_COUNT)

static int test(streaming chanend c_server, s_sdram_state &sdram_state, int n){
    unsigned buffer[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer = buffer;

    unsigned errors = 0;
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += ROW_WORDS){
        for(unsigned i=0;i<ROW_WORDS;i++)
            buffer_pointer[i] = addr + i;
        int e = sdram_write(c_server, sdram_state, addr, ROW_WORDS, move(buffer_pointer));
        if(e) printf("error\n");
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }

    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS - ROW_WORDS; addr += 1){
        sdram_read(c_server, sdram_state, addr, ROW_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);

        for(unsigned i=0;i<ROW_WORDS;i++){
            if(buffer_pointer[i] != (addr + i))
                errors++;
        }
    }

    if(errors)
        printf("%d tests: %d errors:%d\n",n,  BANK_COUNT*ROW_COUNT*ROW_WORDS, errors);
    return 0;
}

void sdram_client(streaming chanend c_server, int n) {
  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);
  test(c_server, sdram_state, n);
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
  streaming chan c_sdram[7];
  par {
      on tile[SERVER_TILE]:{
          par {
              sdram_client(c_sdram[0], 0);
              sdram_client(c_sdram[1], 1);
              sdram_client(c_sdram[2], 2);
              sdram_client(c_sdram[3], 3);
              sdram_client(c_sdram[4], 4);
              sdram_client(c_sdram[5], 5);
              sdram_client(c_sdram[6], 6);
          }
          printf("Success\n");
      }
    on tile[SERVER_TILE]:sdram_server(c_sdram, 1,
            sdram_dq_ah,
            sdram_cas,
            sdram_ras,
            sdram_we,
            sdram_clk,
            sdram_cb,
            2, 128, 16, 8,12, 2, 64, 4096, 4);
  }
  return 0;
}

