#pragma once

#include "kernel/memory/page.h"

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
 * @brief Initialize pages (reserve memory that used by bootmem allocator)
 *
 * @param pages The pages to initialize
 * @param page_cnt The number of pages
 */
void
bootmem_pre_init_pages(struct page* pages, size_t page_cnt);