SDRAM Data Input Timing Calc&Test
=================================

:scope: Tools
:description: Tool to find input delays matching the round trip window
:keywords: Memory,SDRAM,Round Trip Time
:boards: custom board with xcore-ai and SDRAM, XS2 slicekit with SDRAM slice

The tool calculates suitability of read delays for the SDRAM data input,
using parameters from the datasheets and assumptions about the board parameters.
It also tests these read delays and shows the results in a table for comparison.

How to use
----------

Preparations

- edit timing parameters in sdram_calc.xc according to your SDRAM datasheet,
  the XMOS timing papers (linked in top level README) and your board situation
- adapt SDRAM port selection in sdram_ports.h
- select your SDRAM type (SDRAM_256Mb/SDRAM_128Mb/64Mb) in sdram_test.xc,
  possibly adapt the SDRAM configuration parameters at the same place
- select your board or create a new one in CMakeLists.txt
- switch between JTAG IO and XScope in config.xscope

To build and run (with XTC 15.3.x)::

> cd lib_sdram\tools\sdram_timing\
> cmake -G "Unix Makefiles" -B build
> xmake -C build

If your board supports XScope::

> xrun --xscope .\bin\sdram_timing.xe

If you want to use JTAG IO::

> xrun --io .\bin\sdram_timing.xe

If you don't have hardware or just want to do the calculations

- set #define TEST to 0 in sdram_timing.xc
- select DEFAULT_FCORE at the same place
- disable XScope in config.xscope

then::

> xsim .\bin\sdram_timing.xe

The results per setting are shown as follows (refer to comments in sdram_calc.xc)::

 F_core: 600 MHz, clock divider: 6, F_clk: 50.00 MHz
 div:  6 read: 1 sample: 1 pad: 2 [40.558 ( -0.574)  39.984 (  4.600) 44.584] calc: 0 test: 1
 div:  6 read: 1 sample: 1 pad: 1 [38.892 (  1.092)  39.984 (  2.934) 42.918] calc: 1 test: 1
 div:  6 read: 1 sample: 1 pad: 0 [37.226 (  2.758)  39.984 (  1.268) 41.252] calc: 1 test: 1
 div:  6 read: 2 sample: 0 pad: 5 [45.556 (  4.424)  49.980 ( -0.398) 49.582] calc: 0 test: 1
       ^       ^         ^      ^ \_________________________________________/       ^       ^
       |       |         |      |                      ^                            |       |
       |       |         |      |                      |                            |       |
       |       |         |      |  read window ---------                            |       |
       |       |         |      |                                                   |       |
       |       |         |      |   1 if read time fits in calculated read window ---       |
       |       |         |      |                1 if the hardware test succeeded -----------
       |       |         |      |
       |       |         |      -------------- pad_delay (0..5)
       |       |         --------------------- sample_delay 0 or 1
       |       ------------------------------- read_delay_clocks (0..2)
       --------------------------------------- clock_divider (4..12)

The read window timing is shown in nanoseconds from falling clock edge::

                        [40.558 ( -0.574)  39.984 (  4.600) 44.584]
                           ^         ^       ^        ^        ^
                           |         |       |        |        |
 read windows start      ---         |       |        |        |
 start margin            -------------       |        |        |
 read time               ---------------------        |        |
 end margin              ------------------------------        |
 read window end         ---------------------------------------

A negative margin means that there is none.
So, theoretically, such setting cannot reliably work.
In practice, some of the assumptions about hardware
latencies are relatively weak.
