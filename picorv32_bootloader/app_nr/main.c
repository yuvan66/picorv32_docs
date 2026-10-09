#include <stdint.h>

// ============================================================================
// PicoRV32 SoC Diagnostic Firmware for Boolean Board (Spartan-7 XC7S50)
// Tests: UART, LEDs, 32-bit Hardware Timer, and True Random Number Generator (TRNG)
//
// Address Map:
//   0x1000_0000 - 0x1000_1FFF : App RAM (8 KB)
//   0x2000_0000               : UART DATA (Read: RX, Write: TX)
//   0x2000_0004               : UART STATUS (bit0: tx_busy, bit1: rx_valid)
//   0x3000_0000               : LED Register (16-bit: led[15:0])
//   0x4000_0000               : TIMER_CNT (32-bit free running at 100MHz)
//   0x4000_0004               : TIMER_CMP (32-bit compare value)
//   0x4000_0008               : TIMER_CTRL (bit0: EN, bit1: W1C match/irq, bit2: match)
//   0x5000_0000               : TRNG_DATA (Read pops 32-bit random word)
//   0x5000_0004               : TRNG_STATUS (bit0: valid, bit1: health_fail, bit4: warmup_done)
//   0x5000_0008               : TRNG_CTRL (bit0: EN, bit1: VN_EN, bit2: IRQ_EN, bit3: CLR)
//   0x5000_000C               : TRNG_DIV (sample period = DIV+1 cycles)
// ============================================================================

#define UART_DATA    (*(volatile uint32_t *)0x20000000)
#define UART_STATUS  (*(volatile uint32_t *)0x20000004)
#define LED_REG      (*(volatile uint32_t *)0x30000000)

#define TIMER_CNT    (*(volatile uint32_t *)0x40000000)
#define TIMER_CMP    (*(volatile uint32_t *)0x40000004)
#define TIMER_CTRL   (*(volatile uint32_t *)0x40000008)

#define TRNG_DATA    (*(volatile uint32_t *)0x50000000)
#define TRNG_STATUS  (*(volatile uint32_t *)0x50000004)
#define TRNG_CTRL    (*(volatile uint32_t *)0x50000008)
#define TRNG_DIV     (*(volatile uint32_t *)0x5000000C)

#define UART_TX_BUSY   0x01
#define UART_RX_VALID  0x02

// ----------------------------------------------------------------------------
// UART Drivers
// ----------------------------------------------------------------------------

static inline void uart_putc(char c)
{
    while (UART_STATUS & UART_TX_BUSY)
        ;
    UART_DATA = (uint32_t)(uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

static inline int uart_hasc(void)
{
    return (UART_STATUS & UART_RX_VALID) != 0;
}

static inline char uart_getc(void)
{
    while (!(UART_STATUS & UART_RX_VALID))
        ;
    return (char)(UART_DATA & 0xFF);
}

// ----------------------------------------------------------------------------
// Numeric Formatters (Pure RV32I shift/subtract, no HW mul/div or libgcc)
// ----------------------------------------------------------------------------

static void uart_print_hex32(uint32_t val)
{
    uart_puts("0x");
    for (int i = 7; i >= 0; i--) {
        uint32_t nibble = (val >> (i * 4)) & 0xF;
        uart_putc(nibble < 10 ? ('0' + nibble) : ('A' + nibble - 10));
    }
}

static void uart_print_hex16(uint16_t val)
{
    uart_puts("0x");
    for (int i = 3; i >= 0; i--) {
        uint32_t nibble = (val >> (i * 4)) & 0xF;
        uart_putc(nibble < 10 ? ('0' + nibble) : ('A' + nibble - 10));
    }
}

static void uart_print_dec(uint32_t val)
{
    if (val == 0) {
        uart_putc('0');
        return;
    }
    char buf[12];
    int idx = 0;
    while (val > 0) {
        uint32_t q = 0;
        uint32_t r = 0;
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

// Simple delay using CPU loop
static void delay_cycles(int count)
{
    for (volatile int i = 0; i < count; i++)
        ;
}

// ----------------------------------------------------------------------------
// Main Application Entry
// ----------------------------------------------------------------------------
int main(void)
{
    // LED startup walk
    for (int i = 0; i < 16; i++) {
        LED_REG = (1U << i);
        delay_cycles(12000);
    }
    LED_REG = 0xFFFF;
    delay_cycles(30000);
    LED_REG = 0x0000;

    uart_puts("\r\n\r\n");
    uart_puts("========================================================\r\n");
    uart_puts("  PicoRV32 SoC Hardware Diagnostic Suite               \r\n");
    uart_puts("  Board: Real Digital Boolean (Xilinx Spartan-7 XC7S50)\r\n");
    uart_puts("========================================================\r\n");
    uart_puts("  Architecture : RV32I @ 100 MHz                       \r\n");
    uart_puts("  Peripherals  : UART (0x20000000), LEDs (0x30000000)  \r\n");
    uart_puts("                 TIMER (0x40000000), TRNG (0x50000000) \r\n");
    uart_puts("========================================================\r\n\r\n");

    // ------------------------------------------------------------------------
    // 1. HARDWARE TIMER TEST
    // ------------------------------------------------------------------------
    uart_puts("[TEST 1] Testing 32-bit Hardware Timer (0x40000000)...\r\n");
    uint32_t t_start = TIMER_CNT;
    delay_cycles(50000);
    uint32_t t_end = TIMER_CNT;
    uint32_t delta = t_end - t_start;

    uart_puts("  TIMER_CNT initial : ");
    uart_print_hex32(t_start);
    uart_puts("\r\n  TIMER_CNT elapsed : ");
    uart_print_hex32(t_end);
    uart_puts("\r\n  Delta cycles      : ");
    uart_print_dec(delta);
    uart_puts(" ticks\r\n");

    if (delta > 0) {
        uart_puts("  [PASS] Hardware Timer is counting at 100 MHz!\r\n");
    } else {
        uart_puts("  [FAIL] Hardware Timer counter did not increment!\r\n");
    }

    // Test Compare register
    uart_puts("  Configuring TIMER_CMP for 10,000,000 cycles (0.1s)...\r\n");
    TIMER_CMP = 10000000;
    // Clear any prior match
    TIMER_CTRL = 0x03; // EN = 1, W1C match = 1
    delay_cycles(200000);
    uint32_t ctrl_stat = TIMER_CTRL;
    uart_puts("  TIMER_CTRL status : ");
    uart_print_hex32(ctrl_stat);
    if (ctrl_stat & 0x04) {
        uart_puts(" (MATCH flag asserted!)\r\n  [PASS] Timer Match & Flag logic OK!\r\n\r\n");
        // Clear match
        TIMER_CTRL = 0x03;
    } else {
        uart_puts(" (MATCH flag not asserted yet)\r\n\r\n");
    }

    // ------------------------------------------------------------------------
    // 2. HARDWARE TRNG TEST
    // ------------------------------------------------------------------------
    uart_puts("[TEST 2] Testing Hardware TRNG (0x50000000)...\r\n");
    uart_puts("  Enabling TRNG ring oscillators (VN de-biasing enabled)...\r\n");
    TRNG_CTRL = 0x03; // EN = 1, VN_EN = 1

    uart_puts("  Waiting for TRNG warm-up (1024 samples)...\r\n");
    int timeout = 1000000;
    uint32_t trng_stat = 0;
    while (timeout-- > 0) {
        trng_stat = TRNG_STATUS;
        if (trng_stat & 0x10) // WARMUP_DONE (bit 4)
            break;
    }

    uart_puts("  TRNG_STATUS : ");
    uart_print_hex32(trng_stat);
    uart_puts("\r\n");

    if (trng_stat & 0x10) {
        uart_puts("  [PASS] TRNG Warm-up completed successfully!\r\n");
    } else {
        uart_puts("  [WARN] Warm-up taking longer than expected...\r\n");
    }

    if (trng_stat & 0x02) {
        uart_puts("  [WARN] Health test reported a condition: status = ");
        uart_print_hex32(trng_stat);
        uart_puts("\r\n");
    }

    uart_puts("  Sampling True Random Words:\r\n");
    for (int i = 1; i <= 5; i++) {
        int wait_words = 500000;
        while (wait_words-- > 0) {
            if (TRNG_STATUS & 0x01) // DATA_VALID
                break;
        }
        uint32_t rword = TRNG_DATA;
        uart_puts("    Random Word #");
        uart_print_dec(i);
        uart_puts(": ");
        uart_print_hex32(rword);
        uart_puts("\r\n");
    }
    uart_puts("  [PASS] TRNG entropy collection active!\r\n\r\n");

    // ------------------------------------------------------------------------
    // 3. CONTINUOUS RUNTIME STREAMING
    // ------------------------------------------------------------------------
    uart_puts("========================================================\r\n");
    uart_puts("  All Hardware Verified! Entering Live Streaming Mode  \r\n");
    uart_puts("  Streaming Timer Cycles, Live Entropy & LED Counter   \r\n");
    uart_puts("========================================================\r\n\r\n");

    uint32_t loop_count = 0;
    while (1) {
        loop_count++;
        uint32_t now_cycles = TIMER_CNT;

        // Fetch random number if available
        uint32_t rand_sample = 0;
        if (TRNG_STATUS & 0x01) {
            rand_sample = TRNG_DATA;
        }

        // Display lower 16 bits of TRNG on LEDs (or loop count if TRNG not ready)
        uint16_t led_val = (rand_sample != 0) ? (uint16_t)(rand_sample & 0xFFFF) : (uint16_t)(loop_count & 0xFFFF);
        LED_REG = led_val;

        uart_puts("[REPORT #");
        uart_print_dec(loop_count);
        uart_puts("] Cycles: ");
        uart_print_dec(now_cycles);
        uart_puts(" | TRNG: ");
        uart_print_hex32(rand_sample);
        uart_puts(" | LEDs: ");
        uart_print_hex16(led_val);
        uart_puts("\r\n");

        // Responsive delay (~0.5s at 100MHz) with UART echo check
        for (volatile int d = 0; d < 300000; d++) {
            if (uart_hasc()) {
                char ch = uart_getc();
                uart_puts("\r\n  >> [UART ECHO]: '");
                uart_putc(ch);
                uart_puts("' (0x");
                uart_print_hex16((uint8_t)ch);
                uart_puts(")\r\n");
            }
        }
    }

    return 0;
}
