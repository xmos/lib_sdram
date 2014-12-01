#include <platform.h>
#include <print.h>
#include "sdram.h"

/*
 * Put an sdram slice into square slot of A16 board.
 */

#define SLOTS 8
#define MAX_BUFFER_WORDS 256
#define SDRAM_COL_ADDRESS_BITS 8
#define SDRAM_ROW_ADDRESS_BITS 12
#define SDRAM_BANK_ADDRESS_BITS 2
#define SDRAM_COL_COUNT     256
#define SDRAM_BANK_COUNT    4
#define SDRAM_ROW_COUNT     4096
#define SDRAM_ROW_WORDS     128

#pragma unsafe arrays
void application(streaming chanend c_server, s_sdram_state sdram_state) {
#define BUF_WORDS (240)

    unsigned buffer_0[SDRAM_ROW_WORDS];
    unsigned buffer_1[SDRAM_ROW_WORDS];
    unsigned buffer_2[SDRAM_ROW_WORDS];
    unsigned buffer_3[SDRAM_ROW_WORDS];

  unsigned * movable buffer_pointer_0 = buffer_0;
  unsigned * movable buffer_pointer_1 = buffer_1;
  unsigned * movable buffer_pointer_2 = buffer_2;
  unsigned * movable buffer_pointer_3 = buffer_3;

  timer t;
  unsigned time;
#define SECONDS 2
  unsigned words_since_timeout = 0;
  t :> time;
  sdram_read(c_server, sdram_state, 0, SDRAM_ROW_WORDS, move(buffer_pointer_0));
  sdram_read(c_server, sdram_state, 0, SDRAM_ROW_WORDS, move(buffer_pointer_1));
  sdram_read(c_server, sdram_state, 0, SDRAM_ROW_WORDS, move(buffer_pointer_2));
  sdram_read(c_server, sdram_state, 0, SDRAM_ROW_WORDS, move(buffer_pointer_3));
  while(1){
    select {
      case t when timerafter(time + SECONDS*100000000) :> time:
        printintln(words_since_timeout*4/SECONDS);
        words_since_timeout = 0;
        break;
      case sdram_complete(c_server, sdram_state, buffer_pointer_0):{
        words_since_timeout += SDRAM_ROW_WORDS;
        sdram_read(c_server, sdram_state, 0, SDRAM_ROW_WORDS, move(buffer_pointer_0));
        break;
      }
    }
  }
}

void sdram_client(streaming chanend c_server) {
  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);
  application(c_server, sdram_state);
}

on tile[1] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[1] : out buffered port:32   sdram_cas                   = XS1_PORT_1B;
on tile[1] : out buffered port:32   sdram_ras                   = XS1_PORT_1G;
on tile[1] : out buffered port:8    sdram_we                    = XS1_PORT_1C;
on tile[1] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[1] : clock                  sdram_cb                    = XS1_CLKBLK_2;

int main() {
    streaming chan c_sdram[1];
  par {
        on tile[1]:  sdram_client(c_sdram[0]);
        on tile[1]:sdram_server(c_sdram, 1,
            sdram_dq_ah,
            sdram_cas,
            sdram_ras,
            sdram_we,
            sdram_clk,
            sdram_cb,
            2, 128, 16, 8,12, 2, 64, 4096, 4);
        on tile[0]: par(int i=0;i<6;i++) while(1);
  }
  return 0;
}
