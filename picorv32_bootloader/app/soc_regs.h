#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

// UART (0x20000000)
#define REG_UART_DATA     (*(volatile uint32_t *)0x20000000)
#define REG_UART_STATUS   (*(volatile uint32_t *)0x20000004)
#define UART_STAT_TX_BUSY (1U << 0)
#define UART_STAT_RX_VALID (1U << 1)

// 16-bit LEDs (0x30000000)
#define REG_LEDS          (*(volatile uint32_t *)0x30000000)

// 32-bit Hardware Timer (0x40000000)
#define REG_TIMER_CNT     (*(volatile uint32_t *)0x40000000)
#define REG_TIMER_CMP     (*(volatile uint32_t *)0x40000004)
#define REG_TIMER_CTRL    (*(volatile uint32_t *)0x40000008)

// Hardware TRNG (0x50000000)
#define REG_TRNG_DATA     (*(volatile uint32_t *)0x50000000)
#define REG_TRNG_STATUS   (*(volatile uint32_t *)0x50000004)
#define REG_TRNG_CTRL     (*(volatile uint32_t *)0x50000008)
#define REG_TRNG_DIV      (*(volatile uint32_t *)0x5000000C)

#endif