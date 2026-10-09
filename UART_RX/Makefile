TOOLCHAIN_PREFIX ?= /mnt/c/Vivado/2025.1/gnu/riscv/nt/riscv64-unknown-elf/bin/riscv64-unknown-elf-

CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall
LDFLAGS = -T sections.ld -Wl,--build-id=none

all: firmware.bin firmware.asm

firmware.elf: start.s firmware.c sections.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o firmware.elf start.s firmware.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

firmware.asm: firmware.elf
	$(OBJDUMP) -d firmware.elf > firmware.asm

clean:
	rm -f firmware.elf firmware.bin firmware.asm

.PHONY: all clean
