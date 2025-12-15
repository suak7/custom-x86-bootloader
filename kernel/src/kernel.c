#include "driver/pci.h"
#include <kernel.h>
#include "driver/serial.h"

void print(const char* str, int row) 
{
    char* video = (char*)VIDEO_MEMORY;
    video += row * 160;  
    
    int i = 0;
    while (str[i] != '\0') 
    {
        video[i * 2] = str[i];      
        video[i * 2 + 1] = WHITE_ON_BLACK;  
        i++;
    }
}

void print_hex(uint32_t value, int row) 
{
    const char* hex = "0123456789ABCDEF";
    char buf[9];
    buf[8] = '\0';

    for (int i = 7; i >= 0; i--) 
    {
        buf[i] = hex[value & 0xF];
        value >>= 4;
    }

    print(buf, row);
}

void clear_screen(void) 
{
    char* video = (char*)VIDEO_MEMORY;
    
    for (int i = 0; i < 80 * 25 * 2; i += 2) 
    {
        video[i] = ' ';
        video[i + 1] = WHITE_ON_BLACK;
    }
}

void kernel_main(void) 
{
    clear_screen();
    serial_init();

    print("Kernel loaded successfully", 0);
    print("Scanning PCI bus...", 1);

    print("Enumerating PCI devices...", 2);

    pci_enumerate();

    print("PCI scan complete", 8);

    while (1) 
    {
        __asm__ __volatile__("hlt");
    }
}