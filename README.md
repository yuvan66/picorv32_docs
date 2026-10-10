# PicoRV32 RISC-V SoC & Hardware 2FA Security Token

A bare-metal RISC-V System-on-Chip (SoC) synthesized for the **AMD / Xilinx Spartan-7** FPGA on the **Real Digital Boolean Board**. The design couples Claire Wolf's 32-bit `PicoRV32` core with custom hardware peripherals, a resident UART bootloader, a hardware True Random Number Generator (TRNG), and an I2C master controller driving a 1.3" OLED display.

---

## Architecture Overview

```
+-----------------------------------------------------------------------------------------+
|                                  PicoRV32 Core (100 MHz)                                |
|   - RV32I Base Integer Instruction Set (32 registers, x0 - x31)                         |
|   - Native Single-Cycle Memory Bus (mem_valid, mem_ready, mem_wstrb, mem_addr)          |
|   - Reset Vector: 0x0000_0000 (Resident Bootloader in Boot ROM)                         |
+-----------------------------------------------------------------------------------------+
                                              |
                   32-bit Memory-Mapped I/O Bus (mem_addr[31:28] decoding)
                                              |
     +------------------+------------------+--+----------------+-------------------+
     |                  |                  |                   |                   |
0x0000_0000        0x1000_0000        0x2000_0000         0x3000_0000         0x4000_0000
 Boot ROM           App RAM            UART 8N1            16x LEDs            32-bit Timer
 (2 KB Resident)    (8 KB Runtime)     (115,200 Baud)      (Active-High)       (10 ns Ticks)
                                              |                   |
                                         0x5000_0000         0x6000_0000
                                          TRNG (Entropy)      I2C Master
                                         (16 Ring Osc)       (100k / 400k)
                                                                  |
                                                           1.3" OLED (SH1106)
                                                           (128x64 @ 0x78/0x3C)
```

### System Specs
- **FPGA Target**: AMD Spartan-7 `XC7S50-CSGA324-1` (Real Digital Boolean Board)
- **Primary Clock**: 100.00 MHz oscillator (`T_clk = 10.0 ns`, Pin `F14`)
- **CPU ISA**: Pure `RV32I` (Little-endian, 32-bit word aligned)
- **Timing Closure**: Setup Slack (WNS) = `+1.586 ns`, Hold Slack (WHS) = `+0.052 ns` (0 failing endpoints)
- **Execution Model**: Resident UART Bootloader in 2 KB Block RAM; runtime firmware dynamically loaded into 8 KB volatile App RAM without requiring Vivado resynthesis.

---

## Memory Map

Peripheral selection is decoded from the top nibble of the address bus (`mem_addr[31:28]`):

| Base Address | Size | Region Name | Access | Hardware Function |
|:---|:---:|:---|:---:|:---|
| `0x0000_0000` | 2 KB | **Boot ROM** | R/W | Resident UART bootloader (`bootloader.hex`). Runs on reset. |
| `0x1000_0000` | 8 KB | **App RAM** | R/W | Volatile dual-port SRAM holding firmware and stack (`sp = 0x1000_1FFC`). |
| `0x2000_0000` | 8 B | **UART** | R/W | 115,200 Baud 8N1 transceiver (pins `U11` TX, `V12` RX). |
| `0x3000_0000` | 4 B | **LEDs** | R/W | 16-bit register driving onboard LEDs (`LD0` – `LD15`). |
| `0x4000_0000` | 12 B | **Timer** | R/W | 32-bit hardware counter running at 100 MHz (10 ns resolution) with compare match. |
| `0x5000_0000` | 16 B | **TRNG** | R/W | 16-ring-oscillator entropy source with von Neumann de-biasing & NIST SP 800-90B tests. |
| `0x6000_0000` | 24 B | **I2C Master** | R/W | Programmable single-master controller (100k/400k) driving 1.3" I2C OLED display. |

---

## Peripheral Subsystems

### 1. Hardware TRNG (`0x5000_0000`)
- **Entropy Harvester**: 16 asynchronous, odd-length ring oscillator feedback loops with prime inverter counts to generate jitter-induced phase drift.
- **Post-Processing**: Hardware von Neumann de-biasing (converts bit pairs `01` $\to$ `0`, `10` $\to$ `1`, discards `00`/`11`).
- **NIST SP 800-90B Health Tests**: Real-time Repetition Count Test (RCT) and Adaptive Proportion Test (APT) running directly in hardware.
- **Registers**:
  - `TRNG_DATA` (`0x00`): 32-bit random output. Popping read (clears `DATA_VALID`).
  - `TRNG_STATUS` (`0x04`): Bits: `0:VALID`, `1:HEALTH_FAIL`, `2:RCT_FAIL`, `3:APT_FAIL`, `4:WARMUP_DONE`.
  - `TRNG_CTRL` (`0x08`): Bits: `0:EN`, `1:VN_EN`, `2:IRQ_EN`, `3:CLR`.

### 2. I2C Master Controller (`0x6000_0000`)
- **Clock Prescaler**:
  $$\text{Prescale} = \frac{100\text{ MHz}}{4 \times f_{scl}} - 1$$
  - `249` (`0x00F9`): Standard-mode (100 kHz)
  - `62` (`0x003E`): Fast-mode (400 kHz)
- **Features**: Automated clock stretching, arbitration detection, bus-busy detection, open-drain pin drive.
- **Registers**:
  - `I2C_PRESCALE` (`0x00`): 16-bit clock divisor.
  - `I2C_CTRL` (`0x04`): Core enable (`EN = bit 0`) and IRQ enable (`bit 1`).
  - `I2C_TXDATA` (`0x08`): 8-bit byte to transmit.
  - `I2C_RXDATA` (`0x0C`): 8-bit byte received from slave.
  - `I2C_CMD` (`0x10`): Command trigger (`STA`, `STO`, `WR`, `RD`, `NACK`).
  - `I2C_STATUS` (`0x14`): Status flags (`BUSY`, `DONE`, `RXNACK`, `ARB_LOST`, `BUS_BUSY`, `CMD_ERR`, `SCL`, `SDA`).

### 3. 1.3" I2C OLED Display (SH1106 / SSD1306)
- **Resolution**: 128 &times; 64 monochrome pixels (8 pages &times; 128 columns).
- **Address Notation**:
  - Silk-screen `0x78` on the module indicates the 8-bit write byte. In standard 7-bit I2C notation, this is `0x3C` (`0x78 >> 1 = 0x3C`).
  - Alternate silk-screen `0x7A` is 7-bit address `0x3D`.
  - The driver auto-probes both addresses on startup.
- **Column Offset**: SH1106 controller internal RAM is 132 columns wide; the 128-column screen is centered with a 2-pixel margin. The driver compensates by setting column offsets to `col + 2`.
- **Driver API**: High-level C11 `_Generic` interface supporting both strings and integers:
  ```c
  disp_init();                 // Probes bus and configures OLED
  disp_set_cursor(0, 0);       // Page 0, Column 0
  disp("PicoRV32 SoC");        // Prints string
  disp_set_cursor(2, 0);
  disp("Loop: ");
  disp(counter);               // Prints integer value
  ```

---

## 2FA Challenge-Response Protocol

The firmware implements a physical hardware security token communicating with the host PC via UART:

```
    [ Host PC (otp_portal.py) ]                   [ PicoRV32 SoC Hardware ]
                 |                                           |
                 |                                           | 1. Sample 4x 32-bit TRNG words
                 |                                           | 2. Compute local 6-digit OTP
                 |   CHALLENGE:<32-hex-characters>\r\n       |    via SipHash-2/4 + Mod 10^6
                 |<------------------------------------------| 3. Render on 1.3" OLED: "LOCKED"
                 |                                           |
4. Calculate     |                                           |
   SipHash-2/4   |                                           |
   over nonce    |                                           |
5. Send OTP      |   PIN:<6-digit-pin>\r\n                   |
                 |------------------------------------------>| 6. Validate received PIN
                 |                                           |    against expected PIN
                 |   STATUS:ACCESS_GRANTED\r\n               | 7. Match: Turn ON all LEDs,
                 |<------------------------------------------|    render "UNLOCKED" on OLED
                 |                                           |    (Mismatch: STATUS:ACCESS_DENIED)
```

- **Cryptographic Primitive**: SipHash-2/4 PRF with 128-bit pre-shared symmetric key (`SECRET_KEY_0 = 0x0123456789ABCDEF`, `SECRET_KEY_1 = 0xFEDCBA9876543210`).
- **Safety**: Fully implemented using 32-bit shift-and-subtract operations without reliance on hardware multiplication or division instructions.

---

## Quickstart & Demonstration

### Prerequisites
- **Cross-Compiler**: `riscv64-unknown-elf-gcc` or `riscv32-unknown-elf-gcc` (with `-march=rv32i -mabi=ilp32`)
- **Python**: Python 3.8+ with `pyserial` and `tkinter` (`pip install pyserial`)

### 1. Build Firmware
```bash
cd app
make clean && make
```
This produces `app.bin` (6,608 bytes), fitting within the 8,192 byte App RAM boundary.

### 2. Upload to Boolean Board
1. Connect the Real Digital Boolean board to your PC via micro-USB.
2. Press push button **`btn_rst`** (Pin `J2`) on the board. LED 0 will light up (`0x0001`), indicating the resident bootloader is listening.
3. Upload the binary:
   ```bash
   # On Linux:
   python3 host/upload.py /dev/ttyUSB0 app/app.bin

   # On Windows:
   python host\upload.py COM4 app\app.bin
   ```
4. Upon transfer completion, the bootloader verifies the image and jumps to `0x1000_0000`.

### 3. Launch the PC 2FA Authentication Portal
```bash
python3 host/otp_portal.py
```
1. Select your serial port (`115,200 Baud`) and click **Connect**.
2. The board generates a physical 128-bit TRNG challenge and sends it over UART while displaying `LOCKED` on the 1.3" OLED.
3. The PC Portal derives the SipHash OTP and transmits `PIN:XXXXXX`.
4. The board verifies the PIN, responds with `STATUS:ACCESS_GRANTED`, turns on all 16 LEDs, and updates the OLED screen to `ACCESS GRANTED / UNLOCKED`.

---

## Repository Structure

```
picorv32_bootloader/
├── app/                              # Application Firmware (RV32I)
│   ├── main.c                        # 2FA Challenge-Response application logic
│   ├── i2c.h / i2c.c                 # I2C Master peripheral driver
│   ├── display.h / display.c         # 1.3" OLED (SH1106/SSD1306) driver & 6x8 font
│   ├── uart.h / uart.c               # 115200 Baud UART driver
│   ├── timer.h / timer.c             # 100 MHz 32-bit hardware timer driver
│   ├── trng.h / trng.c               # Hardware TRNG driver
│   ├── led.h / led.c                 # 16-bit GPIO LED driver
│   ├── soc_regs.h                    # Memory map register base addresses & bitmasks
│   ├── start.s                       # Startup assembly (stack initialization & .bss clear)
│   ├── sections.ld                   # Linker script (origin: 0x10000000, size: 8K)
│   ├── Makefile                      # Firmware compilation script
│   └── app.bin                       # Compiled application binary payload
│
├── bootloader/                       # Resident Bootloader (baked into Boot ROM)
│   ├── main.c                        # Serial frame loader protocol
│   └── bootloader.hex                # Synthesis hex memory image for $readmemh
│
├── host/                             # Host PC Software
│   ├── upload.py                     # Serial bootloader upload client
│   └── otp_portal.py                 # Tkinter 2FA GUI Authentication Portal
│
├── docs/                             # Technical Documentation & Review Decks
│   ├── PicoRV32_SoC_Peripheral_Datasheet.html  # Complete peripheral register datasheet
│   ├── presentation_deck.html        # Interactive 8-slide presentation deck (keyboard nav)
│   ├── project_review_presentation.html        # System architecture specification
│   └── FIRMWARE_BUILD_AND_FLASH_MANUAL.md      # Detailed flashing reference manual
│
├── top.v                             # Top-level Verilog interconnect & peripheral muxing
├── picorv32.v                        # Claire Wolf's PicoRV32 RISC-V core
├── trng.v                            # Hardware TRNG module (16 ring oscillators)
├── timer.v                           # 32-bit hardware timer with compare match
├── boolean_bootloader.xdc            # FPGA physical pin constraints (Spartan-7)
├── build.tcl                         # Vivado synthesis and implementation script
└── EMBEDDED_PROGRAMMERS_MANUAL.md    # Low-level hardware & peripheral manual
```

---

## Documentation & Presentation Materials

- **Peripheral Register Datasheet**: [`docs/PicoRV32_SoC_Peripheral_Datasheet.html`](docs/PicoRV32_SoC_Peripheral_Datasheet.html)  
  *Complete register maps, bitfield tables, prescaler formulas, and timing characteristics.*
- **Interactive Review Presentation Deck**: [`docs/presentation_deck.html`](docs/presentation_deck.html)  
  *8-slide presentation deck formatted for technical reviews. Navigate with arrow keys or spacebar.*
- **Low-Level Programmer's Manual**: [`EMBEDDED_PROGRAMMERS_MANUAL.md`](EMBEDDED_PROGRAMMERS_MANUAL.md)  
  *Architectural specifications and bare-metal programming guidelines.*
