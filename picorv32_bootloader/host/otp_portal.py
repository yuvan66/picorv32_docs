#!/usr/bin/env python3
"""
TRNG-Based One-Time PIN (OTP) Secure Verification Portal
--------------------------------------------------------
Interactive PC Portal for Challenge-Response Authentication
with PicoRV32 RISC-V SoC over UART.
"""

import sys
import os
import time
import threading
import queue
import tkinter as tk
from tkinter import ttk, messagebox
import serial
import serial.tools.list_ports

# -----------------------------------------------------------------------------
# Cryptographic Parameters: Pre-Shared Key (128-bit)
# Must strictly match SHARED_KEY_0 and SHARED_KEY_1 in SoC firmware (main.c)
# -----------------------------------------------------------------------------
SHARED_KEY_0 = 0x0123456789ABCDEF
SHARED_KEY_1 = 0xFEDCBA9876543210

def rotl64(x, b):
    return ((x << b) | (x >> (64 - b))) & 0xFFFFFFFFFFFFFFFF

def sipround(v0, v1, v2, v3):
    v0 = (v0 + v1) & 0xFFFFFFFFFFFFFFFF
    v1 = rotl64(v1, 13) ^ v0
    v0 = rotl64(v0, 32)
    v2 = (v2 + v3) & 0xFFFFFFFFFFFFFFFF
    v3 = rotl64(v3, 16) ^ v2
    v0 = (v0 + v3) & 0xFFFFFFFFFFFFFFFF
    v3 = rotl64(v3, 21) ^ v0
    v2 = (v2 + v1) & 0xFFFFFFFFFFFFFFFF
    v1 = rotl64(v1, 17) ^ v2
    v2 = rotl64(v2, 32)
    return v0, v1, v2, v3

def compute_siphash_otp(hex_challenge_128):
    """
    Computes SipHash-2-4 over 128-bit TRNG challenge and truncates to 6-digit OTP.
    """
    if len(hex_challenge_128) != 32:
        raise ValueError("128-bit challenge hex must be exactly 32 characters.")

    w0 = int(hex_challenge_128[0:8], 16)
    w1 = int(hex_challenge_128[8:16], 16)
    w2 = int(hex_challenge_128[16:24], 16)
    w3 = int(hex_challenge_128[24:32], 16)

    m0 = (w0 << 32) | w1
    m1 = (w2 << 32) | w3

    v0 = 0x736F6D6570736575 ^ SHARED_KEY_0
    v1 = 0x646F72616E646F6D ^ SHARED_KEY_1
    v2 = 0x6C7967656E657261 ^ SHARED_KEY_0
    v3 = 0x7465646279746573 ^ SHARED_KEY_1

    # Block 0
    v3 ^= m0
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0 ^= m0

    # Block 1
    v3 ^= m1
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0 ^= m1

    # Finalization (16 bytes = 0x10)
    last = 0x1000000000000000
    v3 ^= last
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0, v1, v2, v3 = sipround(v0, v1, v2, v3)
    v0 ^= last

    v2 ^= 0xFF
    for _ in range(4):
        v0, v1, v2, v3 = sipround(v0, v1, v2, v3)

    tag = v0 ^ v1 ^ v2 ^ v3
    otp = (tag & 0x7FFFFFFF) % 1000000
    return otp, f"{otp:06d}", tag, (m0, m1)


class OTPPortalApp:
    def __init__(self, root):
        self.root = root
        self.root.title("RISC-V TRNG One-Time PIN Authentication Portal")
        self.root.geometry("1020x740")
        self.root.minsize(920, 680)

        self.serial_conn = None
        self.rx_thread = None
        self.running = True
        self.rx_queue = queue.Queue()

        self.current_challenge = ""
        self.computed_pin = ""
        self.is_authenticated = False
        self.simulation_mode = False

        self._setup_theme()
        self._build_ui()
        self._refresh_ports()
        self.root.after(50, self._process_rx_queue)

    def _setup_theme(self):
        self.c_bg = "#0B0F19"
        self.c_card = "#161F30"
        self.c_card_border = "#24324D"
        self.c_accent = "#38BDF8"
        self.c_text = "#F1F5F9"
        self.c_muted = "#94A3B8"
        self.c_green = "#10B981"
        self.c_red = "#EF4444"
        self.c_yellow = "#F59E0B"
        self.c_mono_bg = "#070B13"

        self.root.configure(bg=self.c_bg)

    def _build_ui(self):
        # Header Banner
        header = tk.Frame(self.root, bg=self.c_card, highlightbackground=self.c_card_border, highlightthickness=1)
        header.pack(fill="x", padx=16, pady=(12, 8))

        title_lbl = tk.Label(header, text="🛡️ RISC-V SoC TRNG OTP AUTHENTICATION PORTAL",
                             font=("Helvetica", 14, "bold"), fg=self.c_accent, bg=self.c_card)
        title_lbl.pack(side="left", padx=16, pady=10)

        sub_lbl = tk.Label(header, text="PicoRV32 100MHz | 128-bit Nonce | SipHash-2/4 Keyed PRF",
                           font=("Helvetica", 9), fg=self.c_muted, bg=self.c_card)
        sub_lbl.pack(side="right", padx=16, pady=10)

        # Main Layout: 2 Columns
        main_panes = tk.Frame(self.root, bg=self.c_bg)
        main_panes.pack(fill="both", expand=True, padx=16, pady=6)

        # Left Column (Controls & Security Pipeline)
        left_col = tk.Frame(main_panes, bg=self.c_bg)
        left_col.pack(side="left", fill="both", expand=True, padx=(0, 8))

        # Right Column (Live Terminal & Console)
        right_col = tk.Frame(main_panes, bg=self.c_bg, width=380)
        right_col.pack(side="right", fill="both", padx=(8, 0))

        # --- LEFT COLUMN CARDS ---
        # 1. Connection Card
        self._build_conn_card(left_col)

        # 2. Challenge & OTP Pipeline Card
        self._build_pipeline_card(left_col)

        # 3. Access Status & Post-Auth Control Card
        self._build_status_and_controls_card(left_col)

        # --- RIGHT COLUMN CARDS ---
        self._build_terminal_card(right_col)

    def _build_conn_card(self, parent):
        card = tk.LabelFrame(parent, text=" 1. Hardware Serial Connection ", font=("Helvetica", 10, "bold"),
                             bg=self.c_card, fg=self.c_accent, bd=1, relief="solid")
        card.pack(fill="x", pady=(0, 8))

        row = tk.Frame(card, bg=self.c_card)
        row.pack(fill="x", padx=12, pady=10)

        tk.Label(row, text="Port:", font=("Helvetica", 9, "bold"), fg=self.c_text, bg=self.c_card).pack(side="left")
        self.port_combo = ttk.Combobox(row, width=15, state="readonly")
        self.port_combo.pack(side="left", padx=6)

        tk.Label(row, text="Baud:", font=("Helvetica", 9, "bold"), fg=self.c_text, bg=self.c_card).pack(side="left", padx=(8, 0))
        self.baud_combo = ttk.Combobox(row, values=["115200", "57600", "9600"], width=8, state="readonly")
        self.baud_combo.set("115200")
        self.baud_combo.pack(side="left", padx=6)

        self.btn_refresh = tk.Button(row, text="🔄", command=self._refresh_ports, bg="#1E293B", fg=self.c_text,
                                     activebackground="#334155", relief="groove", width=3)
        self.btn_refresh.pack(side="left", padx=4)

        self.btn_connect = tk.Button(row, text="Connect", command=self._toggle_connect,
                                     bg=self.c_green, fg="#FFFFFF", font=("Helvetica", 9, "bold"),
                                     padx=12, relief="raised", cursor="hand2")
        self.btn_connect.pack(side="left", padx=8)

        self.sim_btn = tk.Button(row, text="⚡ Sim Test", command=self._trigger_sim_challenge,
                                 bg="#334155", fg=self.c_text, font=("Helvetica", 8),
                                 relief="groove", cursor="hand2")
        self.sim_btn.pack(side="right")

    def _build_pipeline_card(self, parent):
        card = tk.LabelFrame(parent, text=" 2. Cryptographic OTP Derivation Pipeline ",
                             font=("Helvetica", 10, "bold"), bg=self.c_card, fg=self.c_accent, bd=1, relief="solid")
        card.pack(fill="x", pady=(0, 8))

        p_inner = tk.Frame(card, bg=self.c_card)
        p_inner.pack(fill="x", padx=12, pady=8)

        # Step A: TRNG Nonce
        tk.Label(p_inner, text="A. 128-Bit TRNG Challenge Nonce (from SoC):", font=("Helvetica", 9, "bold"),
                 fg=self.c_muted, bg=self.c_card).pack(anchor="w")

        self.lbl_challenge = tk.Label(p_inner, text="WAITING FOR CHALLENGE...",
                                      font=("Courier", 11, "bold"), fg="#38BDF8", bg=self.c_mono_bg,
                                      padx=8, pady=6, relief="sunken", anchor="w")
        self.lbl_challenge.pack(fill="x", pady=(2, 8))

        # Step B: Shared Secret Key & Algorithm
        info_frame = tk.Frame(p_inner, bg=self.c_card)
        info_frame.pack(fill="x", pady=(0, 8))

        k_lbl = tk.Label(info_frame, text=f"Key: 0x{SHARED_KEY_0:016X}{SHARED_KEY_1:016X} | Algorithm: SipHash-2/4 (64-bit PRF) -> Mod 10^6",
                         font=("Courier", 8), fg=self.c_muted, bg=self.c_card)
        k_lbl.pack(side="left")

        # Step C: Generated 6-Digit PIN
        tk.Label(p_inner, text="B. Calculated 6-Digit Dynamic One-Time PIN:", font=("Helvetica", 9, "bold"),
                 fg=self.c_muted, bg=self.c_card).pack(anchor="w")

        pin_row = tk.Frame(p_inner, bg=self.c_card)
        pin_row.pack(fill="x", pady=(4, 8))

        self.lbl_pin = tk.Label(pin_row, text="------", font=("Helvetica", 22, "bold"),
                                fg="#FACC15", bg=self.c_mono_bg, width=10, relief="solid", bd=1)
        self.lbl_pin.pack(side="left", padx=(0, 12))

        btn_box = tk.Frame(pin_row, bg=self.c_card)
        btn_box.pack(side="left", fill="both", expand=True)

        self.btn_send_pin = tk.Button(btn_box, text="🚀 Send PIN & Verify Access", command=self._send_pin,
                                      bg="#0284C7", fg="#FFFFFF", font=("Helvetica", 10, "bold"),
                                      pady=4, relief="raised", cursor="hand2", state="disabled")
        self.btn_send_pin.pack(fill="x", pady=(0, 4))

        self.auto_solve_var = tk.BooleanVar(value=True)
        self.chk_auto = tk.Checkbutton(btn_box, text="Auto-compute & transmit PIN on challenge arrival",
                                       variable=self.auto_solve_var, font=("Helvetica", 8),
                                       fg=self.c_text, bg=self.c_card, selectcolor="#1E293B",
                                       activebackground=self.c_card, activeforeground=self.c_text)
        self.chk_auto.pack(anchor="w")

    def _build_status_and_controls_card(self, parent):
        card = tk.LabelFrame(parent, text=" 3. Authorization & Verified Dashboard ",
                             font=("Helvetica", 10, "bold"), bg=self.c_card, fg=self.c_accent, bd=1, relief="solid")
        card.pack(fill="both", expand=True)

        inner = tk.Frame(card, bg=self.c_card)
        inner.pack(fill="both", expand=True, padx=12, pady=10)

        # Big Badge
        self.lbl_status_badge = tk.Label(inner, text="🔴 SYSTEM LOCKED — AUTHENTICATION REQUIRED",
                                         font=("Helvetica", 11, "bold"), fg="#FFFFFF", bg="#7F1D1D",
                                         pady=8, relief="ridge", bd=2)
        self.lbl_status_badge.pack(fill="x", pady=(0, 10))

        # Dashboard actions (Enabled only when granted!)
        self.dash_frame = tk.Frame(inner, bg=self.c_card)
        self.dash_frame.pack(fill="both", expand=True)

        tk.Label(self.dash_frame, text="Authenticated SoC Command Center:", font=("Helvetica", 9, "bold"),
                 fg=self.c_muted, bg=self.c_card).pack(anchor="w", pady=(0, 6))

        d_btns = tk.Frame(self.dash_frame, bg=self.c_card)
        d_btns.pack(fill="x", pady=4)

        self.btn_req_challenge = tk.Button(d_btns, text="🔄 New Challenge", command=self._req_challenge,
                                           bg="#334155", fg=self.c_text, font=("Helvetica", 8, "bold"), padx=8, pady=4)
        self.btn_req_challenge.pack(side="left", padx=(0, 6))

        self.btn_led = tk.Button(d_btns, text="💡 Toggle LEDs", command=lambda: self._send_cmd("LED:0x00FF"),
                                 bg="#334155", fg=self.c_text, font=("Helvetica", 8, "bold"), padx=8, pady=4, state="disabled")
        self.btn_led.pack(side="left", padx=6)

        self.btn_stats = tk.Button(d_btns, text="⏱️ SoC Timer Stats", command=lambda: self._send_cmd("STATS"),
                                   bg="#334155", fg=self.c_text, font=("Helvetica", 8, "bold"), padx=8, pady=4, state="disabled")
        self.btn_stats.pack(side="left", padx=6)

        self.btn_lock = tk.Button(d_btns, text="🔒 Lock Session", command=lambda: self._send_cmd("LOCK"),
                                  bg="#991B1B", fg="#FFFFFF", font=("Helvetica", 8, "bold"), padx=8, pady=4, state="disabled")
        self.btn_lock.pack(side="right")

    def _build_terminal_card(self, parent):
        card = tk.LabelFrame(parent, text=" Real-Time UART Serial Log ",
                             font=("Helvetica", 10, "bold"), bg=self.c_card, fg=self.c_accent, bd=1, relief="solid")
        card.pack(fill="both", expand=True)

        self.term_text = tk.Text(card, bg=self.c_mono_bg, fg="#A7F3D0", font=("Courier", 8),
                                 insertbackground="white", bd=0, wrap="word")
        self.term_text.pack(fill="both", expand=True, padx=8, pady=(8, 4))

        t_ctrls = tk.Frame(card, bg=self.c_card)
        t_ctrls.pack(fill="x", padx=8, pady=(0, 8))

        self.btn_clear_log = tk.Button(t_ctrls, text="Clear Log", command=lambda: self.term_text.delete("1.0", tk.END),
                                       bg="#1E293B", fg=self.c_muted, font=("Helvetica", 8), relief="flat")
        self.btn_clear_log.pack(side="right")

    def _refresh_ports(self):
        ports = [p.device for p in serial.tools.list_ports.comports()]
        self.port_combo["values"] = ports
        if ports:
            self.port_combo.current(0)
        else:
            self.port_combo.set("No Ports Found")

    def _toggle_connect(self):
        if self.serial_conn is None:
            port = self.port_combo.get()
            if not port or port == "No Ports Found":
                messagebox.showwarning("Port Error", "Please select a valid serial port (e.g. /dev/ttyUSB0 or COM3).")
                return

            try:
                baud = int(self.baud_combo.get())
                self.serial_conn = serial.Serial(port, baud, timeout=0.1)
                self.simulation_mode = False
                self.btn_connect.config(text="Disconnect", bg=self.c_red)
                self._log_terminal(f"[HOST] Connected to {port} @ {baud} bps\n")

                self.rx_thread = threading.Thread(target=self._serial_reader_loop, daemon=True)
                self.rx_thread.start()

                # Prompt the SoC to send its challenge
                self.root.after(300, self._req_challenge)
            except Exception as e:
                messagebox.showerror("Connection Failed", f"Could not open serial port:\n{e}")
        else:
            self._disconnect()

    def _disconnect(self):
        if self.serial_conn:
            try:
                self.serial_conn.close()
            except Exception:
                pass
            self.serial_conn = None
        self.btn_connect.config(text="Connect", bg=self.c_green)
        self._log_terminal("[HOST] Disconnected from serial port.\n")

    def _serial_reader_loop(self):
        while self.running and self.serial_conn and self.serial_conn.is_open:
            try:
                line = self.serial_conn.readline()
                if line:
                    decoded = line.decode("utf-8", errors="replace")
                    self.rx_queue.put(decoded)
            except Exception:
                break
        time.sleep(0.02)

    def _process_rx_queue(self):
        while not self.rx_queue.empty():
            line = self.rx_queue.get()
            self._log_terminal(line)
            self._handle_soc_message(line.strip())

        self.root.after(50, self._process_rx_queue)

    def _log_terminal(self, text):
        self.term_text.insert(tk.END, text)
        self.term_text.see(tk.END)

    def _handle_soc_message(self, line):
        # Challenge line format: "CHALLENGE:1234567890ABCDEF1234567890ABCDEF"
        if line.startswith("CHALLENGE:"):
            challenge_hex = line.replace("CHALLENGE:", "").strip()
            if len(challenge_hex) == 32:
                self.current_challenge = challenge_hex
                self.lbl_challenge.config(text=f"{challenge_hex[0:8]} {challenge_hex[8:16]} {challenge_hex[16:24]} {challenge_hex[24:32]}")
                
                # Derive 6-Digit PIN
                otp, pin_str, tag, _ = compute_siphash_otp(challenge_hex)
                self.computed_pin = pin_str
                self.lbl_pin.config(text=pin_str)
                self.btn_send_pin.config(state="normal")

                self._set_status_badge("YELLOW", "🟡 CHALLENGE RECEIVED — READY TO VERIFY")

                if self.auto_solve_var.get():
                    self.root.after(400, self._send_pin)

        elif "STATUS:ACCESS_GRANTED" in line:
            self.is_authenticated = True
            self._set_status_badge("GREEN", "🟢 ACCESS GRANTED — AUTHENTICATED SESSION ACTIVE")
            self.btn_led.config(state="normal")
            self.btn_stats.config(state="normal")
            self.btn_lock.config(state="normal")

        elif "STATUS:ACCESS_DENIED" in line:
            self.is_authenticated = False
            self._set_status_badge("RED", "🔴 ACCESS DENIED — INVALID PIN ENTERED")
            self.btn_led.config(state="disabled")
            self.btn_stats.config(state="disabled")
            self.btn_lock.config(state="disabled")

        elif "STATUS:LOCKED" in line:
            self.is_authenticated = False
            self._set_status_badge("RED", "🔴 SYSTEM LOCKED — AUTHENTICATION REQUIRED")
            self.btn_led.config(state="disabled")
            self.btn_stats.config(state="disabled")
            self.btn_lock.config(state="disabled")

    def _set_status_badge(self, color_type, text):
        if color_type == "GREEN":
            self.lbl_status_badge.config(text=text, bg="#065F46", fg="#A7F3D0")
        elif color_type == "RED":
            self.lbl_status_badge.config(text=text, bg="#7F1D1D", fg="#FECACA")
        elif color_type == "YELLOW":
            self.lbl_status_badge.config(text=text, bg="#78350F", fg="#FDE68A")

    def _send_pin(self):
        if not self.computed_pin:
            return
        cmd = f"PIN:{self.computed_pin}\r\n"
        self._send_raw(cmd)
        self._set_status_badge("YELLOW", "🟡 VERIFYING PIN WITH RISC-V HARDWARE...")

    def _req_challenge(self):
        self._send_raw("REQ_CHALLENGE\r\n")

    def _send_cmd(self, cmd_text):
        self._send_raw(cmd_text + "\r\n")

    def _send_raw(self, msg):
        self._log_terminal(f">> [TX] {msg}")
        if self.serial_conn and self.serial_conn.is_open:
            try:
                self.serial_conn.write(msg.encode("utf-8"))
                self.serial_conn.flush()
            except Exception as e:
                self._log_terminal(f"[ERROR] Failed to send: {e}\n")
        elif self.simulation_mode:
            # Handle simulation loopback
            self.root.after(300, lambda: self._sim_soc_response(msg.strip()))

    def _trigger_sim_challenge(self):
        """Simulation mode allows testing without real FPGA attached."""
        self.simulation_mode = True
        import random
        sim_words = [random.randint(0, 0xFFFFFFFF) for _ in range(4)]
        sim_hex = "".join(f"{w:08X}" for w in sim_words)
        self.rx_queue.put("==============================================================\n")
        self.rx_queue.put("   [SIMULATION] PicoRV32 TRNG Boot Sequence Completed        \n")
        self.rx_queue.put("==============================================================\n")
        self.rx_queue.put(f"CHALLENGE:{sim_hex}\n")

    def _sim_soc_response(self, tx_line):
        if tx_line.startswith("PIN:"):
            pin_rcvd = tx_line.split(":")[1]
            if pin_rcvd == self.computed_pin:
                self.rx_queue.put("STATUS:ACCESS_GRANTED\n")
                self.rx_queue.put(f"[AUTH] Success! 6-digit OTP matches: {pin_rcvd}\n")
            else:
                self.rx_queue.put("STATUS:ACCESS_DENIED\n")
        elif tx_line == "REQ_CHALLENGE":
            self._trigger_sim_challenge()
        elif tx_line == "STATS":
            self.rx_queue.put("STATS:CYCLES=10492800,AUTH=1\n")
        elif tx_line == "LOCK":
            self.rx_queue.put("STATUS:LOCKED\n")


def main():
    root = tk.Tk()
    app = OTPPortalApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
