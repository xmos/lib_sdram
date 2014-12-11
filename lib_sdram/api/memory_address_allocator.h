#ifndef MEMORY_ALLOCATOR_H_
#define MEMORY_ALLOCATOR_H_

typedef enum {
    e_success,
    e_overflow,
    e_out_of_memory_range
} e_memory_address_allocator_return_code;

interface memory_address_allocator_i {
    e_memory_address_allocator_return_code request(unsigned bytes, unsigned &address);
} [[sametile]];

[[distributable]]
void memory_address_allocator(
        unsigned client_count,
        server interface memory_address_allocator_i rx[client_count],
        unsigned base_address,
        unsigned memory_size);

#endif /* MEMORY_ALLOCATOR_H_ */
