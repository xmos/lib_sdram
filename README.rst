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
 
Resource Usage
..............

.. resusage::
  :widths: 6 1 4 1 1 1

  * - configuration: SDRAM server
    - globals: out buffered port:32 sdram_dq_ah=XS1_PORT_16A;out buffered port:32 sdram_cas=XS1_PORT_1B;out buffered port:32 sdram_ras=XS1_PORT_1G;out buffered port:8    sdram_we=XS1_PORT_1C;out port sdram_clk=XS1_PORT_1F;clock sdram_cb=XS1_CLKBLK_1;
    - locals:  streaming chan c_sdram[1];
    - fn: sdram_server(c_sdram, 1,sdram_dq_ah,sdram_cas,sdram_ras,sdram_we,sdram_clk,sdram_cb,2, 128, 16, 8,12, 2, 64, 4096, 4);
    - pins: 20
    - ports: 4 (1-bit), 1 (16-bit)

  * - configuration: Memory address allocator 
    - globals: 
    - locals:  interface memory_address_allocator_i to_memory_alloc[1];
    - fn: memory_address_allocator( 1, to_memory_alloc, 0, 1024*1024*8);
    - pins: 0
    - ports: 0


Software version and dependencies
.................................

.. libdeps::


Known Issues
------------

The library is currently limited to the following SDRAM device capacities:

 - XS1 devices can support a maximum of 64 Mb SDRAM (8 MBytes) using a 8b column address. This is a technical limitation due to addressing modes in the XS1 device and cannot be worked around.
 - XS2 (xCORE-200) devices can support a maximum of 256 Mb SDRAM (32 MBytes) using a 9b column address. 512 Mb devices are supportable with some modifications. Please see https://github.com/xmos/lib_sdram/issues/20 for details.
 - No Application note is provided currently. Please see https://github.com/xmos/lib_sdram/examples for simple usage examples


Related application notes
.........................

- None


