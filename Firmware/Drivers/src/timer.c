#include "timer.h"
#include "soc_regs.h"

void timer_init(void) {
    REG_TIMER_CTRL = 0x01; // Enable timer
}

uint32_t timer_get_cycles(void) {
    return REG_TIMER_CNT; // 100MHz = 100,000,000 cycles per second
}

void timer_delay_cycles(uint32_t cycles) {
    uint32_t start = timer_get_cycles();
    while ((timer_get_cycles() - start) < cycles);
}
