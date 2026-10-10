#ifndef I2C_H
#define I2C_H

#include <stdint.h>
#include <stdbool.h>

/* ============================================================================
 * Clock Prescaler Configurations (Assuming 100 MHz System Clock)
 * Formula: f_scl = f_clk / (4 * (PRESCALE + 1))
 * ============================================================================ */
#define I2C_PRESCALE_100KHZ     249U    /* Standard-mode: 100 kHz */
#define I2C_PRESCALE_400KHZ     62U     /* Fast-mode: 400 kHz     */

/* Common I2C display 7-bit bus addresses */
#define I2C_ADDR_OLED_SSD1306   0x3C    /* Common 0.96" / 1.3" OLED (SA0=0) */
#define I2C_ADDR_OLED_ALT       0x3D    /* Alternate OLED address   (SA0=1) */
#define I2C_ADDR_LCD_PCF8574    0x27    /* Common HD44780 I2C backpack      */
#define I2C_ADDR_LCD_ALT        0x3F    /* Alternate LCD backpack address   */

/* ============================================================================
 * I2C Master API Functions
 * ============================================================================ */

/**
 * @brief Initialize the I2C Master peripheral.
 * @param prescale Clock divider value (e.g., I2C_PRESCALE_100KHZ or I2C_PRESCALE_400KHZ).
 */
void i2c_init(uint16_t prescale);

/**
 * @brief Disable I2C peripheral and release bus lines to high-Z.
 */
void i2c_disable(void);

/**
 * @brief Wait until active command finishes executing.
 * @return true if command finished successfully without bus collision/error, false otherwise.
 */
bool i2c_wait_done(void);

/**
 * @brief Transmit a single 8-bit byte over the I2C bus with optional START and STOP conditions.
 * @param data Byte to transmit.
 * @param start If true, asserts START (or Repeated START) condition before sending byte.
 * @param stop If true, asserts STOP condition after slave ACK/NACK phase.
 * @return true if slave responded with ACK (0), false if NACK (1) or bus error.
 */
bool i2c_write_byte(uint8_t data, bool start, bool stop);

/**
 * @brief Receive a single 8-bit byte from the I2C bus.
 * @param nack If true, master sends NACK to indicate last byte. If false, sends ACK.
 * @param stop If true, asserts STOP condition after the byte is received.
 * @return Received 8-bit byte.
 */
uint8_t i2c_read_byte(bool nack, bool stop);

/**
 * @brief Probe if a device exists and is acknowledging on the I2C bus.
 * @param addr7 7-bit I2C slave address (0x08 - 0x77).
 * @return true if device responded with ACK, false if no response.
 */
bool i2c_probe(uint8_t addr7);

/**
 * @brief Transmit a buffer of bytes to an I2C slave device (ideal for OLED/LCD displays).
 *        Issues: START -> [SlaveAddr | WR] -> Byte 0 ... -> Byte N-1 -> STOP.
 * @param addr7 7-bit slave address.
 * @param data Pointer to array of bytes to transmit.
 * @param len Number of bytes to transmit.
 * @return true on success, false if any byte was NACKed or on error.
 */
bool i2c_write(uint8_t addr7, const uint8_t *data, uint32_t len);

/**
 * @brief Write a command/register byte followed by a data buffer to an I2C slave device.
 *        Issues: START -> [SlaveAddr | WR] -> [reg] -> Byte 0 ... -> Byte N-1 -> STOP.
 * @param addr7 7-bit slave address.
 * @param reg Register or command byte (e.g. 0x00 for OLED command, 0x40 for OLED data).
 * @param data Optional payload buffer (can be NULL if len == 0).
 * @param len Number of payload bytes to transmit.
 * @return true on success, false if NACKed or on error.
 */
bool i2c_write_reg(uint8_t addr7, uint8_t reg, const uint8_t *data, uint32_t len);

/**
 * @brief Read a buffer of bytes from an I2C slave device.
 *        Issues: START -> [SlaveAddr | RD] -> Read 0 (ACK) ... -> Read N-1 (NACK + STOP).
 * @param addr7 7-bit slave address.
 * @param data Pointer to destination buffer.
 * @param len Number of bytes to read.
 * @return true on success, false on error.
 */
bool i2c_read(uint8_t addr7, uint8_t *data, uint32_t len);

/**
 * @brief Read from a specific register address using a repeated START condition.
 *        Issues: START -> [SlaveAddr | WR] -> [reg] -> Rep-START -> [SlaveAddr | RD] -> Data -> STOP.
 * @param addr7 7-bit slave address.
 * @param reg Register address to read from.
 * @param data Destination buffer.
 * @param len Number of bytes to read.
 * @return true on success, false on error.
 */
bool i2c_read_reg(uint8_t addr7, uint8_t reg, uint8_t *data, uint32_t len);

#endif /* I2C_H */
