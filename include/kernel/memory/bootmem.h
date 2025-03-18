#pragma once

#include "lib/types.h"

/**
 * @brief Initializes the bootmem allocator
 */
void
init_bootmem(void);

/**
 * @brief Allocates a block of memory from the bootmem allocator
 *
 * @param size The size of the block to allocate
 * @return void* A pointer to the allocated block of memory
 */
void*
bootmem_alloc(size_t size);

/**
 * @brief Get all pages in the bootmem allocator
 *
 * @return size_t The number of pages in the bootmem allocator
 */
size_t
bootmem_get_all_pages(void);