# Two-Factor Authentication (2FA) Protocol & Transaction Specification
**System**: PicoRV32 Hardware Security Token & 2FA Authenticator  
**Target Hardware**: Real Digital Boolean Board (Xilinx Spartan-7 FPGA)  
**Channel**: UART Serial Link (115200 Baud, 8N1)  
**Document**: `2FA_AUTHENTICATION_PROTOCOL_SPEC.md`

---

## 1. Executive Summary: The 2FA Handshake

The 2FA authentication mechanism between the **Host PC (Client/Server)** and the **FPGA Hardware Token (PicoRV32 SoC)** is established via a **4-Way Transaction Handshake** (2 round-trips over the serial channel).

```
  HOST PC / CLIENT                                     FPGA HARDWARE TOKEN
 (Login Screen / Terminal)                            (PicoRV32 + TRNG + Timer)
        |                                                        |
        | ====== Transaction 1: AUTH_REQUEST ==================> |
        |        (Host requests a new login session)             | 
        |                                                        | [1. Reads 128-bit TRNG Entropy]
        |                                                        | [2. Generates Nonce & 6-Digit OTP]
        |                                                        | [3. Starts 30s Hardware Timer]
        | <===== Transaction 2: AUTH_CHALLENGE ================= | [4. Lights 16-LED Countdown Bar]
        |        (Returns Nonce, 6-digit OTP, 30s TTL)           |
        |                                                        |
   [User enters 6-digit                                          | [Timer ticking at 100 MHz]
    OTP on PC terminal]                                          | [LEDs dropping: 16 -> 8 -> 0]
        |                                                        |
        | ====== Transaction 3: AUTH_SUBMIT ===================> |
        |        (Submits entered OTP code)                      |
        |                                                        | [5. Verifies: Elapsed < 30.00s]
        |                                                        | [6. Verifies: Input == OTP]
        | <===== Transaction 4: AUTH_RESULT ==================== | [7. Locks / Clears Session]
        |        (AUTH_SUCCESS or AUTH_FAIL)                     |
        v                                                        v
```

---

## 2. Transaction Count Breakdown

| Transaction # | Direction | Name | Payload / Content | State on FPGA |
| :---: | :---: | :--- | :--- | :--- |
| **Transaction 1** | Host $\rightarrow$ FPGA | `AUTH_REQ` | Request command string: `"auth_req\n"` | `STATE_IDLE` $\rightarrow$ `STATE_GEN_CHALLENGE` |
| **Transaction 2** | FPGA $\rightarrow$ Host | `AUTH_CHALLENGE` | 128-bit Nonce + 6-digit OTP + 30s TTL confirmation | `STATE_GEN_CHALLENGE` $\rightarrow$ `STATE_WAIT_USER` |
| **Transaction 3** | Host $\rightarrow$ FPGA | `AUTH_SUBMIT` | User-submitted OTP (e.g. `"593812\n"`) | `STATE_WAIT_USER` $\rightarrow$ `STATE_VALIDATE` |
| **Transaction 4** | FPGA $\rightarrow$ Host | `AUTH_RESULT` | Final verdict: `ACCESS_GRANTED` or `ACCESS_DENIED` | `STATE_VALIDATE` $\rightarrow$ `STATE_IDLE` |

**Total Transactions to Establish Connectivity / Authentication**: **Exactly 4 wire transactions** (2 round-trip request/response pairs).

---

## 3. Step-by-Step Protocol Walkthrough

### Step 1: Session Initiation (`Transaction 1: Host -> FPGA`)
1. The user sits at a locked computer screen or secure terminal and types `auth_req` (or the host login software automatically sends an authentication request frame).
2. **Wire Transmission**:
   ```text
   TX (Host -> FPGA): "auth_req\n"
   ```
3. The PicoRV32 core receives the command via its memory-mapped UART register (`0x2000_0000`).

---

### Step 2: Physical Entropy Sampling & Challenge Generation (FPGA Internal)
1. **Entropy Harvesting**: PicoRV32 checks `TRNG_STATUS` (`0x5000_0004`) and reads four 32-bit physical random words from `TRNG_DATA` (`0x5000_0000`) produced by the 16 on-chip ring oscillators:
   ```c
   uint32_t entropy[4];
   entropy[0] = TRNG_DATA; // 0x7A9F02C1
   entropy[1] = TRNG_DATA; // 0xD4E8B901
   entropy[2] = TRNG_DATA; // 0x33AF125E
   entropy[3] = TRNG_DATA; // 0x90CC8124
   ```
2. **6-Digit OTP Derivation**: The lowest entropy word is mapped to a 6-digit numerical range ($000000 - 999999$):
   $$\text{OTP} = \text{entropy}[0] \pmod{1000000} \implies \mathbf{593812}$$
3. **Hardware Timer Arming**: The 32-bit Hardware Timer (`0x4000_0000`) records the exact start timestamp:
   ```c
   session.start_cycle = TIMER_CNT; // e.g. 100,000,000 cycles
   session.timeout_cycles = 30 * 100000000; // 30.00 seconds at 100MHz = 3,000,000,000 cycles
   session.active = true;
   session.expected_otp = 593812;
   ```
4. **Visual Countdown Activation**: All 16 on-board LEDs (`0x3000_0000`) are driven high (`0xFFFF`), initiating the physical progress countdown bar.

---

### Step 3: Challenge Issuance (`Transaction 2: FPGA -> Host`)
1. The FPGA transmits the generated challenge payload back to the host terminal over UART.
2. **Wire Transmission**:
   ```text
   RX (Host <- FPGA):
   [CHALLENGE GENERATED]
     Session Nonce : 0x7A9F02C1_D4E8B901_33AF125E_90CC8124
     Dynamic OTP   : 593812
     Validity      : 30.00 Seconds [16-LED Countdown Active]
   ```
3. The Host PC displays the prompt: `"Enter OTP before expiration:"`.

---

### Step 4: User Submission (`Transaction 3: Host -> FPGA`)
1. The user reads the dynamic code and enters it into the terminal within the 30-second window.
2. **Wire Transmission**:
   ```text
   TX (Host -> FPGA): "593812\n"
   ```
3. Meanwhile, during the wait period, the 16 LEDs on the board extinguish linearly as time passes:
   * **30s remaining**: `[ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ]` (16 LEDs ON)
   * **15s remaining**: `[ ■ ■ ■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ ]` (8 LEDs ON)
   * **0s remaining**:  `[ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ ]` (0 LEDs ON)

---

### Step 5: Verification & Decision (`Transaction 4: FPGA -> Host`)

When the FPGA receives the response, it executes the **Hardware Verification Routine**:

```
                              [ Incoming OTP Received ]
                                         |
                                         v
                         +-------------------------------+
                         | Read Current TIMER_CNT        |
                         | delta = now - start_cycle     |
                         +---------------+---------------+
                                         |
                       Is delta <= 3,000,000,000 cycles?
                                   (<= 30.00s)
                                  /             \
                             [YES]               [NO] (Expired)
                              /                     \
            Does input == expected_otp?              |
                    /             \                  |
               [YES]               [NO]              |
                /                     \              v
               v                       v     +--------------------------------+
    +------------------------+  +------------------------+ | [AUTH_FAIL: TOKEN EXPIRED]   |
    | [AUTH_SUCCESS]         |  | [AUTH_FAIL: MISMATCH]  | | Replay Attempt Blocked!      |
    | ACCESS GRANTED         |  | Invalid Code           | | Clear OTP & Turn Off LEDs    |
    | All 16 LEDs Flash      |  | Lock Session           | +--------------------------------+
    +------------------------+  +------------------------+
```

#### Outcome A: Success (Authenticated within 30s)
* **Wire Transmission**:
  ```text
  RX (Host <- FPGA): "[AUTH_SUCCESS] Access Granted! Verified in 5.42 seconds.\r\n"
  ```
* **Hardware State**: All 16 LEDs flash green 3 times. Host PC unlocks and grants session access.

#### Outcome B: Timeout / Replay Attack (Submitted after 30s or Reused)
* **Wire Transmission**:
  ```text
  RX (Host <- FPGA): "[AUTH_FAIL] Token Expired / Replay Attempt Blocked. Access Denied.\r\n"
  ```
* **Hardware State**: 16 LEDs immediately turn OFF (`0x0000`). Internal session is zeroed out. Re-sending the same OTP is rejected.

---

## 4. Packet Frame Format Specification

For production embedded implementations, transactions use fixed binary frames:

### 1. Request Frame (`AUTH_REQ` - 6 Bytes)
```
+--------------+--------------+-----------------------+----------+
| Header (2B)  | Msg Type (1B)| Client Session ID (2B)| CRC8 (1B)|
|    0xAA55    |     0x01     |      0x1024           |   0x3E   |
+--------------+--------------+-----------------------+----------+
```

### 2. Challenge Frame (`AUTH_CHALLENGE` - 28 Bytes)
```
+--------------+--------------+-------------------+-----------------+----------+----------+
| Header (2B)  | Msg Type (1B)| 128-bit Nonce(16B)| 6-digit OTP (4B)| TTL (4B) | CRC8 (1B)|
|    0xAA55    |     0x02     | 16 Entropy Bytes  |    0x00090F74   |  30000ms |   0x7A   |
+--------------+--------------+-------------------+-----------------+----------+----------+
```

### 3. Response Frame (`AUTH_SUBMIT` - 10 Bytes)
```
+--------------+--------------+-----------------------+-----------------+----------+
| Header (2B)  | Msg Type (1B)| Client Session ID (2B)| User OTP (4B)   | CRC8 (1B)|
|    0xAA55    |     0x03     |      0x1024           |    0x00090F74   |   0x51   |
+--------------+--------------+-----------------------+-----------------+----------+
```

### 4. Verdict Frame (`AUTH_RESULT` - 6 Bytes)
```
+--------------+--------------+-----------------------+-----------------+----------+
| Header (2B)  | Msg Type (1B)| Status Code (1B)      | Elapsed ms (2B) | CRC8 (1B)|
|    0xAA55    |     0x04     | 0x00 (OK) / 0xFF(FAIL)|     5420 ms     |   0x9B   |
+--------------+--------------+-----------------------+-----------------+----------+
```

---

## 5. Summary Answer for Reviewers

When asked: *"How is 2FA established and how many transactions does it take?"*

> **"The 2FA authentication is established through a strict 4-transaction handshake over UART:**
>
> 1. **Transaction 1 (`AUTH_REQ`)**: Host requests a login session.
> 2. **Transaction 2 (`AUTH_CHALLENGE`)**: FPGA samples its physical TRNG, starts the 30-second 100 MHz Hardware Timer, and returns a 128-bit session nonce with a dynamic 6-digit OTP while lighting the 16-LED countdown bar.
> 3. **Transaction 3 (`AUTH_SUBMIT`)**: User submits the 6-digit code.
> 4. **Transaction 4 (`AUTH_RESULT`)**: FPGA verifies that the cycle timer is $\le 30.00\,\text{s}$ and the code matches, returning `AUTH_SUCCESS` or instantly blocking replay/expired attempts.
> 
> **Total transactions before connectivity/approval = 4 (2 round trips)."**
