SDRAM Data Input Timing Calculations
====================================

:scope: Tools
:description: Tool to find input delays matching the round trip window
:keywords: Memory,SDRAM,Round Trip Time
:boards: custom board with xcore-ai and SDRAM

The tool calculates read delays for the SDRAM data input ports.
Input parameters are to be taken from datasheets to edit the
defines in the code. C was taken as programming language for the
tool just because it should be available to all XMOS developers.

The input values in the code are selected for a custom board
with xcore-ai and SDRAM, but the method should be valid, with adapted
inputs, for other situations as well, including XS1 and XS2.

How to use
----------

To build and run (with XTC 15.3.x)::

> cd lib_sdram\tools\sdram_timing_calculations\
> cmake -G "Unix Makefiles" -B build
> xmake -C build
> xsim .\bin\sdram_timing_calculations.xe

The results per setting are shown as follows (refer to comments in the program)::

 F_core: 600 MHz, clock divider: 6, F_clk: 50.00 MHz
 div:  6  read: 1 sample: 1 pad: 2  result: 0 [40558 ..(  -574).. 39984 ..(  4600).. 44584] ps
 div:  6  read: 1 sample: 1 pad: 1  result: 1 [38892 ..(  1092).. 39984 ..(  2934).. 42918] ps
 div:  6  read: 1 sample: 1 pad: 0  result: 1 [37226 ..(  2758).. 39984 ..(  1268).. 41252] ps
 div:  6  read: 2 sample: 0 pad: 5  result: 0 [45556 ..(  4424).. 49980 ..(  -398).. 49582] ps
       ^        ^         ^      ^          ^
       |        |         |      |          |
       |        |         |      |          --- 1 if the read time fits in the read window
       |        |         |      -------------- pad_delay (0..5)
       |        |         --------------------- sample_delay 0 or 1
       |        ------------------------------- read_delay_clocks (0..2)
       ---------------------------------------- clock_divider (4..12)

The read window timing is shown in picoseconds from falling clock edge::

                        [40558 ..(  -574).. 39984 ..(  4600).. 44584]
                           ^          ^       ^          ^       ^
                           |          |       |          |       |
 read windows start      ---          |       |          |       |
 start margin            --------------       |          |       |
 read time               ----------------------          |       |
 end margin              ---------------------------------       |
 read window end         -----------------------------------------

A negative margin means that there is none.
So, theoretically, such setting cannot reliably work.
In practice, some of the assumptions about hardware
latencies are relatively weak.
