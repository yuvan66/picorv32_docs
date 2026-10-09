# PicoRV32 UART Bootloader SoC -- Complete Project Documentation

This document provides a detailed technical reference for all files and directories in the `picorv32_bootloader` repository. It explains the system architecture, memory map, peripheral interfaces, the runtime bootloader protocol, and the purpose and usage of every file.

---

## 1. System Architecture & Memory Map

The system is a bare-metal RISC-V System-on-Chip (SoC) implemented in Verilog for the **Real Digital Boolean Board** featuring the **Xilinx Spartan-7 XC7S50-CSGA324-1** FPGA.

```
       +-------------------------------------------------------------+
       |               PicoRV32 CPU (RV32I Core)                    |
       |  - 100 MHz System Clock (pin F14)                           |
       |  - ENABLE_MUL = 0, ENABLE_DIV = 0 (Pure RV32I)              |
       |  - BARREL_SHIFTER = 0, COMPRESSED_ISA = 0                   |
       |  - Reset PC: 0x0000_0000 (Boots into Boot ROM)              |
       +------------------------------+------------------------------+
                                      | Native Memory Interface
                                      v
       +-------------------------------------------------------------+
       |                    Address Decoder (top.v)                  |
       +---------------+--------------+--------------+---------------+
                       |              |              |
                       v              v              v
         [0x0000_0000 - 0x0000_07FF]  [0x1000_0000 - 0x1000_1FFF]   [0x2000_0000 - 0x3000_0000]
                Boot ROM (2 KB)              App RAM (8 KB)                 Peripherals
            Preloaded with Bootloader     Volatile BRAM for App         UART & LED Registers
```

### Memory and Register Map

| Address Range | Region | Size / Bits | Access | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x0000_0000` – `0x0000_07FF` | **Boot ROM** | 512 × 32-bit (2 KB) | R/W | Resident UART bootloader. Preloaded into FPGA BRAM at synthesis time via `$readmemh("bootloader.hex", bootrom)`. |
| `0x1000_0000` – `0x1000_1FFF` | **Application RAM** | 2048 × 32-bit (8 KB) | R/W | Volatile FPGA BRAM where user applications (`app.bin` / `firmware.bin`) are loaded at runtime over UART. |
| `0x2000_0000` | **UART DATA** | 32-bit (8-bit payload) | R/W | **Read**: Returns `{24'h0, rx_data}` and automatically acknowledges (clears) `rx_valid`.<br>**Write**: Writes `mem_wdata[7:0]` to transmit shift register if `tx_busy == 0`. |
| `0x2000_0004` | **UART STATUS** | 32-bit | R | **Bit 0 (`tx_busy`)**: `1` = UART transmitting, `0` = UART idle / ready for next byte.<br>**Bit 1 (`rx_valid`)**: `1` = unread byte available in DATA register, `0` = empty.<br>**Bits 31:2**: Reserved (`0`). |
| `0x3000_0000` | **LED Register** | 16-bit | R/W | Controls the 16 on-board green LEDs (`led[15:0]`). Supports byte and halfword writes. |
| `0x4000_0000` – `0x4000_0008` | **Hardware Timer** | 32-bit | R/W | • `0x4000_0000` (`TIMER_CNT`): Free-running 32-bit counter (100 MHz clock cycles).<br>• `0x4000_0004` (`TIMER_CMP`): Compare match value (triggers IRQ and match flag).<br>• `0x4000_0008` (`TIMER_CTRL`): Bit 0 = enable, Bit 1 = W1C match/IRQ clear, Bit 2 = match flag. |
| `0x5000_0000` – `0x5000_000C` | **Hardware TRNG** | 32-bit | R/W | • `0x5000_0000` (`TRNG_DATA`): Read pops 32-bit true random word.<br>• `0x5000_0004` (`TRNG_STATUS`): Bit 0 = valid, Bit 1 = health_fail, Bit 4 = warmup_done.<br>• `0x5000_0008` (`TRNG_CTRL`): Bit 0 = EN, Bit 1 = VN_EN, Bit 2 = IRQ_EN, Bit 3 = CLR.<br>• `0x5000_000C` (`TRNG_DIV`): Sample clock divisor (default 255). |

### UART Clocking & Baud Rate
* **System Clock**: 100 MHz oscillator (pin `F14`).
* **Baud Rate**: Fixed at **115200 baud** in RTL.
* **Clocks per Bit**: `CLKS_PER_BIT = 100,000,000 / 115,200 ≈ 868` clock cycles.
* **Format**: 8 data bits, 1 stop bit, no parity (8N1).

---

## 2. Execution Lifecycle & Upload Protocol

1. **Power-On / Reset (`btn_rst` pressed)**:
   - Hardware reset forces the CPU program counter to `0x0000_0000`.
   - The resident bootloader initializes stack pointer `sp` to `0x0000_07FC` (top of Boot ROM).
   - Bootloader sets `LED_REG = 0x0001` (LED 0 ON, waiting for upload).
2. **Firmware Upload (`host/upload.py`)**:
   - Host sends a **4-byte little-endian length** header ($N$).
   - Bootloader sets `LED_REG = 0x0003` (LEDs 0 & 1 ON, receiving).
   - Host sends $N$ raw bytes of compiled application code.
   - Bootloader writes the incoming bytes sequentially to App RAM starting at `0x1000_0000`.
   - Bootloader sets `LED_REG = 0xFFFF` (all 16 LEDs ON, transfer complete).
   - Bootloader sends a single ASCII `'K'` character (0x4B) back to host as an acknowledgment.
3. **Application Execution**:
   - Bootloader executes `((void (*)(void))0x10000000)();`, transferring control to `_start` in the application.
   - Application sets `sp = 0x1000_1FFC` (top of 8 KB App RAM), zeroes the `.bss` section, and invokes `main()`.

---

## 3. Directory and File Breakdown

```
picorv32_bootloader/
├── top.v
├── picorv32.v
├── boolean_bootloader.xdc
├── build.tcl
├── bootloader.hex
├── README.md
├── PROJECT_DOCUMENTATION.md
├── PicoRV32_Bootloader_Boolean_FPGA_Manual.docx
├── dfx_runtime.txt
│
├── bootloader/
│   ├── main.c
│   ├── start.s
│   ├── sections.ld
│   ├── Makefile
│   ├── bootloader.elf
│   ├── bootloader.bin
│   └── bootloader.hex
│
├── app/
│   ├── main.c
│   ├── start.s
│   ├── sections.ld
│   ├── Makefile
│   ├── makehex.py
│   ├── app.elf
│   └── app.bin
│
├── host/
│   └── upload.py
│
└── UART_RX/
    ├── firmware.c
    ├── start.s
    ├── sections.ld
    ├── build_firmware.py
    ├── Makefile
    ├── read_uart.py
    ├── firmware.bin
    ├── firmware.elf
    └── firmware.asm
```

---

### 3.1 Root Directory Files

#### [top.v](file:///c:/Projects/picorv32/picorv32_bootloader/top.v)
* **What it does**: Top-level Verilog RTL module. Integrates the `picorv32` CPU core with Boot ROM (2 KB BRAM), Application RAM (8 KB BRAM), custom memory-mapped UART transceiver (115200 baud), and 16-bit LED driver.
* **Usage**: Main hardware source file synthesized by Vivado.
* **Key RTL Blocks**:
  - `rst_sync`: 2-stage synchronizer converting active-high push button `btn_rst` into active-low `resetn`.
  - `cpu`: PicoRV32 instance configured with `PROGADDR_RESET = 32'h0000_0000`.
  - Address decode: Selects between ROM (`0x0...`), App RAM (`0x1...`), UART (`0x2...`), and LEDs (`0x3...`).
  - UART Transmit Engine: Shift register with start/stop framing clocked at 868 clk/bit.
  - UART Receive Engine: Half-bit center sampler with start-bit edge detection and 8-bit shift register.

#### [picorv32.v](file:///c:/Projects/picorv32/picorv32_bootloader/picorv32.v)
* **What it does**: Complete Claire Wolf / YosysHQ PicoRV32 RISC-V CPU core implementation.
* **Usage**: Instantiated by `top.v`.

#### [boolean_bootloader.xdc](file:///c:/Projects/picorv32/picorv32_bootloader/boolean_bootloader.xdc)
* **What it does**: Xilinx Design Constraints (XDC) file mapping top-level ports to physical pins on the Real Digital Boolean FPGA board:
  - `clk` -> Pin `F14` (100 MHz oscillator)
  - `btn_rst` -> Pin `J2` (Active-high push button)
  - `led[0]` to `led[15]` -> Pins `G1`, `G2`, `F1`, `F2`, `E1`, `E2`, `E3`, `E5`, `E6`, `C3`, `B2`, `A2`, `B3`, `A3`, `B4`, `A4`
  - `UART_rxd` -> Pin `V12` (Host-to-FPGA RX)
  - `UART_txd` -> Pin `U11` (FPGA-to-Host TX)
  - `create_clock -period 10.000` (100 MHz timing constraint)
  - SPI flash configuration settings (`SPIx4`, buswidth 4).
* **Usage**: Consumed by Vivado during implementation and bitstream generation.

#### [build.tcl](file:///c:/Projects/picorv32/picorv32_bootloader/build.tcl)
* **What it does**: Automated Vivado Tcl script that creates project `picorv32_bootloader`, imports `top.v`, `picorv32.v`, `bootloader.hex`, and `boolean_bootloader.xdc`, runs synthesis and implementation, and writes the final bitstream file.
* **Usage**: Executed in Vivado Tcl console:
  ```tcl
  cd {c:/Projects/picorv32/picorv32_bootloader}
  source build.tcl
  ```

#### [bootloader.hex](file:///c:/Projects/picorv32/picorv32_bootloader/bootloader.hex)
* **What it does**: Pre-compiled 512-word hexadecimal representation of the resident bootloader firmware. Loaded directly into `bootrom` by `top.v` via `$readmemh("bootloader.hex", bootrom)`.
* **Usage**: Placed in the top-level directory so Vivado can find it during synthesis.

#### [README.md](file:///c:/Projects/picorv32/picorv32_bootloader/README.md)
* **What it does**: High-level project summary and quickstart guide explaining build order, memory concepts, and differences compared to Arduino flash storage.

#### [PicoRV32_Bootloader_Boolean_FPGA_Manual.docx](file:///c:/Projects/picorv32/picorv32_bootloader/PicoRV32_Bootloader_Boolean_FPGA_Manual.docx)
* **What it does**: Comprehensive step-by-step build and usage manual for the project.

#### [dfx_runtime.txt](file:///c:/Projects/picorv32/picorv32_bootloader/dfx_runtime.txt)
* **What it does**: Vivado run profile timing output from synthesis/implementation.

---

### 3.2 `bootloader/` Directory (Resident Bootloader)

This folder contains the firmware that gets preloaded into the FPGA bitstream at `0x0000_0000`.

#### [bootloader/main.c](file:///c:/Projects/picorv32/picorv32_bootloader/bootloader/main.c)
* **What it does**: Implements the resident bootloader logic:
  1. Sets `LED_REG = 0x0001` (waiting state).
  2. Receives 4 bytes from UART to assemble 32-bit length `len`.
  3. Sets `LED_REG = 0x0003` (receiving state).
  4. Reads `len` bytes from UART and writes each byte to `APP_BASE` (`0x10000000`).
  5. Sets `LED_REG = 0xFFFF` (ready state).
  6. Sends `'K'` (0x4B) acknowledgment byte over UART.
  7. Jumps to `0x10000000` to execute the user application.
* **Usage**: Compiled once and baked into the bitstream.

#### [bootloader/start.s](file:///c:/Projects/picorv32/picorv32_bootloader/bootloader/start.s)
* **What it does**: Bootloader assembly reset vector. Sets stack pointer `sp` to `0x000007FC` (top of 2 KB Boot ROM) and jumps to `main()`.

#### [bootloader/sections.ld](file:///c:/Projects/picorv32/picorv32_bootloader/bootloader/sections.ld)
* **What it does**: Linker script defining the `ROM` memory region at `ORIGIN = 0x00000000, LENGTH = 2K`.

#### [bootloader/Makefile](file:///c:/Projects/picorv32/picorv32_bootloader/bootloader/Makefile)
* **What it does**: Makefile to compile `bootloader.elf`, generate `bootloader.bin`, and convert to `bootloader.hex` using `../app/makehex.py`.

#### `bootloader.elf`, `bootloader.bin`, `bootloader.hex`
* **What they do**: The compiled executable, raw binary, and hex memory file for the resident bootloader.

---

### 3.3 `app/` Directory (Default Application Firmware)

This folder contains the application firmware compiled for execution in Application RAM at `0x1000_0000`.

#### [app/main.c](file:///c:/Projects/picorv32/picorv32_bootloader/app/main.c)
* **What it does**: Application code designed for App RAM. Initializes LEDs, prints diagnostic system information and ASCII banner over UART at 115200 baud, continuously increments an internal counter, updates the 16 LEDs, streams status messages, and provides non-blocking UART character echo.
* **Usage**: Target C code for application development.

#### [app/start.s](file:///c:/Projects/picorv32/picorv32_bootloader/app/start.s)
* **What it does**: Application assembly entry point `_start`:
  - Sets stack pointer `sp = 0x10001FFC` (top of 8 KB App RAM).
  - Iterates from `_sbss` to `_ebss` and zeroes all uninitialized global memory.
  - Calls `main()`.
  - Loops infinitely in `hang` if `main` returns.

#### [app/sections.ld](file:///c:/Projects/picorv32/picorv32_bootloader/app/sections.ld)
* **What it does**: Linker script defining memory region `APPRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 8K`. Guarantees `.text.start` is placed at `0x10000000`.

#### [app/Makefile](file:///c:/Projects/picorv32/picorv32_bootloader/app/Makefile)
* **What it does**: Compiles `start.s` and `main.c` with flags `-march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wl,--build-id=none` to produce `app.elf` and extracts raw binary `app.bin`.

#### [app/makehex.py](file:///c:/Projects/picorv32/picorv32_bootloader/app/makehex.py)
* **What it does**: Utility script that reads a raw 32-bit little-endian binary file and formats each 4-byte word into an 8-character hexadecimal line suitable for Verilog `$readmemh`.

#### `app.elf`, `app.bin`
* **What they do**: Compiled ELF binary and raw binary application image (linked at `0x10000000`).

---

### 3.4 `host/` Directory (Host Upload Tools)

#### [host/upload.py](file:///c:/Projects/picorv32/picorv32_bootloader/host/upload.py)
* **What it does**: Python host upload utility that acts as the "programmer":
  1. Opens the specified serial COM port at 115200 baud.
  2. Reads the specified binary file (`app.bin` or `firmware.bin`).
  3. Sends a 4-byte little-endian length prefix.
  4. Streams the binary payload bytes.
  5. Waits for the `'K'` acknowledgment byte from the board.
* **Usage**:
  ```powershell
  py host\upload.py COM15 UART_RX\firmware.bin
  # or
  py host\upload.py COM15 app\app.bin
  ```

---

### 3.5 `UART_RX/` Directory (Dedicated Firmware & UART Monitoring)

This folder contains the newly rewritten firmware specifically configured for the RTL architecture, along with live monitoring tools and disassembly verification.

#### [UART_RX/firmware.c](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.c)
* **What it does**: Complete C implementation of the application firmware:
  - Memory-mapped definitions matching `top.v`:
    ```c
    #define UART_DATA    (*(volatile uint32_t *)0x20000000)
    #define UART_STATUS  (*(volatile uint32_t *)0x20000004)
    #define LED_REG      (*(volatile uint32_t *)0x30000000)
    ```
  - `uart_putc()`: Polls `UART_STATUS & 0x01` (`tx_busy`) before writing to prevent dropped characters; expands `\n` to `\r\n`.
  - `uart_puts()`: Transmits null-terminated strings.
  - `uart_hasc()`: Checks `UART_STATUS & 0x02` (`rx_valid`) to detect incoming bytes.
  - `uart_getc()`: Reads received character and acknowledges receipt in RTL.
  - Pure RV32I integer formatting (`uart_print_hex32`, `uart_print_hex16`, `uart_print_dec` using shift/subtract to avoid hardware divider or `libgcc` dependencies).
  - Diagnostic LED sequence on startup.
  - Continuous streaming loop with non-blocking UART RX character echo.

#### [UART_RX/start.s](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/start.s)
* **What it does**: Application entry code:
  - Sets stack pointer: `la sp, 0x10001ffc`
  - Zeroes `.bss` section between `_sbss` and `_ebss`.
  - Calls `main()`.

#### [UART_RX/sections.ld](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/sections.ld)
* **What it does**: Custom linker script placing `.text.start` at `0x10000000` and defining symbols `_sbss`, `_ebss`, `_sdata`, `_edata` within the 8 KB App RAM.

#### [UART_RX/build_firmware.py](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/build_firmware.py)
* **What it does**: Automated Python compilation tool:
  - Automatically discovers the RISC-V GCC toolchain (checks `C:\Vivado\2025.1\gnu\riscv\nt\riscv64-unknown-elf\bin` or system PATH).
  - Compiles `start.s` and `firmware.c` with flags `-march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -Wl,--build-id=none`.
  - Converts ELF to flat binary `firmware.bin`.
  - Generates full disassembly file `firmware.asm`.
  - Copies output binary to `app/app.bin` to keep binaries synchronized.
* **Usage**:
  ```powershell
  python UART_RX\build_firmware.py
  ```

#### [UART_RX/Makefile](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/Makefile)
* **What it does**: Linux/WSL makefile for compiling `firmware.bin` and `firmware.asm`.

#### [UART_RX/firmware.bin](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.bin)
* **What it does**: The newly compiled application binary (1868 bytes). Ready to be transmitted directly over UART to App RAM.

#### [UART_RX/firmware.elf](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.elf)
* **What it does**: Linked ELF executable containing debug symbols and section headers.

#### [UART_RX/firmware.asm](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.asm)
* **What it does**: Full disassembly of `firmware.elf` generated via `objdump -d`. Verifies that:
  - `_start` begins exactly at address `0x10000000`.
  - Memory accesses point to `0x20000000` (UART) and `0x30000000` (LEDs).
  - All emitted instructions belong strictly to the base RV32I ISA (no `mul`, `div`, or compressed instructions).

#### [UART_RX/read_uart.py](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/read_uart.py)
* **What it does**: Python serial reader that connects to the FPGA serial port (default: `COM15` at 115200 baud) for 12 seconds and prints received characters in real-time.
* **Usage**:
  ```powershell
  python UART_RX\read_uart.py
  ```

---

## 4. End-to-End Workflow Guide

### Step 1: Program the FPGA Bitstream (Vivado)
1. Ensure `bootloader.hex` is in the project root alongside `top.v`.
2. In Vivado Tcl console, run:
   ```tcl
   cd {c:/Projects/picorv32/picorv32_bootloader}
   source build.tcl
   ```
3. In Vivado Hardware Manager:
   - Auto Connect to target.
   - Program device using generated `.bit` file.
4. **Observe LEDs**:
   - LEDs show `0x0001` (binary `0000000000000001`). The bootloader is alive and waiting for an upload.

---

### Step 2: Build Application Firmware (If Modified)
Run the automated build script from PowerShell:
```powershell
python UART_RX\build_firmware.py
```
This generates `UART_RX\firmware.bin` and updates `app\app.bin`.

---

### Step 3: Upload Application over UART
Run the upload script targeting your board's COM port:
```powershell
py host\upload.py COM15 UART_RX\firmware.bin
```
**LED Behavior During Upload**:
* `0x0001`: Waiting for host.
* `0x0003`: Receiving bytes.
* `0xFFFF`: Transfer finished; sending `'K'` acknowledge and jumping to App RAM.

---

### Step 4: Monitor Serial Output from the Application
Run the reader script:
```powershell
py UART_RX\read_uart.py
```
**Expected Console Output**:
```
Opening COM15 at 115200 baud...
Connected! Live monitoring UART output from FPGA...
==================================================

==================================================
  PicoRV32 SoC on Real Digital Boolean Board
  Xilinx Spartan-7 XC7S50-CSGA324-1 (100 MHz)
==================================================
  Architecture : RV32I Base Integer ISA (no M/C)
  UART Baud    : 115200 baud (868 clocks/bit)
  Boot ROM     : 0x00000000 - 0x000007FF (2 KB)
  App RAM      : 0x10000000 - 0x10001FFF (8 KB)
  UART DATA    : 0x20000000
  UART STATUS  : 0x20000004
  LED Register : 0x30000000 (16-bit)
==================================================
[INFO] Application firmware active in App RAM!
[INFO] Monitoring UART RX and streaming counter...

Hello world! Count: 1 (hex: 0x00000001) | LEDs: 0x0001
Hello world! Count: 2 (hex: 0x00000002) | LEDs: 0x0002
...
```

---

## 5. Troubleshooting & FAQ

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| **LEDs remain stuck at `0x0001`** | Bootloader is waiting and has not received the 4-byte header. | Check Device Manager for the correct COM port. Ensure `upload.py` is targeting that port. |
| **Upload times out waiting for `'K'`** | Baud rate mismatch or FPGA was in an undefined state. | Press `btn_rst` on the board to return to `0x0001`, then re-run `upload.py`. |
| **LEDs flash `0xFFFF` then freeze** | Memory origin mismatch or illegal instruction. | Confirm application was linked with `ORIGIN = 0x10000000` and compiled with `-march=rv32i` (no M extension). |
| **`read_uart.py` says "Access is denied"** | Another program (terminal or previous script) is holding the COM port. | Close PuTTY, Tera Term, Serial Monitor, or previous Python instances before running `read_uart.py`. |
