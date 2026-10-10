/**
 * ============================================================================
 * Project  : TRNG-Based One-Time PIN (OTP) Secure 2FA Token on RISC-V SoC
 * Platform : PicoRV32 (RV32I @ 100MHz)
 * Target   : Hardware 2FA Token with 1.3" I2C OLED & PC Portal Interface
 * ============================================================================
 */

#include "soc_regs.h"
#include "led.h"
#include "uart.h"
#include "timer.h"
#include "trng.h"
#include "i2c.h"
#include "display.h"

/* ============================================================================
 * SECTION 1: CRYPTOGRAPHIC PARAMETERS & CONSTANTS
 * ============================================================================ */

// 128-bit Pre-Shared Symmetric Secret Key (Must match host/otp_portal.py)
#define SECRET_KEY_0    0x0123456789ABCDEFULL
#define SECRET_KEY_1    0xFEDCBA9876543210ULL

// 100 MHz clock reference (100,000 cycles per millisecond)
#define TICKS_PER_MS    100000UL

/* ============================================================================
 * SECTION 2: UTILITIES & DELAYS
 * ============================================================================ */

static void delay_ms(uint32_t ms) {
    uint32_t start_time = timer_get_cycles();
    uint32_t wait_ticks = ms * TICKS_PER_MS;
    while ((timer_get_cycles() - start_time) < wait_ticks);
}

// 64-bit circular left rotate
static inline uint64_t rotl64(uint64_t x, int b) {
    return (x << b) | (x >> (64 - b));
}

// Pure shift-and-subtract modulo 1,000,000 (100% safe on RV32I)
static uint32_t mod_1000000(uint32_t val) {
    uint32_t divisor = 1000000;
    uint32_t r = 0;
    for (int i = 31; i >= 0; i--) {
        r = (r << 1) | ((val >> i) & 1);
        if (r >= divisor) {
            r -= divisor;
        }
    }
    return r;
}

/* ============================================================================
 * SECTION 3: SIPHASH-2/4 CRYPTOGRAPHIC 6-DIGIT OTP CALCULATION
 * ============================================================================ */

static void sipround(uint64_t *v0, uint64_t *v1, uint64_t *v2, uint64_t *v3) {
    *v0 += *v1; *v1 = rotl64(*v1, 13); *v1 ^= *v0; *v0 = rotl64(*v0, 32);
    *v2 += *v3; *v3 = rotl64(*v3, 16); *v3 ^= *v2;
    *v0 += *v3; *v3 = rotl64(*v3, 21); *v3 ^= *v0;
    *v2 += *v1; *v1 = rotl64(*v1, 17); *v1 ^= *v2; *v2 = rotl64(*v2, 32);
}

static uint32_t compute_6digit_otp(uint64_t k0, uint64_t k1, uint64_t m0, uint64_t m1) {
    uint64_t v0 = 0x736f6d6570736575ULL ^ k0;
    uint64_t v1 = 0x646f72616e646f6dULL ^ k1;
    uint64_t v2 = 0x6c7967656e657261ULL ^ k0;
    uint64_t v3 = 0x7465646279746573ULL ^ k1;

    // Message Block 0
    v3 ^= m0;
    sipround(&v0, &v1, &v2, &v3);
    sipround(&v0, &v1, &v2, &v3);
    v0 ^= m0;

    // Message Block 1
    v3 ^= m1;
    sipround(&v0, &v1, &v2, &v3);
    sipround(&v0, &v1, &v2, &v3);
    v0 ^= m1;

    // Finalization (16 bytes = 0x10)
    uint64_t length_block = 0x1000000000000000ULL;
    v3 ^= length_block;
    sipround(&v0, &v1, &v2, &v3);
    sipround(&v0, &v1, &v2, &v3);
    v0 ^= length_block;

    v2 ^= 0xFFULL;
    for (int i = 0; i < 4; i++) {
        sipround(&v0, &v1, &v2, &v3);
    }

    uint64_t tag = v0 ^ v1 ^ v2 ^ v3;
    uint32_t positive_tag = (uint32_t)(tag & 0x7FFFFFFFULL);
    return mod_1000000(positive_tag);
}

/* ============================================================================
 * SECTION 4: UART & STRING HELPERS
 * ============================================================================ */

static void uart_print_hex_word(uint32_t val) {
    for (int i = 7; i >= 0; i--) {
        uint32_t nibble = (val >> (i * 4)) & 0x0F;
        char hex_char = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
        uart_putc(hex_char);
    }
}

static void uart_print_6digit_pin(uint32_t pin) {
    char pin_str[7];
    pin_str[6] = '\0';
    for (int i = 5; i >= 0; i--) {
        uint32_t q = 0, r = 0;
        for (int b = 31; b >= 0; b--) {
            r = (r << 1) | ((pin >> b) & 1);
            if (r >= 10) {
                r -= 10;
                q |= (1U << b);
            }
        }
        pin_str[i] = '0' + (char)r;
        pin = q;
    }
    uart_puts(pin_str);
}

static int uart_read_line(char *buf, int max_len) {
    int count = 0;
    while (count < max_len - 1) {
        char ch = uart_getc();
        if (ch == '\r' || ch == '\n') {
            if (count > 0) break;
            continue;
        }
        buf[count++] = ch;
    }
    buf[count] = '\0';
    return count;
}

static int str_equal(const char *a, const char *b) {
    while (*a && *b) {
        if (*a != *b) return 0;
        a++;
        b++;
    }
    return (*a == *b);
}

static int str_starts_with(const char *str, const char *prefix) {
    while (*prefix) {
        if (*str != *prefix) return 0;
        str++;
        prefix++;
    }
    return 1;
}

/* ============================================================================
 * SECTION 5: AUTHENTICATION PROTOCOL & DISPLAY STATE
 * ============================================================================ */

static uint32_t g_trng_words[4];
static uint32_t g_expected_pin = 0;
static int      g_is_unlocked  = 0;

static void update_oled_challenge(void) {
    disp_clear();
    disp_set_cursor(0, 0);
    disp("2FA TOKEN LOCK");
    disp_set_cursor(1, 0);
    disp("--------------------");
    disp_set_cursor(2, 0);
    disp("CHALLENGE:");
    disp_set_cursor(3, 0);
    disp_hex(g_trng_words[0]);

    disp_set_cursor(5, 0);
    disp("Status: LOCKED");
    disp_set_cursor(6, 0);
    disp("Awaiting PC PIN...");
}

static void update_oled_unlocked(uint32_t pin) {
    disp_clear();
    disp_set_cursor(0, 0);
    disp("2FA TOKEN UNLOCKED");
    disp_set_cursor(1, 0);
    disp("--------------------");
    disp_set_cursor(2, 0);
    disp("OTP: ");
    disp(pin);

    disp_set_cursor(4, 0);
    disp("ACCESS GRANTED!");
    disp_set_cursor(6, 0);
    disp("Status: AUTHENTICATED");
}

static void emit_new_challenge(void) {
    // 1. Read 4x 32-bit hardware entropy words from TRNG FIFO
    for (int i = 0; i < 4; i++) {
        g_trng_words[i] = trng_read();
    }

    // 2. Combine into two 64-bit message blocks
    uint64_t m0 = ((uint64_t)g_trng_words[0] << 32) | (uint64_t)g_trng_words[1];
    uint64_t m1 = ((uint64_t)g_trng_words[2] << 32) | (uint64_t)g_trng_words[3];

    // 3. Compute expected 6-digit PIN locally on RISC-V SoC
    g_expected_pin = compute_6digit_otp(SECRET_KEY_0, SECRET_KEY_1, m0, m1);

    // 4. Send structured challenge over UART to PC Portal
    uart_puts("CHALLENGE:");
    for (int i = 0; i < 4; i++) {
        uart_print_hex_word(g_trng_words[i]);
    }
    uart_puts("\r\n");

    // 5. Update 1.3" OLED Display
    update_oled_challenge();
}

/* ============================================================================
 * SECTION 6: MAIN APPLICATION ENTRY POINT
 * ============================================================================ */

void main(void) {
    // 1. Initialize Peripherals
    timer_init();
    led_set(0x0001);

    // 2. Initialize TRNG & wait for entropy stabilization
    trng_init();
    while (!trng_is_warm());

    // 3. Initialize 1.3" I2C OLED Display
    disp_init();

    // 4. Print Startup Banner to UART
    uart_puts("\r\n");
    uart_puts("==============================================================\r\n");
    uart_puts("   RISC-V PicoRV32 TRNG One-Time PIN Authentication SoC       \r\n");
    uart_puts("==============================================================\r\n");

    // 5. Issue initial 128-bit challenge to PC Portal
    emit_new_challenge();

    char command_buffer[64];

    // 6. Main Event Loop
    while (1) {
        // Simple non-blocking LED indicator
        if (g_is_unlocked) {
            led_set(0xFFFF);
        } else {
            led_set(0x0001);
        }

        // Process incoming UART commands from PC Portal
        if (uart_available()) {
            uart_read_line(command_buffer, sizeof(command_buffer));

            // Case A: Request a new TRNG challenge
            if (str_equal(command_buffer, "REQ_CHALLENGE") || str_equal(command_buffer, "RESET")) {
                g_is_unlocked = 0;
                uart_puts("[SYSTEM] Generating new TRNG challenge...\r\n");
                emit_new_challenge();
            }

            // Case B: Validate 6-digit PIN (e.g. "PIN:700392" or "700392")
            else if (str_starts_with(command_buffer, "PIN:") || 
                    (command_buffer[0] >= '0' && command_buffer[0] <= '9')) {

                const char *pin_text = str_starts_with(command_buffer, "PIN:") ? 
                                       (command_buffer + 4) : command_buffer;

                uint32_t received_pin = 0;
                int digit_count = 0;
                for (int i = 0; pin_text[i] >= '0' && pin_text[i] <= '9'; i++) {
                    received_pin = (received_pin << 3) + (received_pin << 1) + (uint32_t)(pin_text[i] - '0');
                    digit_count++;
                }

                // Verify PIN
                if (digit_count == 6 && received_pin == g_expected_pin) {
                    g_is_unlocked = 1;
                    uart_puts("STATUS:ACCESS_GRANTED\r\n");
                    uart_puts("[AUTH] Success! Verified 6-digit OTP: ");
                    uart_print_6digit_pin(received_pin);
                    uart_puts("\r\n[AUTH] Access Granted! SoC Unlocked.\r\n");

                    // Update OLED display with verified PIN & unlocked state
                    update_oled_unlocked(received_pin);
                } else {
                    g_is_unlocked = 0;
                    uart_puts("STATUS:ACCESS_DENIED\r\n");
                    uart_puts("[AUTH] Verification Failed! Invalid PIN.\r\n");

                    disp_set_cursor(4, 0);
                    disp("ACCESS DENIED!   ");
                    disp_set_cursor(6, 0);
                    disp("Invalid PIN!     ");

                    delay_ms(800);
                    // Re-issue fresh challenge to prevent replay attacks
                    emit_new_challenge();
                }
            }

            // Case C: Authenticated Commands (Accessible only after unlocking)
            else if (g_is_unlocked) {
                if (str_equal(command_buffer, "PING")) {
                    uart_puts("PONG\r\n");
                }
                else if (str_starts_with(command_buffer, "LED:")) {
                    led_set(0x00FF);
                    uart_puts("[LED] Updated LED state\r\n");
                }
                else if (str_equal(command_buffer, "STATS")) {
                    uart_puts("STATS:CYCLES=");
                    uart_print_dec(timer_get_cycles());
                    uart_puts(",STATUS=UNLOCKED\r\n");
                }
                else if (str_equal(command_buffer, "LOCK")) {
                    g_is_unlocked = 0;
                    uart_puts("STATUS:LOCKED\r\n");
                    uart_puts("[AUTH] System locked by user request.\r\n");
                    emit_new_challenge();
                }
                else {
                    uart_puts("[ECHO] ");
                    uart_puts(command_buffer);
                    uart_puts("\r\n");
                }
            }

            // Case D: Access blocked
            else {
                uart_puts("STATUS:LOCKED\r\n");
                uart_puts("[AUTH] Access Locked. Please submit 6-digit PIN.\r\n");
            }
        }

        delay_ms(20);
    }
}
