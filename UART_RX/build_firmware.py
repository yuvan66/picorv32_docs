#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

C_SRC = os.path.join(SCRIPT_DIR, "firmware.c")
S_SRC = os.path.join(SCRIPT_DIR, "start.s")
LDS_SRC = os.path.join(SCRIPT_DIR, "sections.ld")
ELF_OUT = os.path.join(SCRIPT_DIR, "firmware.elf")
BIN_OUT = os.path.join(SCRIPT_DIR, "firmware.bin")
DUMP_OUT = os.path.join(SCRIPT_DIR, "firmware.asm")

VIVADO_GCC = r"C:\Vivado\2025.1\gnu\riscv\nt\riscv64-unknown-elf\bin\riscv64-unknown-elf-gcc.exe"
VIVADO_OBJCOPY = r"C:\Vivado\2025.1\gnu\riscv\nt\riscv64-unknown-elf\bin\riscv64-unknown-elf-objcopy.exe"
VIVADO_OBJDUMP = r"C:\Vivado\2025.1\gnu\riscv\nt\riscv64-unknown-elf\bin\riscv64-unknown-elf-objdump.exe"

def find_tool(name, vivado_path):
    if os.path.exists(vivado_path):
        return vivado_path
    for prefix in ["riscv64-unknown-elf-", "riscv-none-elf-", "riscv32-unknown-elf-"]:
        candidate = shutil.which(prefix + name)
        if candidate:
            return candidate
    which = shutil.which(name)
    if which and "riscv" in which:
        return which
    return None

def main():
    gcc = find_tool("gcc", VIVADO_GCC)
    objcopy = find_tool("objcopy", VIVADO_OBJCOPY)
    objdump = find_tool("objdump", VIVADO_OBJDUMP)

    if not gcc or not objcopy:
        print("[ERROR] Could not find RISC-V GCC / objcopy toolchain.")
        sys.exit(1)

    print(f"[TOOL] Using GCC:     {gcc}")
    print(f"[TOOL] Using objcopy: {objcopy}")

    cmd_compile = [
        gcc,
        "-march=rv32i",
        "-mabi=ilp32",
        "-O2",
        "-ffreestanding",
        "-nostdlib",
        "-Wl,--build-id=none",
        "-T", LDS_SRC,
        "-o", ELF_OUT,
        S_SRC,
        C_SRC
    ]

    print("\n[BUILD] Compiling firmware...")
    res = subprocess.run(cmd_compile, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[FAIL] Compilation failed:\n{res.stderr}\n{res.stdout}")
        sys.exit(res.returncode)
    print("  Compiled firmware.elf successfully.")

    cmd_bin = [objcopy, "-O", "binary", ELF_OUT, BIN_OUT]
    res_bin = subprocess.run(cmd_bin, capture_output=True, text=True)
    if res_bin.returncode != 0:
        print(f"[FAIL] Binary conversion failed:\n{res_bin.stderr}")
        sys.exit(res_bin.returncode)

    bin_size = os.path.getsize(BIN_OUT)
    print(f"  Generated {BIN_OUT} ({bin_size} bytes / max 8192 bytes for App RAM).")

    if objdump:
        with open(DUMP_OUT, "w") as f:
            subprocess.run([objdump, "-d", ELF_OUT], stdout=f)
        print(f"  Disassembly saved to {DUMP_OUT}.")

    app_dir = os.path.join(PROJECT_DIR, "app")
    if os.path.exists(app_dir):
        app_bin = os.path.join(app_dir, "app.bin")
        shutil.copyfile(BIN_OUT, app_bin)
        print(f"  Synced binary to {app_bin}.")

    print("\n[SUCCESS] firmware.bin is ready for upload!")

if __name__ == "__main__":
    main()
