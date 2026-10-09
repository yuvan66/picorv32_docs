#ifndef LED_H
#define LED_H
#include <stdint.h>

void led_set(uint16_t value);
void led_toggle(uint16_t mask);
void led_set_bit(uint8_t bit);
void led_clear_bit(uint8_t bit);

#endif
