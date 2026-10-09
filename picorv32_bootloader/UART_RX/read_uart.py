import serial
import time
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace', line_buffering=True)
port = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyUSB1"
baud = 115200

print(f"Opening {port} at {baud} baud...", flush=True)
try:
    ser = serial.Serial(port, baudrate=baud, timeout=0.1)
    print(f"Connected! Live monitoring UART output from FPGA...\n", flush=True)
    print("=" * 50, flush=True)
    
    start_time = time.time()
    received_bytes = bytearray()
    
    while time.time() - start_time < 12:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            received_bytes.extend(data)
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
        time.sleep(0.01)
        
    print("\n" + "=" * 50, flush=True)
    print(f"\n[SUCCESS] Total UART bytes received: {len(received_bytes)}", flush=True)
    ser.close()
except Exception as e:
    print(f"\nError: {e}", flush=True)
