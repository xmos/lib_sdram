// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <stdio.h>
#include "sdram.h"

 /*
  * Put an SDRAM slice into square slot of A16 board, or into slot '2' of the xCore200 slice kit
  * For xCORE200 slice kit, ensure Link switch on debug adapter is switched to "off" to avoid contention
  */

//Uses IS42S16400D 64Mb part supplied on SDRAM slice
#define MAX_BUFFER_WORDS 128
#define SDRAM_BANK_COUNT    4
#define SDRAM_ROW_COUNT     4096
#define SDRAM_ROW_WORDS     128

#define TOTAL_MEMORY_WORDS (SDRAM_ROW_WORDS*SDRAM_ROW_COUNT*SDRAM_BANK_COUNT)

static int test(streaming chanend c_server, s_sdram_state &sdram_state, int n){
    unsigned buffer[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer = buffer;

    unsigned errors = 0;
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += SDRAM_ROW_WORDS){
        for(unsigned i=0;i<SDRAM_ROW_WORDS;i++)
            buffer_pointer[i] = addr + i;
        int e = sdram_write(c_server, sdram_state, addr, SDRAM_ROW_WORDS, move(buffer_pointer));
        if(e) printf("error\n");
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }

    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS - SDRAM_ROW_WORDS; addr += 1){
        sdram_read(c_server, sdram_state, addr, SDRAM_ROW_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);

        for(unsigned i=0;i<SDRAM_ROW_WORDS;i++){
            if(buffer_pointer[i] != (addr + i))
                errors++;
        }
    }

    if(errors)
        printf("%d tests: %d errors:%d\n",n,  SDRAM_BANK_COUNT*SDRAM_ROW_COUNT*SDRAM_ROW_WORDS, errors);
    return 0;
}

void sdram_client(streaming chanend c_server, int n) {
  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);
  test(c_server, sdram_state, n);
}

//Use port mapping according to slicekit used
#ifdef __XS2A__
//Slot 2 on xCORE200 slicekit
#define      SERVER_TILE            0
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16B;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1J;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1I;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1K;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1L;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_2;
#else
//Square slot on A16 slicekit
#define      SERVER_TILE            1
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1B;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1G;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1C;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[SERVER_TILE] : clock                  sdram_cb                    = XS1_CLKBLK_2;
#endif

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

