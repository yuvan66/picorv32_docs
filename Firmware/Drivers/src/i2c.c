#include "i2c.h"
#include "soc_regs.h"

#define I2C_TIMEOUT_CYCLES  500000UL

void i2c_init(uint16_t prescale) {
    // 1. Program clock prescaler based on 100 MHz SoC bus
    REG_I2C_PRESCALE = (uint32_t)prescale;

    // 2. Clear any stale status flags (W1C bits)
    REG_I2C_STATUS = I2C_STATUS_DONE | I2C_STATUS_ARB_LOST | I2C_STATUS_CMD_ERR;

    // 3. Enable I2C Master core
    REG_I2C_CTRL = I2C_CTRL_EN;
}

void i2c_disable(void) {
    // Disable core, releasing SCL and SDA lines to open-drain high-Z
    REG_I2C_CTRL = 0;
}

bool i2c_wait_done(void) {
    uint32_t timeout = I2C_TIMEOUT_CYCLES;

    // Wait while core is shifting bits or driving bus conditions
    while ((REG_I2C_STATUS & I2C_STATUS_BUSY) && (--timeout > 0));

    if (timeout == 0) {
        // Hardware timed out (e.g. infinite clock stretching or bus disconnect)
        return false;
    }

    uint32_t status = REG_I2C_STATUS;

    // Check for hardware arbitration loss or command sequencing error
    if (status & (I2C_STATUS_ARB_LOST | I2C_STATUS_CMD_ERR)) {
        // Clear sticky error bits by writing 1 to clear
        REG_I2C_STATUS = I2C_STATUS_ARB_LOST | I2C_STATUS_CMD_ERR;
        return false;
    }

    return true;
}

bool i2c_write_byte(uint8_t data, bool start, bool stop) {
    // 1. Load data byte into transmit register
    REG_I2C_TXDATA = (uint32_t)data;

    // 2. Assemble command bitmask
    uint32_t cmd = I2C_CMD_WR;
    if (start) cmd |= I2C_CMD_STA;
    if (stop)  cmd |= I2C_CMD_STO;

    // 3. Dispatch command to hardware state machine
    REG_I2C_CMD = cmd;

    // 4. Wait for command completion
    if (!i2c_wait_done()) {
        return false;
    }

    // 5. Check acknowledgment: RXNACK == 0 means slave sent ACK
    return (REG_I2C_STATUS & I2C_STATUS_RXNACK) == 0;
}

uint8_t i2c_read_byte(bool nack, bool stop) {
    // Assemble read command
    uint32_t cmd = I2C_CMD_RD;
    if (nack) cmd |= I2C_CMD_NACK;
    if (stop) cmd |= I2C_CMD_STO;

    // Trigger read operation
    REG_I2C_CMD = cmd;

    // Wait until byte shifted in from slave
    i2c_wait_done();

    return (uint8_t)(REG_I2C_RXDATA & 0xFF);
}

bool i2c_probe(uint8_t addr7) {
    // Send START + (addr7 << 1 | 0) + STOP
    // If slave is present and operational, it pulls SDA low (ACK)
    uint8_t addr_byte = (uint8_t)((addr7 << 1) | 0);
    return i2c_write_byte(addr_byte, true, true);
}

bool i2c_write(uint8_t addr7, const uint8_t *data, uint32_t len) {
    if (len == 0) {
        return i2c_probe(addr7);
    }

    // Step 1: Send Slave Address with Write flag (R/W = 0) and START
    uint8_t addr_wr = (uint8_t)((addr7 << 1) | 0);
    if (!i2c_write_byte(addr_wr, true, false)) {
        // Device did not acknowledge address; release bus with STOP
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    // Step 2: Stream all data bytes. The final byte generates STOP.
    for (uint32_t i = 0; i < len; i++) {
        bool is_last = (i == (len - 1));
        if (!i2c_write_byte(data[i], false, is_last)) {
            // NACK received from slave during stream
            if (!is_last) {
                REG_I2C_CMD = I2C_CMD_STO;
                i2c_wait_done();
            }
            return false;
        }
    }

    return true;
}

bool i2c_write_reg(uint8_t addr7, uint8_t reg, const uint8_t *data, uint32_t len) {
    // Step 1: Send Slave Address with START
    uint8_t addr_wr = (uint8_t)((addr7 << 1) | 0);
    if (!i2c_write_byte(addr_wr, true, false)) {
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    // Step 2: Send Register pointer / Command byte
    bool reg_is_last = (len == 0);
    if (!i2c_write_byte(reg, false, reg_is_last)) {
        if (!reg_is_last) {
            REG_I2C_CMD = I2C_CMD_STO;
            i2c_wait_done();
        }
        return false;
    }

    // Step 3: Stream payload bytes if any
    for (uint32_t i = 0; i < len; i++) {
        bool is_last = (i == (len - 1));
        if (!i2c_write_byte(data[i], false, is_last)) {
            if (!is_last) {
                REG_I2C_CMD = I2C_CMD_STO;
                i2c_wait_done();
            }
            return false;
        }
    }

    return true;
}

bool i2c_read(uint8_t addr7, uint8_t *data, uint32_t len) {
    if (len == 0) return true;

    // Step 1: Send Slave Address with Read flag (R/W = 1) and START
    uint8_t addr_rd = (uint8_t)((addr7 << 1) | 1);
    if (!i2c_write_byte(addr_rd, true, false)) {
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    // Step 2: Read bytes; ACK intermediate bytes, NACK and STOP on final byte
    for (uint32_t i = 0; i < len; i++) {
        bool is_last = (i == (len - 1));
        data[i] = i2c_read_byte(is_last, is_last);
    }

    return true;
}

bool i2c_read_reg(uint8_t addr7, uint8_t reg, uint8_t *data, uint32_t len) {
    // Step 1: Write target register address
    uint8_t addr_wr = (uint8_t)((addr7 << 1) | 0);
    if (!i2c_write_byte(addr_wr, true, false)) {
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    if (!i2c_write_byte(reg, false, false)) {
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    // Step 2: Issue Repeated START with Read address
    uint8_t addr_rd = (uint8_t)((addr7 << 1) | 1);
    if (!i2c_write_byte(addr_rd, true, false)) {
        REG_I2C_CMD = I2C_CMD_STO;
        i2c_wait_done();
        return false;
    }

    // Step 3: Read data bytes
    for (uint32_t i = 0; i < len; i++) {
        bool is_last = (i == (len - 1));
        data[i] = i2c_read_byte(is_last, is_last);
    }

    return true;
}
