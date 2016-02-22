// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <print.h>
#include <stdio.h>
#include <stdlib.h>
#include <xs1.h>
#include "sdram.h"

 /*
  * Put an SDRAM slice into 'square' slot of A16 slice kit, or into slot '2' of the xCore200 slice kit
  * For xCORE200 slice kit, ensure Link switch on debug adapter is switched to "off" to avoid contention
  */
#define VERBOSE_MSG 1

#define SDRAM_256Mb 0 //Use IS45S16160D 256Mb, othewise IS42S16400D 64Mb
#define FAST_TEST   1 //Simplify read and wait only 12 seconds instead of 120 for refresh tests

#define CAS_LATENCY   2
#define REFRESH_MS    64
#define CLOCK_DIV     3 //Note clock div 4 gives (500/ (4*2)) = 62.5MHz
#define DATA_BITS     16

#if SDRAM_256Mb
#define REFRESH_CYCLES 8192
#define COL_ADDRESS_BITS 9
#define ROW_ADDRESS_BITS 13
#define BANK_ADDRESS_BITS 2
#define BANK_COUNT    4
#define ROW_COUNT     8192
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

#define TOTAL_MEMORY_WORDS (ROW_WORDS*ROW_COUNT*BANK_COUNT)

{unsigned, unsigned, unsigned} decode_identifier(unsigned d){
    unsigned bank, row, word;
    bank = d&((1<<BANK_ADDRESS_BITS)-1);
    row = (d>>(BANK_ADDRESS_BITS))&((1<<ROW_ADDRESS_BITS)-1);
    word = (d>>(BANK_ADDRESS_BITS + ROW_ADDRESS_BITS))&((1<<COL_ADDRESS_BITS)-1);
    return {bank, row, word};
}
unsigned c = 0xffffffff;

static void reset_super_pattern(unsigned x) {
  c = x;
}

static unsigned super_pattern() {
  crc32(c, 0xff, 0x82F63B78);
  return c;
}

#define TEST_WORDS  (ROW_WORDS)
#define MAX_BUFFER_WORDS 256

static void whole_memory_write_read(streaming chanend c_server, s_sdram_state &sdram_state){
    unsigned buffer[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer = buffer;

    int error = 0;

    if (VERBOSE_MSG) printf("Begin   : whole_memory_write_read\n");

    //clear memory to know value
    for(unsigned i=0;i<TEST_WORDS;i++)
        buffer_pointer[i] = 0xdeafbeef;
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        sdram_write(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }
    printf("cleared\n");


    //Fill address value into memory location
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        for(unsigned i=0;i<TEST_WORDS;i++){
            buffer_pointer[i] = (addr + i);
        }
        sdram_write(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }

    printf("written\n");

#if FAST_TEST
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
#else
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS - TEST_WORDS; addr += 1){
#endif

        sdram_read(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);

        for(unsigned i=0;i<TEST_WORDS;i++){
            if(buffer_pointer[i] != (addr + i)){
                error = 1;
                if (VERBOSE_MSG) printf("error read:%08x wrote:%08x base_addr:0x%x i:0x%x: Difference (r-w)=%d \n",
                        buffer_pointer[i], (addr + i), addr, i, (buffer_pointer[i] - (addr + i)));
            }
        }
    }
    if (VERBOSE_MSG) printf("Complete: whole_memory_write_read\t");
    if (VERBOSE_MSG) printf(error?"fail\n":"pass\n");
}

static void refresh_test_1(streaming chanend c_server, s_sdram_state &sdram_state){
    timer t;
    unsigned time;
    unsigned buffer[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer = buffer;
    int error = 0;
    if (VERBOSE_MSG) printf("Begin   : refresh_test_1\n");

    //write some data
    for(unsigned i=0;i<TEST_WORDS;i++)
        buffer_pointer[i] = 0xffffffff;

    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        sdram_write(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }
    //wait for 2 mins
    t:> time;
    for(unsigned j=0;j<2;j++){
        for(unsigned i=0;i<60;i++)
#if FAST_TEST
            t when timerafter(time + 10000000) :> time;
#else
            t when timerafter(time + 100000000) :> time;
#endif
    }

    //read it back
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        for(unsigned i=0;i<TEST_WORDS;i++)
            buffer_pointer[i] = 0;

        sdram_read(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);

        for(unsigned i=0;i<TEST_WORDS;i++){
            if(buffer_pointer[i] != 0xffffffff){
                error = 1;
                if (VERBOSE_MSG) printf("error %08x %08x addr:%d i:%d\n", buffer_pointer[i] , 0xffffffff, addr, i);
            }
        }
    }
    if (VERBOSE_MSG) printf("Complete: refresh_test_1\t\t");
    if (VERBOSE_MSG) printf(error?"fail\n":"pass\n");
}

static void refresh_test_2(streaming chanend c_server, s_sdram_state &sdram_state){
    timer t;
    unsigned time;
    unsigned buffer[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer = buffer;
    int error = 0;
    if (VERBOSE_MSG) printf("Begin   : refresh_test_2\n");

    //write some data
    for(unsigned i=0;i<TEST_WORDS;i++)
        buffer_pointer[i] = 0;

    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        sdram_write(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);
    }
    //wait for 2 mins
    t:> time;
    for(unsigned j=0;j<2;j++){
        for(unsigned i=0;i<60;i++)
#if FAST_TEST
            t when timerafter(time + 10000000) :> time;
#else
            t when timerafter(time + 100000000) :> time;
#endif
    }

    //read it back
    for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
        for(unsigned i=0;i<TEST_WORDS;i++)
            buffer_pointer[i] = 0xffffffff;

        sdram_read(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer));
        sdram_complete(c_server, sdram_state, buffer_pointer);

        for(unsigned i=0;i<TEST_WORDS;i++){
            if(buffer_pointer[i] != 0){
                error = 1;
                if (VERBOSE_MSG) printf("error %08x %08x addr:%d i:%d\n", buffer_pointer[i] , 0, addr, i);
            }
        }
    }
    if (VERBOSE_MSG) printf("Complete: refresh_test_2\t\t");
    if (VERBOSE_MSG) printf(error?"fail\n":"pass\n");
}

static void refresh_test_3(streaming chanend c_server, s_sdram_state &sdram_state){
    unsigned buffer0[MAX_BUFFER_WORDS];
    unsigned buffer1[MAX_BUFFER_WORDS];
    unsigned buffer2[MAX_BUFFER_WORDS];
    unsigned buffer3[MAX_BUFFER_WORDS];
    unsigned buffer4[MAX_BUFFER_WORDS];
    unsigned buffer5[MAX_BUFFER_WORDS];
    unsigned buffer6[MAX_BUFFER_WORDS];
    unsigned buffer7[MAX_BUFFER_WORDS];
    unsigned * movable buffer_pointer0 = buffer0;
    unsigned * movable buffer_pointer1 = buffer1;
    unsigned * movable buffer_pointer2 = buffer2;
    unsigned * movable buffer_pointer3 = buffer3;
    unsigned * movable buffer_pointer4 = buffer4;
    unsigned * movable buffer_pointer5 = buffer5;
    unsigned * movable buffer_pointer6 = buffer6;
    unsigned * movable buffer_pointer7 = buffer7;

      int error = 0;
      if (VERBOSE_MSG) printf("Begin   : refresh_test_3\n");
      reset_super_pattern(0);
      for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
          for(unsigned i=0;i<TEST_WORDS;i++)
              buffer_pointer0[i] = super_pattern();
          sdram_write(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer0));
          sdram_complete(c_server, sdram_state, buffer_pointer0);
      }

      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer0));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer1));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer2));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer3));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer4));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer5));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer6));
      sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer7));

      for(unsigned i=0;i<8*100000;i++){
          sdram_complete(c_server, sdram_state, buffer_pointer0);
          sdram_read(c_server, sdram_state, 0, TEST_WORDS, move(buffer_pointer0));
      }
      sdram_complete(c_server, sdram_state, buffer_pointer0);
      sdram_complete(c_server, sdram_state, buffer_pointer1);
      sdram_complete(c_server, sdram_state, buffer_pointer2);
      sdram_complete(c_server, sdram_state, buffer_pointer3);
      sdram_complete(c_server, sdram_state, buffer_pointer4);
      sdram_complete(c_server, sdram_state, buffer_pointer5);
      sdram_complete(c_server, sdram_state, buffer_pointer6);
      sdram_complete(c_server, sdram_state, buffer_pointer7);

      //read it back
      reset_super_pattern(0);
      for(unsigned addr = 0; addr < TOTAL_MEMORY_WORDS; addr += TEST_WORDS){
          for(unsigned i=0;i<TEST_WORDS;i++)
              buffer_pointer0[i] = 0;
          sdram_read(c_server, sdram_state, addr, TEST_WORDS, move(buffer_pointer0));
          sdram_complete(c_server, sdram_state, buffer_pointer0);

          for(unsigned i=0;i<TEST_WORDS;i++){
              unsigned s = super_pattern();
              if(buffer_pointer0[i] != s){
                  error = 1;
                  if (VERBOSE_MSG) printf("error %08x %08x addr:%x i:%d\n", buffer_pointer0[i] , s, addr, i);
              }
          }
      }
      if (VERBOSE_MSG) printf("Complete: refresh_test_3\t\t");
      if (VERBOSE_MSG) printf(error?"fail\n":"pass\n");
}

static void testbench_single_thread(streaming chanend c_server, s_sdram_state &sdram_state) {
  whole_memory_write_read(c_server, sdram_state);
  refresh_test_1(c_server, sdram_state);
  refresh_test_2(c_server, sdram_state);
  refresh_test_3(c_server, sdram_state);
}

static void load_thread(chanend in_t, chanend out_t) {
  set_thread_fast_mode_on();
  in_t :> int;
  out_t <: 1;
}

static void testbench(streaming chanend c_server, s_sdram_state &sdram_state, chanend in_t, chanend out_t) {
  testbench_single_thread(c_server, sdram_state);
  out_t <: 1;
  in_t :> int;
}

static void test_4_threads(streaming chanend c_server, s_sdram_state &sdram_state) {
  chan c[3];
  if (VERBOSE_MSG)
    printf("4 threaded test suite start\n");
  par {
    testbench(c_server, sdram_state, c[0], c[1]);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[0]);
  }
  if (VERBOSE_MSG)
    printf("4 threaded test suite completed\n");
}

static void test_8_threads(streaming chanend c_server, s_sdram_state &sdram_state) {
  chan c[7];
  if (VERBOSE_MSG)
    printf("8 threaded test suite start\n");
  par {
    testbench(c_server, sdram_state, c[0], c[1]);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[5]);
    load_thread(c[5], c[6]);
    load_thread(c[6], c[0]);
  }
  if (VERBOSE_MSG)
    printf("8 threaded test suite completed\n");
}
static void test_7_threads(streaming chanend c_server, s_sdram_state &sdram_state) {
  chan c[6];
  if (VERBOSE_MSG)
    printf("7 threaded test suite start\n");
  par {
    testbench(c_server, sdram_state, c[0], c[1]);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[5]);
    load_thread(c[5], c[0]);
  }
  if (VERBOSE_MSG)
    printf("7 threaded test suite completed\n");
}
static void test_6_threads(streaming chanend c_server, s_sdram_state &sdram_state) {
  chan c[5];
  if (VERBOSE_MSG)
    printf("6 threaded test suite start\n");
  par {
    testbench(c_server, sdram_state, c[0], c[1]);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[0]);
  }
  if (VERBOSE_MSG)
    printf("6 threaded test suite completed\n");
}
static void test_5_threads(streaming chanend c_server, s_sdram_state &sdram_state) {
  chan c[4];
  if (VERBOSE_MSG)
    printf("5 threaded test suite start\n");
  par {
    testbench(c_server, sdram_state, c[0], c[1]);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[0]);
  }
  if (VERBOSE_MSG)
    printf("5 threaded test suite completed\n");
}

void sdram_client(streaming chanend c_server) {

  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_server, sdram_state);

  if (VERBOSE_MSG)
    printf("Test suite begin\n");
  test_8_threads(c_server, sdram_state);
  test_7_threads(c_server, sdram_state);
  test_6_threads(c_server, sdram_state);
  test_5_threads(c_server, sdram_state);
  test_4_threads(c_server, sdram_state);
  if (VERBOSE_MSG)
    printf("Test suite completed\n");
  _Exit(0);
}

//Use port mapping according to slicekit used
#ifdef __XS2A__
//Mic Array Board #2
#define      SERVER_TILE            1
on tile[SERVER_TILE] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[SERVER_TILE] : out buffered port:32   sdram_cas                   = XS1_PORT_1A;
on tile[SERVER_TILE] : out buffered port:32   sdram_ras                   = XS1_PORT_1B;
on tile[SERVER_TILE] : out buffered port:8    sdram_we                    = XS1_PORT_1D;
on tile[SERVER_TILE] : out port               sdram_clk                   = XS1_PORT_1C;
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
  streaming chan c_sdram[1];
  par {
    on tile[SERVER_TILE]:sdram_client(c_sdram[0]);
    on tile[SERVER_TILE]:
    {
        set_core_high_priority_on();
        sdram_server(c_sdram, 1,
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
    }
  }
  return 0;
}

