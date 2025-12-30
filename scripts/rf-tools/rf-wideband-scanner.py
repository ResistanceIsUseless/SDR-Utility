#!/usr/bin/python3
"""
Wideband RF Scanner
Scans frequency ranges using RTL-SDR and CatSniffer, detects signals by strength,
and automatically dispatches to appropriate decoder based on frequency.
"""

import sys
import os
import subprocess
import time
import signal
import tempfile
from collections import defaultdict
from datetime import datetime

# Frequency bands and their decoders
FREQUENCY_BANDS = [
    # Format: (start_freq, end_freq, band_name, decoder, description)
    (24000000, 50000000, "VHF Low", "rtl_fm", "VHF radio, amateur, marine"),
    (88000000, 108000000, "FM Broadcast", "rtl_fm", "FM radio stations"),
    (108000000, 137000000, "Aviation", "rtl_fm", "Air traffic control"),
    (137000000, 138000000, "Weather Sat", "rtl_fm", "NOAA weather satellites"),
    (315000000, 315500000, "315 MHz ISM", "rtl_433", "Car keys, remotes, sensors"),
    (433050000, 434790000, "433 MHz ISM", "rtl_433", "Weather, IoT, smart home"),
    (868000000, 868600000, "868 MHz ISM", "rtl_433", "EU IoT devices"),
    (902000000, 928000000, "915 MHz ISM", "rtl_433", "US IoT, LoRa, sensors"),
    (1090000000, 1090500000, "ADS-B", "dump1090", "Aircraft transponders"),
    (2400000000, 2483500000, "2.4 GHz ISM", "catsniffer", "WiFi, BLE, Zigbee, Thread"),
]

# Signal strength threshold (dB above noise floor)
SIGNAL_THRESHOLD = 10  # Adjust based on environment

# Scanner configuration
SCAN_INTEGRATION_TIME = 1  # seconds per scan
FFT_BIN_SIZE = 100000  # 100 kHz bins


class SignalDetector:
    """Detects and tracks RF signals"""

    def __init__(self, threshold=SIGNAL_THRESHOLD):
        self.threshold = threshold
        self.detections = defaultdict(list)

    def analyze_fft_data(self, freq, power, noise_floor):
        """Analyze FFT bin for signal detection"""
        signal_strength = power - noise_floor

        if signal_strength > self.threshold:
            return {
                'frequency': freq,
                'power': power,
                'signal_strength': signal_strength,
                'timestamp': datetime.now()
            }
        return None

    def get_decoder_for_frequency(self, freq):
        """Determine appropriate decoder based on frequency"""
        for start, end, band_name, decoder, description in FREQUENCY_BANDS:
            if start <= freq <= end:
                return {
                    'decoder': decoder,
                    'band': band_name,
                    'description': description
                }
        return {'decoder': 'rtl_fm', 'band': 'Unknown', 'description': 'Generic FM demod'}


def scan_frequency_range(start_freq, end_freq, integration_time=1):
    """Scan frequency range using rtl_power"""
    print(f"[*] Scanning {start_freq/1e6:.1f} - {end_freq/1e6:.1f} MHz...")

    # Create temporary file for rtl_power output
    temp_file = tempfile.NamedTemporaryFile(mode='w+', suffix='.csv', delete=False)
    temp_file.close()

    try:
        # Run rtl_power for quick scan
        # Format: rtl_power -f start:end:step -i integration_time output.csv
        bandwidth = end_freq - start_freq
        bin_size = min(FFT_BIN_SIZE, bandwidth // 100)  # At least 100 bins

        cmd = [
            'rtl_power',
            '-f', f'{int(start_freq)}:{int(end_freq)}:{int(bin_size)}',
            '-i', str(integration_time),
            '-1',  # Single scan
            '-d', '0',  # Device 0
            temp_file.name
        ]

        # Run with timeout
        result = subprocess.run(cmd, capture_output=True, timeout=integration_time + 10)

        # Parse results
        signals = []
        if os.path.exists(temp_file.name) and os.path.getsize(temp_file.name) > 0:
            with open(temp_file.name, 'r') as f:
                for line in f:
                    # rtl_power CSV format:
                    # date, time, Hz low, Hz high, Hz step, samples, dB, dB, dB...
                    parts = line.strip().split(',')
                    if len(parts) > 6:
                        try:
                            freq_low = int(parts[2])
                            freq_high = int(parts[3])
                            freq_step = int(parts[4])
                            powers = [float(p) for p in parts[6:]]

                            # Calculate noise floor (lowest 10% of readings)
                            sorted_powers = sorted(powers)
                            noise_floor = sum(sorted_powers[:len(sorted_powers)//10]) / (len(sorted_powers)//10)

                            # Find peaks
                            for i, power in enumerate(powers):
                                freq = freq_low + (i * freq_step)
                                if power - noise_floor > SIGNAL_THRESHOLD:
                                    signals.append({
                                        'frequency': freq,
                                        'power': power,
                                        'strength': power - noise_floor,
                                        'noise_floor': noise_floor
                                    })
                        except (ValueError, IndexError):
                            continue

        return signals

    except subprocess.TimeoutExpired:
        print("[!] Scan timeout")
        return []
    except Exception as e:
        print(f"[!] Scan error: {e}")
        return []
    finally:
        # Cleanup
        try:
            os.unlink(temp_file.name)
        except:
            pass


def decode_signal(frequency, decoder, duration=30):
    """Attempt to decode signal using appropriate tool"""
    print(f"\n[*] Decoding {frequency/1e6:.3f} MHz with {decoder}...")

    if decoder == 'rtl_433':
        # Use rtl_433 for ISM band decoding
        cmd = [
            'timeout', str(duration),
            'rtl_433',
            '-f', str(int(frequency)),
            '-F', 'json',
            '-M', 'level',
            '-M', 'time:unix'
        ]

    elif decoder == 'catsniffer':
        # Use CatSniffer for 2.4 GHz
        if 2400000000 <= frequency <= 2483500000:
            # Determine channel (2.4 GHz WiFi/BLE channels)
            if frequency < 2420000000:
                protocol = 'ble'
                channel = 37  # BLE advertising channel
            elif 2410000000 <= frequency <= 2475000000:
                protocol = 'zigbee'
                # Zigbee channel = (freq - 2405) / 5
                channel = int((frequency - 2405000000) / 5000000)
            else:
                protocol = 'ble'
                channel = 37

            cmd = [
                'timeout', str(duration),
                '/usr/bin/python3',
                '/home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3/cat_sniffer.py',
                'sniff',
                '/dev/ttyACM1',
                '--phy', protocol,
                '-c', str(channel),
                '--fifo'
            ]
        else:
            print(f"[!] CatSniffer doesn't support {frequency/1e6:.1f} MHz")
            return None

    elif decoder == 'dump1090':
        # ADS-B aircraft tracking
        cmd = [
            'timeout', str(duration),
            'dump1090',
            '--device-index', '0',
            '--interactive'
        ]

    elif decoder == 'rtl_fm':
        # Generic FM demodulation
        cmd = [
            'timeout', str(duration),
            'rtl_fm',
            '-f', str(int(frequency)),
            '-M', 'fm',
            '-s', '200k',
            '-A', 'fast'
        ]

    else:
        print(f"[!] Unknown decoder: {decoder}")
        return None

    # Run decoder
    try:
        print(f"    Command: {' '.join(cmd)}")
        print(f"    Duration: {duration} seconds")
        print(f"    Press Ctrl+C to stop early\n")

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True
        )

        # Stream output
        try:
            for line in process.stdout:
                print(f"    {line.rstrip()}")
        except KeyboardInterrupt:
            print("\n[*] Stopping decoder...")
            process.terminate()

        process.wait(timeout=5)

    except subprocess.TimeoutExpired:
        process.kill()
    except Exception as e:
        print(f"[!] Decoder error: {e}")


def quick_scan_all_bands():
    """Quick scan across all frequency bands"""
    print("=" * 80)
    print("WIDEBAND RF SCANNER")
    print("=" * 80)
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Signal threshold: {SIGNAL_THRESHOLD} dB above noise\n")

    all_detections = []
    detector = SignalDetector()

    # Scan RTL-SDR bands (24 MHz - 1.7 GHz)
    rtl_bands = [b for b in FREQUENCY_BANDS if b[1] <= 1700000000]

    for start, end, name, decoder, description in rtl_bands:
        print(f"\n[{name}] {start/1e6:.1f} - {end/1e6:.1f} MHz ({description})")

        signals = scan_frequency_range(start, end, SCAN_INTEGRATION_TIME)

        if signals:
            # Sort by signal strength
            signals.sort(key=lambda x: x['strength'], reverse=True)

            print(f"    ✓ Found {len(signals)} signal(s)")

            # Show top 3 strongest
            for sig in signals[:3]:
                decoder_info = detector.get_decoder_for_frequency(sig['frequency'])
                print(f"      {sig['frequency']/1e6:.3f} MHz: {sig['strength']:.1f} dB → {decoder_info['decoder']}")

                all_detections.append({
                    'frequency': sig['frequency'],
                    'strength': sig['strength'],
                    'power': sig['power'],
                    'band': name,
                    'decoder': decoder_info['decoder']
                })
        else:
            print(f"    - No signals detected")

    # CatSniffer 2.4 GHz scan
    print(f"\n[2.4 GHz ISM] 2400 - 2483.5 MHz (BLE/Zigbee/WiFi)")
    print(f"    Note: Use CatSniffer BLE/Zigbee capture tools for 2.4 GHz")
    print(f"    Automatic scan not available (protocol-specific)")

    return all_detections


def interactive_decoder(detections):
    """Allow user to select signal to decode"""
    if not detections:
        print("\n[!] No signals detected")
        return

    print("\n" + "=" * 80)
    print("DETECTED SIGNALS")
    print("=" * 80)

    # Sort by strength
    detections.sort(key=lambda x: x['strength'], reverse=True)

    for i, det in enumerate(detections, 1):
        print(f"[{i}] {det['frequency']/1e6:.3f} MHz ({det['band']})")
        print(f"    Strength: {det['strength']:.1f} dB")
        print(f"    Decoder: {det['decoder']}")
        print()

    print("[0] Exit")
    print()

    try:
        choice = input("Select signal to decode (number): ").strip()

        if choice == '0' or not choice:
            return

        idx = int(choice) - 1
        if 0 <= idx < len(detections):
            selected = detections[idx]

            duration = input(f"Capture duration in seconds [30]: ").strip()
            duration = int(duration) if duration else 30

            decode_signal(selected['frequency'], selected['decoder'], duration)
        else:
            print("[!] Invalid selection")

    except (ValueError, KeyboardInterrupt):
        print("\n[*] Cancelled")


def continuous_monitor():
    """Continuously monitor for new signals"""
    print("=" * 80)
    print("CONTINUOUS RF MONITORING MODE")
    print("=" * 80)
    print("Scanning all bands every 30 seconds...")
    print("Press Ctrl+C to stop\n")

    previous_signals = set()

    try:
        while True:
            detections = quick_scan_all_bands()

            # Check for new signals
            current_signals = set((d['frequency'], d['band']) for d in detections)
            new_signals = current_signals - previous_signals

            if new_signals:
                print("\n" + "!" * 80)
                print("NEW SIGNAL(S) DETECTED!")
                print("!" * 80)
                for freq, band in new_signals:
                    det = next(d for d in detections if d['frequency'] == freq and d['band'] == band)
                    print(f"  {freq/1e6:.3f} MHz ({band}): {det['strength']:.1f} dB")
                print()

            previous_signals = current_signals

            print(f"\n[*] Waiting 30 seconds before next scan...")
            time.sleep(30)

    except KeyboardInterrupt:
        print("\n\n[*] Monitoring stopped")


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Wideband RF Scanner')
    parser.add_argument('--scan', action='store_true', help='Quick scan all bands')
    parser.add_argument('--monitor', action='store_true', help='Continuous monitoring mode')
    parser.add_argument('--threshold', type=int, default=SIGNAL_THRESHOLD,
                       help=f'Signal threshold in dB (default: {SIGNAL_THRESHOLD})')
    parser.add_argument('--freq', type=float, help='Decode specific frequency in MHz')
    parser.add_argument('--decoder', choices=['rtl_433', 'rtl_fm', 'catsniffer', 'dump1090'],
                       help='Force specific decoder')
    parser.add_argument('--duration', type=int, default=30, help='Decode duration in seconds')

    args = parser.parse_args()

    # Update threshold
    SIGNAL_THRESHOLD = args.threshold

    if args.freq:
        # Decode specific frequency
        freq_hz = int(args.freq * 1e6)
        detector = SignalDetector()
        decoder_info = detector.get_decoder_for_frequency(freq_hz)
        decoder = args.decoder or decoder_info['decoder']

        print(f"[*] Decoding {args.freq} MHz using {decoder}")
        decode_signal(freq_hz, decoder, args.duration)

    elif args.monitor:
        # Continuous monitoring
        continuous_monitor()

    else:
        # Quick scan + interactive decode
        detections = quick_scan_all_bands()
        interactive_decoder(detections)
