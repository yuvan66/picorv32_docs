CROSS ?= riscv64-unknown-elf-
CC = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra
LDFLAGS = -T sections.ld -Wl,--build-id=none

SRCS = start.s main.c led.c uart.c timer.c trng.c
OBJS = start.o main.o led.o uart.o timer.o trng.o

all: app.bin

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<

app.elf: $(OBJS) sections.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

app.bin: app.elf
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -d $< > app.asm
	@echo "[SUCCESS] Generated app.bin ($$(wc -c < app.bin) bytes)"

clean:
	rm -f *.o app.elf app.bin app.asm

.PHONY: all clean
