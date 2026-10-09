TOOLCHAIN_PREFIX ?= riscv-none-elf-

CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall
LDFLAGS = -T sections.ld -Wl,--build-id=none

all: app.bin

app.elf: start.s main.c sections.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o app.elf start.s main.c

app.bin: app.elf
	$(OBJCOPY) -O binary app.elf app.bin

clean:
	rm -f app.elf app.bin

.PHONY: all clean
