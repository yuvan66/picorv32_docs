#ifndef TRNG_H
#define TRNG_H
#include <stdint.h>
#include <stdbool.h>

void trng_init(void);
bool trng_is_warm(void);
bool trng_has_data(void);
uint32_t trng_read(void);

#endif
