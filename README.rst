SDRAM Library
=============

SDRAM Libary
------------

The XMOS SDRAM module is designed for 16 bit read and write access of 
arbitrary length at up to 62.5MHz clock rates. It uses an optimised 
pinout with address and data lines overlaid along with other pinout 
optimisations in order to implement 16 bit read/write with up to 13 
address lines with a total of just 20 pins.

Features
........

The SDRAM component has the following features:

  * Configurability of:
     - SDRAM geometry,
     - clock rate,
     - refresh properties.
  * Supports:
     - read,
     - write,
     - one or more clients
     - asynchronous command decoupling with a command queue of length 8 for each client
     - refresh handled by the SDRAM component itself.
  * Requires a single core for the server.

Components
...........

 * SDRAM server.
 * Memory address allocator.
 
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

Related application notes
.........................

The following application notes use this library:

  * AN00170 - Using the SDRAM library


