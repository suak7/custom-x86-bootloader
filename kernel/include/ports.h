/**
 * C has no native syntax for the x86 IN and OUT instructions. 
 * These functions wrap inline assembly to allow communication with legacy 
 * hardware like the PIT, VGA controller, and serial ports.
 */

#ifndef PORTS_H
#define PORTS_H

#include <stdint.h>

static inline uint8_t inb(uint16_t port)
{
    uint8_t result;

    // "=a" (result): Use the eax register for the output
    // "Nd" (port): 'N' for 8-bit immediate, 'd' for the dx register
    __asm__ __volatile__("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

static inline void outb(uint16_t port, uint8_t data)
{
    __asm__ __volatile__("outb %0, %1" : : "a"(data), "Nd"(port));
}

static inline uint16_t inw(uint16_t port)
{
    uint16_t result;
    __asm__ __volatile__("inw %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

static inline void outw(uint16_t port, uint16_t data)
{
    __asm__ __volatile__("outw %0, %1" : : "a"(data), "Nd"(port));
}

static inline uint32_t inl(uint16_t port)
{
    uint32_t result;
    __asm__ __volatile__("inl %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

static inline void outl(uint16_t port, uint32_t data)
{
    __asm__ __volatile__("outl %0, %1" : : "a"(data), "Nd"(port));
}

/**
 * Modern controllers like EHCI map their registers into the physical 
 * address space. We access them like RAM, but must ensure the compiler 
 * does not reorder or cache these accesses.
 */

static inline uint8_t mmio_read8(uintptr_t base, uint32_t offset)
{
    // Ensures the compiler completes all previous 
    // memory operations before reading the hardware register.
    __asm__ __volatile__("" : : : "memory");
    return *((volatile uint8_t*)(base + offset));
}

static inline uint32_t mmio_read32(uintptr_t base, uint32_t offset)
{
    __asm__ __volatile__("" : : : "memory");
    return *((volatile uint32_t*)(base + offset));
}

static inline void mmio_write32(uintptr_t base, uint32_t offset, uint32_t value)
{
    // Writing to a volatile pointer ensures the 
    // CPU executes the write immediately.
    *((volatile uint32_t*)(base + offset)) = value;

    // Prevents the compiler from reordering subsequent code 
    // to occur before this hardware write is committed.
    __asm__ __volatile__("" : : : "memory");
}

#endif