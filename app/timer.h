#ifndef TIMER_H
#define TIMER_H
#include <stdint.h>

void timer_init(void);
uint32_t timer_get_cycles(void);
void timer_delay_cycles(uint32_t cycles);

#endif
