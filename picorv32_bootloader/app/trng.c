#include "trng.h"
#include "soc_regs.h"

void trng_init(void) {
    REG_TRNG_CTRL = 0x03; // Enable TRNG (bit 0) + Von Neumann de-biaser (bit 1)
}

bool trng_is_warm(void) {
    return (REG_TRNG_STATUS & 0x10) != 0; // Bit 4 = WARMUP_DONE
}

bool trng_has_data(void) {
    return (REG_TRNG_STATUS & 0x01) != 0; // Bit 0 = DATA_VALID
}

uint32_t trng_read(void) {
    while (!trng_has_data()); // Wait for valid random sample
    return REG_TRNG_DATA;     // Reading pops 32-bit random word from FIFO
}
