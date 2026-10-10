#include "display.h"
#include "i2c.h"

/* Active 7-bit I2C slave address (Auto-detected: 0x3C or 0x3D) */
static uint8_t g_oled_addr = OLED_I2C_ADDR_78;

/* Text cursor position */
static uint8_t g_cursor_page = 0;  /* 0 - 7 */
static uint8_t g_cursor_col  = 0;  /* 0 - 127 */

/* Standard compact 5x7 ASCII font table (ASCII 32 ' ' to 126 '~') */
static const uint8_t font5x7[95][5] = {
    {0x00, 0x00, 0x00, 0x00, 0x00}, /* ' ' */
    {0x00, 0x00, 0x5F, 0x00, 0x00}, /* '!' */
    {0x00, 0x07, 0x00, 0x07, 0x00}, /* '"' */
    {0x14, 0x7F, 0x14, 0x7F, 0x14}, /* '#' */
    {0x24, 0x2A, 0x7F, 0x2A, 0x12}, /* '$' */
    {0x23, 0x13, 0x08, 0x64, 0x62}, /* '%' */
    {0x36, 0x49, 0x55, 0x22, 0x50}, /* '&' */
    {0x00, 0x05, 0x03, 0x00, 0x00}, /* ''' */
    {0x00, 0x1C, 0x22, 0x41, 0x00}, /* '(' */
    {0x00, 0x41, 0x22, 0x1C, 0x00}, /* ')' */
    {0x08, 0x2A, 0x1C, 0x2A, 0x08}, /* '*' */
    {0x08, 0x08, 0x3E, 0x08, 0x08}, /* '+' */
    {0x00, 0x50, 0x30, 0x00, 0x00}, /* ',' */
    {0x08, 0x08, 0x08, 0x08, 0x08}, /* '-' */
    {0x00, 0x60, 0x60, 0x00, 0x00}, /* '.' */
    {0x20, 0x10, 0x08, 0x04, 0x02}, /* '/' */
    {0x3E, 0x51, 0x49, 0x45, 0x3E}, /* '0' */
    {0x00, 0x42, 0x7F, 0x40, 0x00}, /* '1' */
    {0x42, 0x61, 0x51, 0x49, 0x46}, /* '2' */
    {0x21, 0x41, 0x45, 0x4B, 0x31}, /* '3' */
    {0x18, 0x14, 0x12, 0x7F, 0x10}, /* '4' */
    {0x27, 0x45, 0x45, 0x45, 0x39}, /* '5' */
    {0x3C, 0x4A, 0x49, 0x49, 0x30}, /* '6' */
    {0x01, 0x71, 0x09, 0x05, 0x03}, /* '7' */
    {0x36, 0x49, 0x49, 0x49, 0x36}, /* '8' */
    {0x06, 0x49, 0x49, 0x29, 0x1E}, /* '9' */
    {0x00, 0x36, 0x36, 0x00, 0x00}, /* ':' */
    {0x00, 0x56, 0x36, 0x00, 0x00}, /* ';' */
    {0x00, 0x08, 0x14, 0x22, 0x41}, /* '<' */
    {0x14, 0x14, 0x14, 0x14, 0x14}, /* '=' */
    {0x41, 0x22, 0x14, 0x08, 0x00}, /* '>' */
    {0x02, 0x01, 0x51, 0x09, 0x06}, /* '?' */
    {0x32, 0x49, 0x79, 0x41, 0x3E}, /* '@' */
    {0x7E, 0x11, 0x11, 0x11, 0x7E}, /* 'A' */
    {0x7F, 0x49, 0x49, 0x49, 0x36}, /* 'B' */
    {0x3E, 0x41, 0x41, 0x41, 0x22}, /* 'C' */
    {0x7F, 0x41, 0x41, 0x22, 0x1C}, /* 'D' */
    {0x7F, 0x49, 0x49, 0x49, 0x41}, /* 'E' */
    {0x7F, 0x09, 0x09, 0x01, 0x01}, /* 'F' */
    {0x3E, 0x41, 0x41, 0x51, 0x32}, /* 'G' */
    {0x7F, 0x08, 0x08, 0x08, 0x7F}, /* 'H' */
    {0x00, 0x41, 0x7F, 0x41, 0x00}, /* 'I' */
    {0x20, 0x40, 0x41, 0x3F, 0x01}, /* 'J' */
    {0x7F, 0x08, 0x14, 0x22, 0x41}, /* 'K' */
    {0x7F, 0x40, 0x40, 0x40, 0x40}, /* 'L' */
    {0x7F, 0x02, 0x04, 0x02, 0x7F}, /* 'M' */
    {0x7F, 0x04, 0x08, 0x10, 0x7F}, /* 'N' */
    {0x3E, 0x41, 0x41, 0x41, 0x3E}, /* 'O' */
    {0x7F, 0x09, 0x09, 0x09, 0x06}, /* 'P' */
    {0x3E, 0x41, 0x51, 0x21, 0x5E}, /* 'Q' */
    {0x7F, 0x09, 0x19, 0x29, 0x46}, /* 'R' */
    {0x46, 0x49, 0x49, 0x49, 0x31}, /* 'S' */
    {0x01, 0x01, 0x7F, 0x01, 0x01}, /* 'T' */
    {0x3F, 0x40, 0x40, 0x40, 0x3F}, /* 'U' */
    {0x1F, 0x20, 0x40, 0x20, 0x1F}, /* 'V' */
    {0x7F, 0x20, 0x18, 0x20, 0x7F}, /* 'W' */
    {0x63, 0x14, 0x08, 0x14, 0x63}, /* 'X' */
    {0x03, 0x04, 0x78, 0x04, 0x03}, /* 'Y' */
    {0x61, 0x51, 0x49, 0x45, 0x43}, /* 'Z' */
    {0x00, 0x7F, 0x41, 0x41, 0x00}, /* '[' */
    {0x02, 0x04, 0x08, 0x10, 0x20}, /* '\' */
    {0x00, 0x41, 0x41, 0x7F, 0x00}, /* ']' */
    {0x04, 0x02, 0x01, 0x02, 0x04}, /* '^' */
    {0x40, 0x40, 0x40, 0x40, 0x40}, /* '_' */
    {0x00, 0x01, 0x02, 0x04, 0x00}, /* '`' */
    {0x20, 0x54, 0x54, 0x54, 0x78}, /* 'a' */
    {0x7F, 0x48, 0x44, 0x44, 0x38}, /* 'b' */
    {0x38, 0x44, 0x44, 0x44, 0x20}, /* 'c' */
    {0x38, 0x44, 0x44, 0x48, 0x7F}, /* 'd' */
    {0x38, 0x54, 0x54, 0x54, 0x18}, /* 'e' */
    {0x08, 0x7E, 0x09, 0x01, 0x02}, /* 'f' */
    {0x08, 0x14, 0x54, 0x54, 0x3C}, /* 'g' */
    {0x7F, 0x08, 0x04, 0x04, 0x78}, /* 'h' */
    {0x00, 0x44, 0x7D, 0x40, 0x00}, /* 'i' */
    {0x20, 0x40, 0x44, 0x3D, 0x00}, /* 'j' */
    {0x00, 0x7F, 0x10, 0x28, 0x44}, /* 'k' */
    {0x00, 0x41, 0x7F, 0x40, 0x00}, /* 'l' */
    {0x7C, 0x04, 0x18, 0x04, 0x78}, /* 'm' */
    {0x7C, 0x08, 0x04, 0x04, 0x78}, /* 'n' */
    {0x38, 0x44, 0x44, 0x44, 0x38}, /* 'o' */
    {0x7C, 0x14, 0x14, 0x14, 0x08}, /* 'p' */
    {0x08, 0x14, 0x14, 0x18, 0x7C}, /* 'q' */
    {0x7C, 0x08, 0x04, 0x04, 0x08}, /* 'r' */
    {0x48, 0x54, 0x54, 0x54, 0x20}, /* 's' */
    {0x04, 0x3F, 0x44, 0x40, 0x20}, /* 't' */
    {0x3C, 0x40, 0x40, 0x20, 0x7C}, /* 'u' */
    {0x1C, 0x20, 0x40, 0x20, 0x1C}, /* 'v' */
    {0x3C, 0x40, 0x30, 0x40, 0x3C}, /* 'w' */
    {0x44, 0x28, 0x10, 0x28, 0x44}, /* 'x' */
    {0x0C, 0x50, 0x50, 0x50, 0x3C}, /* 'y' */
    {0x44, 0x64, 0x54, 0x4C, 0x44}, /* 'z' */
    {0x00, 0x08, 0x36, 0x41, 0x00}, /* '{' */
    {0x00, 0x00, 0x7F, 0x00, 0x00}, /* '|' */
    {0x00, 0x41, 0x36, 0x08, 0x00}, /* '}' */
    {0x08, 0x08, 0x2A, 0x1C, 0x08}  /* '~' */
};

/* Send a single command byte to the OLED (Control Byte: 0x00) */
static void oled_send_cmd(uint8_t cmd) {
    uint8_t packet[2];
    packet[0] = 0x00; // Co=0, D/C#=0 (Command Stream)
    packet[1] = cmd;
    i2c_write(g_oled_addr, packet, 2);
}

/* Send display data bytes to the OLED (Control Byte: 0x40) */
static void oled_send_data(const uint8_t *data, uint32_t len) {
    i2c_write_reg(g_oled_addr, 0x40, data, len);
}

/* Set page and column address (Supports 1.3" SH1106 2-column hardware offset) */
static void oled_set_pos(uint8_t page, uint8_t col) {
    if (page > 7) page = 7;
    if (col > 127) col = 127;

    // SH1106 column offset: Display RAM is 132 wide, active area starts at col + 2
    uint8_t real_col = col + 2;

    oled_send_cmd(0xB0 | page);                       // Set Page address
    oled_send_cmd(0x00 | (real_col & 0x0F));          // Lower column nibble
    oled_send_cmd(0x10 | ((real_col >> 4) & 0x0F));   // Upper column nibble
}

bool disp_init(void) {
    // 1. Initialize I2C bus at 400 kHz Fast-mode for smooth display refreshes
    i2c_init(I2C_PRESCALE_400KHZ);

    // 2. Auto-detect 7-bit I2C address (0x3C / 0x78 pad, or 0x3D / 0x7A pad)
    if (i2c_probe(OLED_I2C_ADDR_78)) {
        g_oled_addr = OLED_I2C_ADDR_78;
    } else if (i2c_probe(OLED_I2C_ADDR_7A)) {
        g_oled_addr = OLED_I2C_ADDR_7A;
    } else {
        // Fallback default
        g_oled_addr = OLED_I2C_ADDR_78;
    }

    // 3. 1.3" OLED (SH1106 / SSD1306) Universal Initialization Sequence
    static const uint8_t init_cmds[] = {
        0xAE,        // Display OFF
        0x02, 0x10,  // Set lower & higher column address (offset 2)
        0x40,        // Set display start line to 0
        0xB0,        // Set page address to 0
        0x81, 0xCF,  // Set contrast control
        0xA1,        // Set segment re-map (col 127 -> SEG0)
        0xA6,        // Normal display (1=ON, 0=OFF)
        0xA8, 0x3F,  // Set multiplex ratio (1/64 duty)
        0xAD, 0x8B,  // SH1106: Enable DC-DC charge pump
        0x8D, 0x14,  // SSD1306: Enable charge pump (safe on both)
        0xC8,        // COM output scan direction: remapped (top-down)
        0xD3, 0x00,  // Display offset = 0
        0xD5, 0x80,  // Display clock divide ratio / oscillator
        0xD9, 0xF1,  // Pre-charge period
        0xDA, 0x12,  // COM pins hardware configuration
        0xDB, 0x40,  // VCOMH deselect level
        0xAF         // Turn Display ON!
    };

    for (uint32_t i = 0; i < sizeof(init_cmds); i++) {
        oled_send_cmd(init_cmds[i]);
    }

    // 4. Blank screen & reset cursor
    disp_clear();
    disp_set_cursor(0, 0);

    return true;
}

void disp_clear(void) {
    uint8_t zero_buf[32];
    for (int i = 0; i < 32; i++) zero_buf[i] = 0x00;

    for (uint8_t page = 0; page < OLED_PAGES; page++) {
        oled_set_pos(page, 0);
        // Write 128 zeros in four 32-byte chunks
        for (int chunk = 0; chunk < 4; chunk++) {
            oled_send_data(zero_buf, 32);
        }
    }

    disp_set_cursor(0, 0);
}

void disp_clear_line(uint8_t line) {
    if (line >= OLED_PAGES) return;
    oled_set_pos(line, 0);

    uint8_t zero_buf[32];
    for (int i = 0; i < 32; i++) zero_buf[i] = 0x00;
    for (int chunk = 0; chunk < 4; chunk++) {
        oled_send_data(zero_buf, 32);
    }

    disp_set_cursor(line, 0);
}

void disp_set_cursor(uint8_t line, uint8_t col) {
    if (line >= OLED_PAGES) line = OLED_PAGES - 1;
    if (col >= OLED_WIDTH) col = OLED_WIDTH - 1;

    g_cursor_page = line;
    g_cursor_col  = col;
    oled_set_pos(g_cursor_page, g_cursor_col);
}

void disp_char(char c) {
    if (c == '\n') {
        // Line feed: move to next page
        g_cursor_page = (g_cursor_page + 1) % OLED_PAGES;
        g_cursor_col = 0;
        oled_set_pos(g_cursor_page, g_cursor_col);
        return;
    }

    if (c == '\r') {
        g_cursor_col = 0;
        oled_set_pos(g_cursor_page, g_cursor_col);
        return;
    }

    // Check if line wrap is needed (6 pixels per char: 5 font + 1 space)
    if (g_cursor_col + 6 > OLED_WIDTH) {
        g_cursor_page = (g_cursor_page + 1) % OLED_PAGES;
        g_cursor_col = 0;
        oled_set_pos(g_cursor_page, g_cursor_col);
    }

    uint8_t glyph[6];
    if (c >= 32 && c <= 126) {
        for (int i = 0; i < 5; i++) {
            glyph[i] = font5x7[c - 32][i];
        }
    } else {
        // Unprintable fallback
        for (int i = 0; i < 5; i++) glyph[i] = 0x00;
    }
    glyph[5] = 0x00; // 1-pixel inter-character spacing

    oled_set_pos(g_cursor_page, g_cursor_col);
    oled_send_data(glyph, 6);

    g_cursor_col += 6;
}

void disp_str(const char *str) {
    if (!str) return;
    while (*str) {
        disp_char(*str++);
    }
}

/* Display integer numbers cleanly on RV32I without hardware division */
void disp_num(int32_t val) {
    if (val == 0) {
        disp_char('0');
        return;
    }

    if (val < 0) {
        disp_char('-');
        val = -val;
    }

    char buf[12];
    int idx = 0;
    uint32_t uval = (uint32_t)val;

    // Shift-and-subtract division by 10 (100% portable on bare-metal RV32I)
    while (uval > 0) {
        uint32_t q = 0, r = 0;
        for (int i = 31; i >= 0; i--) {
            r = (r << 1) | ((uval >> i) & 1);
            if (r >= 10) {
                r -= 10;
                q |= (1U << i);
            }
        }
        buf[idx++] = '0' + (char)r;
        uval = q;
    }

    while (idx > 0) {
        disp_char(buf[--idx]);
    }
}

void disp_hex(uint32_t val) {
    disp_str("0x");
    for (int i = 7; i >= 0; i--) {
        uint32_t nibble = (val >> (i * 4)) & 0x0F;
        char c = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
        disp_char(c);
    }
}
