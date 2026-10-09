# PicoRV32 Bare-Metal Firmware Build, Flash & Driver Manual
**Platform**: Real Digital Boolean Board (Xilinx Spartan-7 `XC7S50-CSGA324-1`)  
**Processor**: PicoRV32 (Pure RV32I Core @ 100 MHz)  
**Document**: `FIRMWARE_BUILD_AND_FLASH_MANUAL.md`

---

## 1. Overview & Execution Model

The system runs a **Resident Bootloader Execution Model**:
1. **Boot ROM (`0x0000_0000` - `0x0000_07FF`)**: Preloaded in FPGA Block RAM during synthesis. Contains the resident UART bootloader.
2. **Application RAM (`0x1000_0000` - `0x1000_1FFF`)**: 8 KB volatile Block RAM. Your application (`app.bin`) is loaded here dynamically at runtime over USB-UART in ~1.5 seconds without re-running Vivado.

```
                           +-------------------------------------+
                           |      Boolean Board (Spartan-7)      |
                           |                                     |
                           |   +------------------------------+  |
                           |   |      PicoRV32 CPU Core       |  |
                           |   |      RV32I Base ISA @ 100MHz |  |
                           |   +---------------+--------------+  |
                           +-------------------|-----------------+
                                               |
                          Native Memory Bus    | (32-bit addr/data)
                                               v
+---------------------------------------------------------------------------------------------------+
| 0x0000_0000 (2KB) | 0x1000_0000 (8KB) | 0x2000_0000   | 0x3000_0000 | 0x4000_0000   | 0x5000_0000 |
| Boot ROM          | Application RAM   | UART Engine   | 16-bit LEDs | HW Timer      | HW TRNG     |
| (Resident Loader) | (Your app.bin)    | 115200 Baud   | 16 Green    | 32-bit 100MHz | 16 Ring Osc |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Structure & File Map

```
picorv32_bootloader/
├── app/                      <-- Your Modular Driver Application
│   ├── soc_regs.h            <-- Memory-mapped base addresses & register macros
│   ├── led.h / led.c         <-- 16-bit LED control driver
│   ├── uart.h / uart.c       <-- 115200 baud UART TX/RX driver
│   ├── timer.h / timer.c     <-- 100 MHz 32-bit Hardware Timer driver
│   ├── trng.h / trng.c       <-- True Random Number Generator driver
│   ├── main.c                <-- Main application testing all peripherals
│   ├── start.s               <-- Startup assembly (sp=0x10001ffc, .bss zeroing)
│   ├── sections.ld           <-- Linker script (origin: 0x10000000, length: 8K)
│   ├── Makefile              <-- Automated build script
│   ├── app.elf               <-- Linked RISC-V ELF binary
│   ├── app.bin               <-- Final raw machine code (uploaded to board)
│   └── app.asm               <-- Complete disassembly listing
│
├── host/
│   └── upload.py             <-- Python host loader (sends app.bin over UART)
│
└── UART_RX/
    ├── read_uart.py          <-- Python live serial telemetry viewer
    └── build_firmware.py     <-- Alternative Python automated builder
```

---

## 3. Peripheral Driver API Reference

### 3.1 Hardware Register Map (`soc_regs.h`)
All registers are accessed via `volatile uint32_t *` pointers:
```c
// UART (Base: 0x20000000)
#define REG_UART_DATA     (*(volatile uint32_t *)0x20000000)
#define REG_UART_STATUS   (*(volatile uint32_t *)0x20000004)
#define UART_STAT_TX_BUSY (1U << 0)
#define UART_STAT_RX_VALID (1U << 1)

// LEDs (Base: 0x30000000)
#define REG_LEDS          (*(volatile uint32_t *)0x30000000)

// 32-bit Hardware Timer (Base: 0x40000000)
#define REG_TIMER_CNT     (*(volatile uint32_t *)0x40000000)
#define REG_TIMER_CMP     (*(volatile uint32_t *)0x40000004)
#define REG_TIMER_CTRL    (*(volatile uint32_t *)0x40000008)

// Hardware TRNG (Base: 0x50000000)
#define REG_TRNG_DATA     (*(volatile uint32_t *)0x50000000)
#define REG_TRNG_STATUS   (*(volatile uint32_t *)0x50000004)
#define REG_TRNG_CTRL     (*(volatile uint32_t *)0x50000008)
#define REG_TRNG_DIV      (*(volatile uint32_t *)0x5000000C)
```

---

### 3.2 LED Driver (`led.h` / `led.c`)
Controls the 16 on-board green LEDs (`led[15:0]` on pins `G1` to `A4`):
* `void led_set(uint16_t value)` — Writes a 16-bit pattern to all 16 LEDs.
* `void led_toggle(uint16_t mask)` — Inverts the state of masked LEDs.
* `void led_set_bit(uint8_t bit)` — Sets a single LED (0 to 15) high.
* `void led_clear_bit(uint8_t bit)` — Clears a single LED (0 to 15) low.

---

### 3.3 UART Driver (`uart.h` / `uart.c`)
Operates at **115200 baud, 8N1** (868 clock cycles per bit @ 100MHz):
* `void uart_putc(char c)` — Transmits a single character (waits if TX is busy).
* `void uart_puts(const char *str)` — Transmits a null-terminated string (auto-converts `\n` to `\r\n`).
* `bool uart_available(void)` — Returns `true` if an unread character is available in the RX FIFO.
* `char uart_getc(void)` — Blocks until a byte is received and returns it.
* `void uart_print_hex32(uint32_t val)` — Formats and prints a 32-bit value in hexadecimal (`0xXXXXXXXX`).
* `void uart_print_dec(uint32_t val)` — Formats and prints an unsigned decimal integer using software shift-and-subtract (pure RV32I, zero hardware `div` instructions).

---

### 3.4 Hardware Timer Driver (`timer.h` / `timer.c`)
Interfaces with the single-cycle 32-bit counter running at 100 MHz:
* `void timer_init(void)` — Enables the timer module (`REG_TIMER_CTRL = 0x01`).
* `uint32_t timer_get_cycles(void)` — Reads current 32-bit counter (increments every 10 ns).
* `void timer_delay_cycles(uint32_t cycles)` — Performs a non-freezing cycle delay using timer comparisons (e.g. 50,000,000 cycles = 0.5 seconds).

---

### 3.5 TRNG Driver (`trng.h` / `trng.c`)
Interfaces with the 16 ring oscillators and hardware Von Neumann de-biaser:
* `void trng_init(void)` — Enables TRNG oscillators and Von Neumann filter (`REG_TRNG_CTRL = 0x03`).
* `bool trng_is_warm(void)` — Returns `true` once the 1024-sample initial warmup is complete (`bit 4`).
* `bool trng_has_data(void)` — Returns `true` when a valid 32-bit random word is ready in the FIFO (`bit 0`).
* `uint32_t trng_read(void)` — Waits for `trng_has_data()` and pops a fresh 32-bit physical random word.

---

## 4. End-to-End Build, Flash & Run Workflow

### Step 1: Build the Firmware (`app.bin`)

In your Linux terminal:
```bash
cd "/home/yuvan66/Documents/picorv32_bootloader(1)/picorv32_bootloader/app"
make clean
make
```

**Expected Build Output:**
```text
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o start.o start.s
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o main.o main.c
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o led.o led.c
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o uart.o uart.c
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o timer.o timer.c
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wall -Wextra -c -o trng.o trng.c
riscv64-unknown-elf-gcc ... -T sections.ld -o app.elf start.o main.o led.o uart.o timer.o trng.o
riscv64-unknown-elf-objcopy -O binary app.elf app.bin
[SUCCESS] Generated app.bin (1580 bytes)
```

---

### Step 2: Flash / Upload to Boolean Board over UART

1. **Reset into Bootloader**:  
   Press the physical **`btn_rst`** push button (Pin `J2`) on the Boolean board.  
   *(On the board, **LED 0 will illuminate `0x0001`**, signaling that the resident bootloader is waiting for an upload)*.

2. **Upload the Binary**:  
   Find your USB-serial port (e.g. `/dev/ttyUSB0` or `/dev/ttyUSB1`):
   ```bash
   ls /dev/ttyUSB*
   ```
   Run the upload script:
   ```bash
   python3 "/home/yuvan66/Documents/picorv32_bootloader(1)/picorv32_bootloader/host/upload.py" /dev/ttyUSB0 "/home/yuvan66/Documents/picorv32_bootloader(1)/picorv32_bootloader/app_nr/app.bin"
   ```

**Expected Upload Output:**
```text
App image: app/app.bin (1580 bytes)
Sending length header...
Sending application bytes...
Waiting for acknowledgement...
Upload confirmed -- application should now be running.
```

---

### Step 3: View Live Serial Output

Monitor the UART stream live from the board at 115200 baud:
```bash
python3 "/home/yuvan66/Documents/picorv32_bootloader(1)/picorv32_bootloader/UART_RX/read_uart.py"
```

**Live Output Captured from Board:**
```text
======================================================
   PicoRV32 Modular Driver Suite & Security Token   
   Board: Real Digital Boolean (Spartan-7 @ 100MHz) 
======================================================

Waiting for TRNG warm-up (1024 entropy samples)...
[PASS] TRNG is warmed up and active!

[SAMPLE #1] Timer: 498214 cycles | TRNG: 0xCEA5E29F | LEDs: 0xE29F
[SAMPLE #2] Timer: 50498214 cycles | TRNG: 0xC28B390F | LEDs: 0x390F
[SAMPLE #3] Timer: 100498214 cycles | TRNG: 0x8E256F4A | LEDs: 0x6F4A
[SAMPLE #4] Timer: 150498214 cycles | TRNG: 0xC9168040 | LEDs: 0x8040
```

---

## 5. Verification Checklist

| Test Item | Verification Method | Status |
| :--- | :--- | :--- |
| **Toolchain & Compiler** | Compiled with `riscv64-unknown-elf-gcc` (`-march=rv32i -mabi=ilp32`) | **PASS** |
| **Binary Footprint** | Binary size: 1,580 bytes (Well within 8,192 byte App RAM limit) | **PASS** |
| **Linker Address Alignment** | Origin set to `0x10000000`, Stack initialized to `0x10001FFC` | **PASS** |
| **16-bit LEDs (`0x30000000`)** | Live pattern updates mirroring lower 16 bits of TRNG (`0x50000000`) | **PASS** |
| **100MHz Timer (`0x40000000`)** | Cycle delta verifies continuous incrementing at 10 ns / tick | **PASS** |
| **TRNG (`0x50000000`)** | Warmup bit 4 asserts; generates 32-bit physical random words | **PASS** |
| **UART TX/RX (`0x20000000`)** | Continuous telemetry transmission and interactive character echo | **PASS** |
