#include "uart.h"
#include "soc_regs.h"

void uart_putc(char c) {
    while (REG_UART_STATUS & UART_STAT_TX_BUSY); // Wait if transmitter is busy
    REG_UART_DATA = (uint32_t)(uint8_t)c;
}

void uart_puts(const char *str) {
    while (*str) {
        if (*str == '\n') uart_putc('\r');
        uart_putc(*str++);
    }
}

bool uart_available(void) {
    return (REG_UART_STATUS & UART_STAT_RX_VALID) != 0;
}

char uart_getc(void) {
    while (!uart_available()); // Block until byte is received
    return (char)(REG_UART_DATA & 0xFF);
}

// void uart_print_hex32(uint32_t val) {
//     uart_puts("0x");
//     for (int i = 7; i >= 0; i--) {
//         uint32_t nibble = (val >> (i * 4)) & 0x0F;
//         char c = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
//         uart_putc(c);
//     }
// }

// Pure shift-and-subtract decimal printer (no hardware DIV needed!)
void uart_print_dec(uint32_t val) {
    if (val == 0) {
        uart_putc('0');
        return;
    }
    char buf[12];
    int idx = 0;
    while (val > 0) {
        uint32_t q = 0, r = 0;
        for (int i = 31; i >= 0; i--) {
            r = (r << 1) | ((val >> i) & 1);
            if (r >= 10) {
                r -= 10;
                q |= (1U << i);
            }
        }
        buf[idx++] = '0' + (char)r;
        val = q;
    }
    while (idx > 0) {
        uart_putc(buf[--idx]);
    }
}
