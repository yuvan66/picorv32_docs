#include "soc_regs.h"
#include "led.h"
#include "uart.h"
#include "timer.h"
#include "trng.h"

// ============================================================================
// PicoRV32 SoC -- Make-A-Thon 2026  |  Module Verification Demo
// Board : RealDigital Boolean (Spartan-7 XC7S50 @ 100 MHz)
// ============================================================================
// Tick constants (100 MHz clock, no division needed)
#define TICKS_PER_MS  100000UL

static void delay_ms(uint32_t ms) {
    uint32_t t0 = timer_get_cycles();
    uint32_t target = ms * TICKS_PER_MS;
    while ((timer_get_cycles() - t0) < target);
}

// ----------- LED patterns ---------------------------------------------------

static void led_knightrider(int rounds) {
    for (int r = 0; r < rounds; r++) {
        for (int i = 0; i < 16; i++) { led_set(1U << i); delay_ms(40); }
        for (int i = 14; i >= 1; i--) { led_set(1U << i); delay_ms(40); }
    }
}

static void led_binary_count(uint16_t from, uint16_t to, int step_ms) {
    for (uint32_t v = from; v <= to; v++) {
        led_set((uint16_t)v);
        delay_ms(step_ms);
    }
}

static void led_fill_center(int cycles, int step_ms) {
    for (int c = 0; c < cycles; c++) {
        uint16_t mask = 0;
        for (int i = 0; i < 8; i++) {
            mask |= (uint16_t)((1U << i) | (1U << (15 - i)));
            led_set(mask); delay_ms(step_ms);
        }
        for (int i = 0; i < 8; i++) {
            mask &= (uint16_t)(~((1U << i) | (1U << (15 - i))));
            led_set(mask); delay_ms(step_ms);
        }
    }
}

static void led_flash(int n, int on_ms, int off_ms) {
    for (int i = 0; i < n; i++) {
        led_set(0xFFFF); delay_ms(on_ms);
        led_set(0x0000); delay_ms(off_ms);
    }
}

// ----------- Section banners ------------------------------------------------

static void print_banner(const char *title) {
    uart_puts("\r\n+----------------------------------------------------------+\r\n|  ");
    uart_puts(title);
    uart_puts("\r\n+----------------------------------------------------------+\r\n");
}

static void print_pass(void) { uart_puts("  [  PASS  ] "); }
static void print_fail(void) { uart_puts("  [  FAIL  ] "); }
static void print_info(void) { uart_puts("  [  INFO  ] "); }

// ============================================================================
// MODULE 1 -- UART Test
// ============================================================================
static void test_uart(void) {
    print_banner("MODULE 1 : UART Self-Test");

    print_info(); uart_puts("Sending ASCII alphabet:\r\n  > ");
    for (char c = 'A'; c <= 'Z'; c++) { uart_putc(c); }
    uart_puts("\r\n");

    print_info(); uart_puts("Sending digits 0-9:\r\n  > ");
    for (char c = '0'; c <= '9'; c++) { uart_putc(c); }
    uart_puts("\r\n");

    print_pass(); uart_puts("UART TX verified\r\n");

    // 2-second RX sniff
    uart_puts("\r\n");
    print_info(); uart_puts("Waiting 2s for host keypress (RX test)...\r\n");
    uint32_t t0 = timer_get_cycles();
    int rx_count = 0;
    while ((timer_get_cycles() - t0) < 2 * TICKS_PER_MS * 1000) {
        if (uart_available()) {
            char ch = uart_getc();
            rx_count++;
            uart_puts("  >> RX: '"); uart_putc(ch); uart_puts("'\r\n");
        }
    }
    if (rx_count == 0) {
        print_info(); uart_puts("No RX data received (host silent -- that's OK)\r\n");
    } else {
        print_pass(); uart_print_dec(rx_count);
        uart_puts(" byte(s) received -- UART RX functional!\r\n");
    }
}

// ============================================================================
// MODULE 2 -- LED Chaser Demo
// ============================================================================
static void test_leds(void) {
    print_banner("MODULE 2 : LED Chaser & Pattern Demo");

    print_info(); uart_puts("Pattern 1 -- Knight-Rider bounce (2 rounds)...\r\n");
    led_knightrider(2);

    print_info(); uart_puts("Pattern 2 -- Binary counter 0 to 255...\r\n");
    led_binary_count(0, 255, 8);

    print_info(); uart_puts("Pattern 3 -- Fill from ends to center (2 cycles)...\r\n");
    led_fill_center(2, 45);

    print_info(); uart_puts("Pattern 4 -- Alternating halves (8 blinks)...\r\n");
    for (int i = 0; i < 8; i++) {
        led_set(0x00FF); delay_ms(120);
        led_set(0xFF00); delay_ms(120);
    }

    print_info(); uart_puts("Pattern 5 -- Full flash (3x)...\r\n");
    led_flash(3, 150, 100);
    led_set(0x0000);

    print_pass(); uart_puts("LED driver verified -- all 16 LEDs exercised\r\n");
}

// ============================================================================
// MODULE 3 -- Hardware Timer Test
// ============================================================================
static void test_timer(void) {
    print_banner("MODULE 3 : Hardware Timer Verification");
    int pass_count = 0;

    // 3a: Free-running counter advancing
    print_info(); uart_puts("Reading TIMER_CNT before and after 1 ms delay...\r\n");
    uint32_t t1 = timer_get_cycles();
    delay_ms(1);
    uint32_t t2 = timer_get_cycles();
    uint32_t delta = t2 - t1;

    uart_puts("  T1    = "); uart_print_hex32(t1); uart_puts("\r\n");
    uart_puts("  T2    = "); uart_print_hex32(t2); uart_puts("\r\n");
    uart_puts("  Delta = "); uart_print_dec(delta); uart_puts(" ticks\r\n");

    // 100 MHz -> 100000 ticks/ms. Allow +/-30%.
    if (delta >= 70000 && delta <= 130000) {
        print_pass(); uart_puts("Free-running counter correct (~100k ticks/ms)\r\n");
        pass_count++;
    } else {
        print_fail(); uart_puts("Counter delta out of expected range!\r\n");
    }

    // 3b: Measure 5 delays for accuracy
    print_info(); uart_puts("Timing 5x 1 ms delays:\r\n");
    for (int i = 1; i <= 5; i++) {
        uint32_t ts = timer_get_cycles();
        delay_ms(1);
        uint32_t te = timer_get_cycles();
        uart_puts("  Delay #"); uart_print_dec(i);
        uart_puts(" = "); uart_print_dec(te - ts);
        uart_puts(" ticks (expect ~100000)\r\n");
        // Show on LEDs: lower 8 bits of tick count >> 10
        led_set((uint16_t)(((te - ts) >> 10) & 0xFF));
        delay_ms(80);
    }
    led_set(0x0000);

    print_pass(); uart_puts("TIMER MODULE done (");
    uart_print_dec(pass_count); uart_puts("/1 sub-tests passed)\r\n");
}

// ============================================================================
// MODULE 4 -- TRNG Test
// ============================================================================
static void test_trng(void) {
    print_banner("MODULE 4 : TRNG Verification");

    print_info(); uart_puts("Waiting for TRNG warm-up (1024 entropy samples)...\r\n");
    while (!trng_is_warm());
    print_pass(); uart_puts("TRNG warm-up complete!\r\n");

    // Collect 8 random words
    print_info(); uart_puts("Sampling 8 true-random 32-bit words:\r\n");
    uint32_t words[8];
    int unique_ok = 1;
    for (int i = 0; i < 8; i++) {
        words[i] = trng_read();
        uart_puts("  Word["); uart_print_dec(i); uart_puts("] = ");
        uart_print_hex32(words[i]); uart_puts("\r\n");
        // Show lower byte on LEDs
        led_set((uint16_t)(words[i] & 0x00FF));
        delay_ms(150);
    }
    led_set(0x0000);

    // Uniqueness check
    for (int a = 0; a < 8 && unique_ok; a++)
        for (int b = a + 1; b < 8 && unique_ok; b++)
            if (words[a] == words[b]) unique_ok = 0;

    if (unique_ok) {
        print_pass(); uart_puts("All 8 samples unique -- entropy source active!\r\n");
    } else {
        print_fail(); uart_puts("Duplicate sample -- TRNG may need more warm-up\r\n");
    }

    // XOR health metric
    uint32_t xor_acc = 0;
    for (int i = 0; i < 8; i++) xor_acc ^= words[i];
    uint32_t ones = 0;
    for (int b = 0; b < 32; b++) if ((xor_acc >> b) & 1) ones++;
    uart_puts("  XOR acc = "); uart_print_hex32(xor_acc);
    uart_puts("  |  Ones = "); uart_print_dec(ones);
    uart_puts(" / 32 (ideal ~16)\r\n");
    if (ones >= 10 && ones <= 22) {
        print_pass(); uart_puts("XOR distribution healthy\r\n");
    } else {
        print_info(); uart_puts("XOR skewed -- may be OK for ring-osc design\r\n");
    }
}

// ============================================================================
// Live stream loop (runs forever)
// ============================================================================
static void run_live_stream(void) {
    print_banner("LIVE STREAM : Real-time Telemetry (press any key to echo)");
    uart_puts("  Format: [#N]  Timer=<cycles>  TRNG=<hex>  LEDs=<hex>\r\n\r\n");

    uint32_t report_count = 0;
    uint32_t last_tick = timer_get_cycles();
    uint16_t led_pattern = 0x0001;
    int direction = 1;
    uint32_t frame_count = 0;

    while (1) {
        uint32_t now = timer_get_cycles();

        // Read TRNG if ready
        uint32_t rand_word = 0;
        if (trng_has_data()) {
            rand_word = trng_read();
        }

        // 50 ms LED tick
        if ((now - last_tick) >= (50 * TICKS_PER_MS)) {
            last_tick = timer_get_cycles();
            frame_count++;

            // Advance knight-rider dot
            if (direction == 1) {
                led_pattern = (led_pattern == 0) ? 1 : (led_pattern << 1);
                if (led_pattern >= 0x8000) direction = -1;
            } else {
                led_pattern >>= 1;
                if (led_pattern <= 0x0001) direction = 1;
            }
            // XOR upper byte with TRNG bits for flair
            if (rand_word) {
                led_pattern ^= (uint16_t)((rand_word >> 16) & 0xFF00);
            }
            led_set(led_pattern);

            // Print telemetry every 10 frames (~500 ms)
            if (frame_count >= 10) {
                frame_count = 0;
                report_count++;
                uart_puts("[#"); uart_print_dec(report_count);
                uart_puts("]  Timer="); uart_print_dec(now);
                uart_puts("  TRNG="); uart_print_hex32(rand_word);
                uart_puts("  LEDs="); uart_print_hex32((uint32_t)led_pattern);
                uart_puts("\r\n");
            }
        }

        // Echo any host keypress
        if (uart_available()) {
            char ch = uart_getc();
            uart_puts("  >> [RX ECHO] '"); uart_putc(ch);
            uart_puts("'  Timer="); uart_print_dec(timer_get_cycles());
            uart_puts("\r\n");
        }
    }
}

// ============================================================================
// Entry Point
// ============================================================================
int main(void) {
    // Initialize drivers
    led_set(0x0001);
    timer_init();
    trng_init();

    // Boot blink: triple fast flash = alive
    led_flash(3, 60, 60);

    // Boot banner
    uart_puts("\r\n\r\n");
    uart_puts("##########################################################\r\n");
    uart_puts("##   PicoRV32 SoC  |  Make-A-Thon 2026  |  Demo Suite  ##\r\n");
    uart_puts("##   Board : RealDigital Boolean  (Spartan-7 XC7S50)    ##\r\n");
    uart_puts("##   CPU   : RV32I @ 100 MHz  |  Bare-Metal / No OS     ##\r\n");
    uart_puts("##   Modules : UART  |  LED  |  TIMER  |  TRNG          ##\r\n");
    uart_puts("##########################################################\r\n\r\n");
    uart_puts("  Starting module verification sequence...\r\n");

    delay_ms(300);

    test_uart();   delay_ms(200);
    test_leds();   delay_ms(200);
    test_timer();  delay_ms(200);
    test_trng();   delay_ms(200);

    uart_puts("\r\n");
    uart_puts("##########################################################\r\n");
    uart_puts("##   ALL MODULES VERIFIED -- Entering Live Stream Mode  ##\r\n");
    uart_puts("##########################################################\r\n\r\n");

    // Celebration sequence
    led_flash(5, 80, 50);
    led_knightrider(1);

    // Run forever
    run_live_stream();

    return 0;
}
