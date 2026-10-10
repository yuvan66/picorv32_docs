#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdint.h>
#include <stdbool.h>

/* ============================================================================
 * 1.3" I2C OLED Display Driver (SH1106 / SSD1306 Controller)
 * ============================================================================
 * Note: PCB marked "0x78" corresponds to 7-bit I2C address 0x3C (0x3C << 1 = 0x78).
 *       PCB marked "0x7A" corresponds to 7-bit I2C address 0x3D (0x3D << 1 = 0x7A).
 * Resolution: 128 x 64 pixels (8 text lines, 21 characters per line in 6x8 font).
 * ============================================================================ */

#define OLED_I2C_ADDR_78    0x3C    /* 7-bit address for 0x78 pad */
#define OLED_I2C_ADDR_7A    0x3D    /* 7-bit address for 0x7A pad */

/* Display geometry */
#define OLED_WIDTH          128
#define OLED_HEIGHT         64
#define OLED_PAGES          8       /* 8 pages of 8 pixels height each */
#define OLED_CHARS_PER_LINE 21      /* 128 pixels / 6 pixels per char */

/* Lifecycle & Screen Control */
bool disp_init(void);
void disp_clear(void);
void disp_clear_line(uint8_t line);
void disp_set_cursor(uint8_t line, uint8_t col);

/* Print Primitives */
void disp_char(char c);
void disp_str(const char *str);
void disp_num(int32_t val);
void disp_hex(uint32_t val);

/* ============================================================================
 * Generic disp() Macro:
 * Automatically calls disp_str() for strings and disp_num() for integers!
 * Examples:
 *   disp("PicoRV32 SoC");
 *   disp(45129);
 * ============================================================================ */
#define disp(X) _Generic((X), \
    char*:                  disp_str, \
    const char*:            disp_str, \
    int:                    disp_num, \
    unsigned int:           disp_num, \
    long:                   disp_num, \
    unsigned long:          disp_num, \
    short:                  disp_num, \
    unsigned short:         disp_num, \
    default:                disp_num  \
)(X)

#endif /* DISPLAY_H */
