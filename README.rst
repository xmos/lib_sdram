SDRAM Library
===========

SDRAM Libary
-----------

The XMOS SDRAM module is designed for 16 bit read and write access of 
arbitrary length at up to 62.5MHz clock rates. It uses an optimised 
pinout with address and data lines overlaid along with other pinout 
optimisations in order to implement 16 bit read/write with up to 13 
address lines with a total of just 20 pins.

Features
........

The SDRAM component has the following features:

  * Configurability of:
     * SDRAM geometry,
     * clock rate,
     * refresh properties.
  * Supports:
     * read,
     * write,
     * one or more clients
     * asynchronous command decoupling with a command queue of length 8 for each client
     * refresh handled by the SDRAM component itself.
  * Requires a single core for the server.

Components
...........

 * SDRAM server.
 
Resource Usage
..............

TODO

Software version and dependencies
.................................

This document pertains to version |version| of the SDRAM library. It is
intended to be used with version 13.x of the xTIMEcomposer studio tools.

The library does not have any dependencies (i.e. it does not rely on any
other libraries).

Related application notes
.........................

The following application notes use this library:

  * AN00xxx - How to get the most out of a SDRAM server

