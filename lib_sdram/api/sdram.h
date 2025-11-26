// Copyright 2014-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef SDRAM_H_
#define SDRAM_H_
#include <platform.h>
#include <xccompat.h>
#include "structs_and_enums.h"

// These are needed for DOXYGEN to render properly
#ifndef __DOXYGEN__
#define const_static_unsigned_t const static unsigned
#define out_port_t out port
#define MOVABLE_REFERENCE_PARAM(type, name) type * movable &name
#define MOVABLE_PARAM(type, name) type * movable name
#endif

/**
 * The actual SDRAM server providing a software interface plus services to access the SDRAM.
 * This provides the software interface to the physical SDRAM. It provides services including:
 *  - Automatic SDRAM refresh,
 *  - Multi-client interface,
 *  - Client prioritisation,
 *  - Client command buffering,
 *  - Automatic multi-line SDRAM access.
 *
 *  \param c_client             This is an ordered array of the streaming channels to the clients. It is in client
 *                              priority order(element 0 being the highest priority).
 *  \param client_count         The number of clients.
 *  \param dq_ah                The data and address bus port.
 *  \param cas                  The CAS signal port.
 *  \param ras                  The RAS signal port.
 *  \param we                   The WE signal port.
 *  \param clk                  The SDRAM clock.
 *  \param cb                   Clock block to control the ports.
 *  \param cas_latency          The CAS latency.
 *  \param row_words            The number of 32b words in a SDRAM row (half the number of columns).
 *  \param col_bits             The count of bits for a memory location, normally 16.
 *  \param col_address_bits     The number of bits in the column address bus.
 *  \param row_address_bits     The number of bits in the row address bus.
 *  \param bank_address_bits    The number of bits in the bank address bus.
 *  \param refresh_ms           The count of milliseconds for a full refresh cycle.
 *  \param refresh_cycles       The count of refresh instructions per full refresh cycle.
 *  \param clock_divider        The divider of the system clock to the SDRAM clock.
 **/
void sdram_server(
        ARRAY_OF_SIZE(streaming_chanend_t, c_client, client_count),
        const_static_unsigned_t client_count,
        out_buffered_port_32_t dq_ah,
        out_buffered_port_32_t cas,
        out_buffered_port_32_t ras,
        out_buffered_port_8_t we,
        out_port_t clk,
        clock cb,
        const_static_unsigned_t cas_latency,
        const_static_unsigned_t row_words,
        const_static_unsigned_t col_bits,
        const_static_unsigned_t col_address_bits,
        const_static_unsigned_t row_address_bits,
        const_static_unsigned_t bank_address_bits,
        const_static_unsigned_t refresh_ms,
        const_static_unsigned_t refresh_cycles,
        const_static_unsigned_t clock_divider);

/**
 * This is used to initialise the sdram_state that follows the channel to the SDRAM server. It must only be called
 * once on the s_sdram_state that it is initialising. A client must have only one s_sdram_state that exists for the
 * life time of the use of the SDRAM.
 *
 * \param c_sdram_server    Channel to the SDRAM server.
 * \param sdram_state       State structure.
 *
 * \return                  None.
 **/
void sdram_init_state(streaming_chanend_t c_sdram_server, REFERENCE_PARAM(s_sdram_state, sdram_state));

/**
 * This is a blocking call that may be used as a select handler. It returns an array
 * to a movable pointer. It will complete when a command has been completed by the
 * server.
 **/
#pragma select handler
void sdram_complete(
        streaming_chanend_t c_sdram_server,
        REFERENCE_PARAM(s_sdram_state, state),
        MOVABLE_REFERENCE_PARAM(unsigned, buffer));

/**
 * Request the SDRAM server to perform a write operation of a number of long (32b) words.
 * This function will place a write command into the SDRAM command buffer if the command buffer is not full. This is a
 * non-blocking call with a return value to indicate the successful issuing of the write to the SDRAM server.
 *
 *  \param c_sdram_server     Channel to the SDRAM server.
 *  \param state              State structure.
 *  \param address            This is a long word address of the location in SDRAM to write from.
 *  \param word_count         The number of long words to be written to the SDRAM.
 *  \param buffer             A movable pointer from which the data to be written to the SDRAM will be read. Note, that the ownership of the pointer will pass to the SDRAM server.
 *  \return                   0 for write command has successfully be added to SDRAM command queue.
 *  \return                   1 for SDRAM command queue is full, write command has not been added.
 **/
int sdram_write(
        streaming_chanend_t c_sdram_server,
        REFERENCE_PARAM(s_sdram_state, state),
        unsigned address,
        unsigned word_count,
        MOVABLE_PARAM(unsigned, buffer));

/**
 * Request the SDRAM server to perform a read operation of a number of long (32b) words.
 * This function will place a read command into the SDRAM command buffer if the command buffer is not full. This is a
 * non-blocking call with a return value to indicate the successful issuing of the read to the SDRAM server.
 *
 *  \param c_sdram_server     Channel to the SDRAM server.
 *  \param state              State structure.
 *  \param address            This is a long word address of the location in SDRAM to read from.
 *  \param word_count         The number of long words to be read from the SDRAM.
 *  \param buffer             A movable pointer from which the data to be read from the SDRAM will be written. Note, that the ownership of the pointer will pass to the SDRAM server.
 *  \return                   0 for read command has successfully be added to SDRAM command queue.
 *  \return                   1 for SDRAM command queue is full, read command has not been added.
 *
 **/
int sdram_read(
        streaming_chanend_t c_sdram_server,
        REFERENCE_PARAM(s_sdram_state, state),
        unsigned address,
        unsigned word_count,
        MOVABLE_PARAM(unsigned, buffer));

/**
 * Terminates the SDRAM server.
 *
 *  \param c_sdram_server     Channel to the SDRAM server.
 *
 *  \return                  None.
 **/
void sdram_shutdown(streaming_chanend_t c_sdram_server);

#endif /* SDRAM_H_ */
