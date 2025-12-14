#ifndef SERIAL_H
#define SERIAL_H

#include <stdint.h>

void serial_init(void);
void serial_write_char(char c);
void serial_print(const char* str);
void serial_print_hex(uint32_t value);

#endif