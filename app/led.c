#include "led.h"
#include "soc_regs.h"

void led_set(uint16_t value) {
    REG_LEDS = (uint32_t)value;
}

void led_toggle(uint16_t mask) {
    REG_LEDS ^= (uint32_t)mask;
}

void led_set_bit(uint8_t bit) {
    if (bit < 16) REG_LEDS |= (1U << bit);
}

void led_clear_bit(uint8_t bit) {
    if (bit < 16) REG_LEDS &= ~(1U << bit);
}
