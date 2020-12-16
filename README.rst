SDRAM Library
=============

SDRAM Libary
------------

The XMOS SDRAM library is designed for read and write access of arbitrary length 32b long word buffers at up to 62.5MHz clock rates. 
It uses an optimized pinout with address and data lines overlaid along with other pinout 
optimizations to implement 16 bit read/writes to Single Data Rate (SDR) SDRAM devices of size up to 256Mb,
while consuming a total of just 20 xCORE I/O pins.

Features
........

The SDRAM component has the following features:

  * Configurability of:

     - SDRAM capacity
     - clock rate (62.5 to 25MHz steps are provided)
     - refresh properties
  * Supports:

     - read of 32b long words
     - write of 32b long words
     - one or more clients
     - asynchronous command decoupling with a command queue of length 8 for each client
     - refresh handled by the SDRAM component itself
  * Requires a single core for the server
  * Requires 500MHz core clock operation

Components
...........

 * SDRAM server
 * Memory address allocator

Software version and dependencies
.................................

The CHANGELOG contains information about the current and previous versions.
For a list of direct dependencies, look for DEPENDENT_MODULES in lib_sdram/module_build_info.


Related application notes
.........................

- I/O Timings for xCORE200 [#]_.

.. [#] https://www.xmos.com/download/private/I-O-timings-for-xCORE200%281.0%29.pdf




