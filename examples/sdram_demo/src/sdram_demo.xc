#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include "sdram.h"

/*
 * Put an sdram slice into square slot of A16 board.
 */

void application(streaming chanend c_server) {
#define BUF_WORDS (16)
  unsigned read_buffer[BUF_WORDS];
  unsigned write_buffer[BUF_WORDS];
  unsigned * movable read_buffer_pointer = read_buffer;
  unsigned * movable write_buffer_pointer = write_buffer;

  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);

  for(unsigned i=0;i<BUF_WORDS;i++){
    write_buffer_pointer[i] = i;
    read_buffer_pointer[i] = 0;
  }

  sdram_write(c_server, sdram_state, 0, BUF_WORDS, move(write_buffer_pointer));
  sdram_read (c_server, sdram_state, 0, BUF_WORDS, move( read_buffer_pointer));

  sdram_complete(c_server, sdram_state, write_buffer_pointer);
  sdram_complete(c_server, sdram_state,  read_buffer_pointer);

  for(unsigned i=0;i<BUF_WORDS;i++){
    printf("%08x %d\n", read_buffer_pointer[i], i);
    if(read_buffer_pointer[i] != write_buffer_pointer[i]){
      printf("SDRAM demo fail.\n");
     _Exit(1);
    }
  }
  printf("SDRAM demo complete.\n");
  _Exit(0);
}

on tile[1] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[1] : out buffered port:32   sdram_cas                   = XS1_PORT_1B;
on tile[1] : out buffered port:32   sdram_ras                   = XS1_PORT_1G;
on tile[1] : out buffered port:8    sdram_we                    = XS1_PORT_1C;
on tile[1] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[1] : clock                  sdram_cb                    = XS1_CLKBLK_1;

int main() {
  streaming chan c_sdram[1];
  par {
      on tile[1]:sdram_server(c_sdram, 1,
              sdram_dq_ah,
              sdram_cas,
              sdram_ras,
              sdram_we,
              sdram_clk,
              sdram_cb,
              2, 128, 16, 8,12, 2, 64, 4096, 4);
    on tile[1]: application(c_sdram[0]);
    on tile[1]: par(int i=0;i<6;i++) while(1);
  }
  return 0;
}
