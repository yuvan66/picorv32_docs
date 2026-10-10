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

// I2C Master (0x60000000)
#define REG_I2C_PRESCALE  (*(volatile uint32_t *)0x60000000)
#define REG_I2C_CTRL      (*(volatile uint32_t *)0x60000004)
#define REG_I2C_TXDATA    (*(volatile uint32_t *)0x60000008)
#define REG_I2C_RXDATA    (*(volatile uint32_t *)0x6000000C)
#define REG_I2C_CMD       (*(volatile uint32_t *)0x60000010)
#define REG_I2C_STATUS    (*(volatile uint32_t *)0x60000014)

#define I2C_CTRL_EN             (1U << 0)
#define I2C_CTRL_IRQ_EN         (1U << 1)

#define I2C_CMD_STA             (1U << 0)
#define I2C_CMD_STO             (1U << 1)
#define I2C_CMD_WR              (1U << 2)
#define I2C_CMD_RD              (1U << 3)
#define I2C_CMD_NACK            (1U << 4)

#define I2C_STATUS_BUSY         (1U << 0)
#define I2C_STATUS_DONE         (1U << 1)
#define I2C_STATUS_RXNACK       (1U << 2)
#define I2C_STATUS_ARB_LOST     (1U << 3)
#define I2C_STATUS_BUS_BUSY     (1U << 4)
#define I2C_STATUS_CMD_ERR      (1U << 5)
#define I2C_STATUS_SCL          (1U << 6)
#define I2C_STATUS_SDA          (1U << 7)

#define I2C_PRESCALE_100KHZ     249U
#define I2C_PRESCALE_400KHZ     62U

#endif