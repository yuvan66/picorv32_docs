#ifndef UART_H
#define UART_H
#include <stdint.h>
#include <stdbool.h>

void uart_putc(char c);
void uart_puts(const char *str);
bool uart_available(void);
char uart_getc(void);
void uart_print_dec(uint32_t val);
void uart_print_hex32(uint32_t val);

#endif
