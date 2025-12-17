:orphan:

##############################
lib_sdram: SDRAM library
##############################

:vendor: XMOS
:version: 3.4.0
:scope: General Use
:description: SDRAM server and Memory address allocator components
:category: General Purpose
:keywords: Memory,SDRAM
:devices: xcore-200

*******
Summary
*******

The XMOS SDRAM library is designed for read and write access of arbitrary length 32b long word buffers at up to 62.5MHz clock rates. 
It uses an optimized pinout with address and data lines overlaid along with other pinout 
optimizations to implement 16 bit read/writes to Single Data Rate (SDR) SDRAM devices of size up to 256Mb,
while consuming a total of just 20 xCORE I/O pins.

********
Features
********

* Configurability of:
   * SDRAM capacity
   * clock rate (62.5 to 25MHz steps are provided)
   * refresh properties
* Supports:
   * read of 32b long words
   * write of 32b long words
   * one or more clients
   * asynchronous command decoupling with a command queue of length 8 for each client
   * refresh handled by the SDRAM component itself
* Requires a single core for the server
* Requires 500MHz core clock operation

************
Known issues
************

* XS1 devices can support a maximum of 64 Mb SDRAM (8 MBytes) using a 8b column address. This is a technical limitation due to addressing modes in the XS1 device and cannot be worked around using the current library architecture.
* XS2 (xCORE-200) devices can support a maximum of 256 Mb SDRAM (32 MBytes) using a 9b column address. 512 Mb devices are supportable with some modifications. Please see the following github issue https://github.com/xmos/lib_sdram/issues/20 for details.
* No Application note is provided currently. Please see https://github.com/xmos/lib_sdram/examples for a simple usage example
* The IP assumes a 500MHz core clock. It may be possible to support other core clock frequencies. However, the I/O timing must be re-calculated to populate the read delay constants for the apprioriate clock divider. These may be found in ``server.xc``.

****************
Development repo
****************

* `lib_sdram <https://www.github.com/xmos/lib_sdram>`_ (https://www.github.com/xmos/lib_sdram)

**************
Required tools
**************

* XMOS XTC Tools: 15.3.1

*********************************
Required libraries (dependencies)
*********************************

* None

*************************
Related application notes
*************************

* I/O Timings for xCORE200 [#]_.

.. [#] https://www.xmos.com/download/private/I-O-timings-for-xCORE200%281.0%29.pdf

*******
Support
*******

This package is supported by XMOS Ltd. Issues can be raised against the software at
`www.xmos.com/support <https://www.xmos.com/support>`_ or using GitHub `issues <https://github.com/xmos/lib_sdram/issues>`_.