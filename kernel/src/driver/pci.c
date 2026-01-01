#include <stdint.h>
#include <ports.h>
#include <kernel.h>
#include "driver/pci.h"
#include "driver/serial.h"
#include "driver/vga.h"
#include "driver/ehci.h"

static uint32_t pci_addr(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset) 
{
    return (1U << 31)
         | ((uint32_t)bus  << 16)
         | ((uint32_t)slot << 11)
         | ((uint32_t)func << 8)
         | (offset & 0xFC);
}

uint32_t pci_read(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset) 
{
    outl(PCI_CONFIG_ADDRESS, pci_addr(bus, slot, func, offset));
    return inl(PCI_CONFIG_DATA);
}

void pci_print_device_info(uint8_t bus, uint8_t slot, uint8_t func, uint32_t id, uint8_t class_code, uint8_t subclass, uint8_t prog_if) 
{
    serial_print("PCI ["); 
    serial_print_hex8(bus); 
    serial_print(":"); 
    serial_print_hex8(slot); 
    serial_print(":"); 
    serial_print_hex8(func); 
    serial_print("]");
    serial_print(" ID = "); 
    serial_print_hex(id);
    serial_print(" Class = "); 
    serial_print_hex8(class_code);
    serial_print(" Subclass = ");  
    serial_print_hex8(subclass);
    serial_print(" ProgIF = "); 
    serial_print_hex8(prog_if);
    serial_print("\n");
}

void pci_check_device(uint8_t bus, uint8_t slot, uint8_t func) 
{
    uint32_t id = pci_read(bus, slot, func, PCI_VENDOR_ID);
    
    if ((id & 0xFFFF) == 0xFFFF) 
    {
        return; 
    }

    uint32_t class_info = pci_read(bus, slot, func, PCI_CLASS_INFO);
    uint8_t class_code = (class_info >> 24) & 0xFF;
    uint8_t subclass = (class_info >> 16) & 0xFF;
    uint8_t prog_if = (class_info >> 8)  & 0xFF;

    pci_print_device_info(bus, slot, func, id, class_code, subclass, prog_if);

    if (class_code == PCI_CLASS_SERIAL && subclass == PCI_SUBCLASS_USB && prog_if == 0x20) 
    {
        ehci_init_controller(bus, slot, func);
    }
}

void pci_enumerate(void)
{ 
    vga_print_color("                                    ARTORIAS\n\n", WHITE, BLACK);

    for (uint16_t bus = 0; bus < 256; bus++)
    {
        for (uint8_t slot = 0; slot < 32; slot++)
        {
            uint32_t id = pci_read(bus, slot, 0, PCI_VENDOR_ID);
            
            if ((id & 0xFFFF) == 0xFFFF) 
            {
                continue;
            }
            
            pci_check_device(bus, slot, 0);

            uint32_t header_type = pci_read(bus, slot, 0, PCI_HEADER_TYPE);
            
            if ((header_type >> 16) & 0x80) 
            {
                for (uint8_t func = 1; func < 8; func++) 
                {
                    pci_check_device(bus, slot, func);
                }
            }
        }
    }
}