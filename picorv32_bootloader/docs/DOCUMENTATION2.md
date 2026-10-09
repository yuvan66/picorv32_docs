# PicoRV32 Bootloader & SoC Diagnostics -- Technical Reference & Resolution Guide
**Document:** `DOCUMENTATION2.md`  
**Date:** October 9, 2026  
**Target Board:** Real Digital Boolean (Xilinx Spartan-7 XC7S50-CSGA324-1)

---

## 1. Summary of Problems Diagnosed & Rectified

### Problem 1: Inverted Reset Logic in `timer.v` Causing Bus Freeze
- **The Issue**: In `timer.v` line 94, the reset condition was written as:
  ```verilog
  if (!reset) begin   // Inverted! Active whenever reset == 0
      ...
      ready <= 1'b0;
  end
  ```
- **Consequence**: Since `reset` is active-high (`reset = ~resetn`), during normal operation (`reset == 0`), `!reset` evaluated to `1`. The hardware timer remained permanently in reset and **`ready` was never asserted**.
- When the application firmware attempted to read `TIMER_CNT` at `0x4000_0000`, the PicoRV32 native memory interface stalled waiting for `ready`, freezing the CPU and halting all further UART prints.
- **The Fix**: Corrected line 94 of [timer.v](file:///c:/Projects/picorv32/picorv32_bootloader/timer.v) to:
  ```verilog
  if (reset) begin
  ```

---

### Problem 2: Missing Files in `build.tcl`
- **The Issue**: In [build.tcl](file:///c:/Projects/picorv32/picorv32_bootloader/build.tcl), the file list only included `top.v` and `picorv32.v`.
- **The Fix**: Updated `build.tcl` to include all modules:
  ```tcl
  add_files -norecurse {top.v picorv32.v timer.v trng.v}
  ```

---

### Problem 3: Negative Setup Slack Timing Violation (-2.414 ns)
- **The Issue**: The 16 ring oscillators in `trng.v` are asynchronous entropy sources with 33-inverter loops (~12.4 ns delay). Vivado attempted to time them as synchronous 100 MHz paths into `sync1_reg[*]`, causing a `-2.414 ns` setup violation.
- **The Fix**: Added false-path and DRC constraints to [boolean_bootloader.xdc](file:///c:/Projects/picorv32/picorv32_bootloader/boolean_bootloader.xdc):
  ```tcl
  set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]
  set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_trng*sync1_reg*}]
  ```
- **Timing Result**: Implementation completed with **positive slack**:
  - **WNS**: `+1.586 ns`
  - **TNS**: `0.000 ns` (Zero failing endpoints)

---

### Problem 4: Vivado Programming Error (`spi_xc7s50_pullnone.bit` Not Found)
- **The Issue**: Vivado 2025.1 left `spi_xc7s50_pullnone.bit` compressed inside `bitfile.zip`. Additionally, the configuration memory device (SPI flash) was selected instead of programming the FPGA SRAM device (`xc7s50_0`).
- **The Fix**: Extracted `spi_xc7s50_pullnone.bit` to `C:\Vivado\2025.1\Vivado\data\xicom\cfgmem\`, and programmed `top.bit` directly into the `xc7s50_0` FPGA device.

---

## 2. Hardware Verification & Live UART Stream

After recompiling the bitstream with positive timing slack (`WNS = +1.586 ns`), programming the FPGA, and uploading [UART_RX/firmware.bin](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.bin), the UART output was captured via [UART_RX/read_uart.py](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/read_uart.py):

```text
Opening COM15 at 115200 baud...
Connected! Live monitoring UART output from FPGA...
==================================================
[REPORT #60] Cycles: 8010473 | TRNG: 0x0E307074 | LEDs: 0x7074
[REPORT #61] Cycles: 2670672 | TRNG: 0xCEA5E29F | LEDs: 0xE29F
[REPORT #62] Cycles: 7330869 | TRNG: 0xC28B390F | LEDs: 0x390F
[REPORT #63] Cycles: 1991105 | TRNG: 0x8E256F4A | LEDs: 0x6F4A
[REPORT #64] Cycles: 6651306 | TRNG: 0xC9168040 | LEDs: 0x8040
[REPORT #65] Cycles: 1311510 | TRNG: 0xC913479F | LEDs: 0x479F
[REPORT #66] Cycles: 5971688 | TRNG: 0x4E12E7A6 | LEDs: 0xE7A6
[REPORT #67] Cycles: 631911  | TRNG: 0x6B2FD9B5 | LEDs: 0xD9B5
...
[REPORT #140] Cycles: 1124213 | TRNG: 0xAB8D43E2 | LEDs: 0x43E2
[REPORT #141] Cycles: 5793090 | TRNG: 0xDF284C72 | LEDs: 0x4C72
==================================================
[SUCCESS] Total UART bytes received: 5367
```

**Verification Results**:
- **32-Bit Timer (`0x4000_0000`)**: Running at 100 MHz, free-running counter incrementing on every cycle.
- **TRNG (`0x5000_0000`)**: Entropy generation active, producing distinct 32-bit random words.
- **LEDs (`0x3000_0000`)**: Displaying the lower 16 bits of each fresh TRNG word.
- **UART Transceiver (`0x2000_0000`)**: Transmitting 115200 baud stream continuously without dropped frames.

---

## 3. Operational Workflow & Commands

### Step 1: Program the FPGA Bitstream
If you ever power-cycle the board or need to re-program:
```powershell
# Using the automated Vivado batch programmer:
$tcl = @"
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
current_hw_device [get_hw_devices xc7s50_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7s50_0] 0]
set_property PROGRAM.FILE {C:/Projects/picorv32/picorv32_bootloader/picorv32_bootloader_proj/picorv32_bootloader.runs/impl_1/top.bit} [get_hw_devices xc7s50_0]
program_hw_devices [get_hw_devices xc7s50_0]
close_hw_target
disconnect_hw_server
close_hw_manager
"@
$tcl | Out-File -Encoding ASCII program.tcl
& "C:\Vivado\2025.1\Vivado\bin\vivado.bat" -mode batch -nolog -nojournal -source program.tcl
Remove-Item program.tcl
```
*(On the Boolean board, LED 0 will light up `0x0001`, signaling the bootloader is ready)*.

---

### Step 2: Build the Firmware (When Changing C Code)
```powershell
python UART_RX\build_firmware.py
```
This compiles [UART_RX/firmware.c](file:///c:/Projects/picorv32/picorv32_bootloader/UART_RX/firmware.c) with the RISC-V toolchain (`-march=rv32i -mabi=ilp32`) and generates `UART_RX/firmware.bin`.

---

### Step 3: Upload Firmware via Serial Port
If the board is already running an earlier app, **press the physical `btn_rst` button** to return to the bootloader (`0x0001`), then run:
```powershell
python host\upload.py COM15 UART_RX\firmware.bin
```
**Console Output**:
```
App image: UART_RX/firmware.bin (3524 bytes)
Sending length header...
Sending application bytes...
Waiting for acknowledgement...
Upload confirmed -- application should now be running.
```

---

### Step 4: Monitor Serial Output
```powershell
python UART_RX\read_uart.py
```
Outputs live cycle counts from the 100 MHz Hardware Timer and random words from the TRNG.
