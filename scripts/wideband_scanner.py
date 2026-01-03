#!/usr/bin/env python3
"""
Wideband RF Spectrum Scanner for USRP B210

Scans across frequency ranges, detects signals, and creates a spectrum map.
USB 2.0 optimized: Uses 2 MHz capture bandwidth with frequency hopping.
"""

import numpy as np
import subprocess
import os
import sys
import json
import time
from datetime import datetime

class SpectrumScanner:
    def __init__(self, sample_rate=2e6, fft_size=2048, gain=40):
        self.sample_rate = sample_rate
        self.fft_size = fft_size
        self.gain = gain
        self.uhd_images_dir = "/usr/share/uhd/4.9.0/images"

    def capture_at_frequency(self, center_freq, duration=0.1):
        """
        Capture IQ samples at a specific frequency
        Returns: numpy array of complex samples
        """
        num_samples = int(self.sample_rate * duration)
        temp_file = "/tmp/scan_temp.cfile"

        # Build uhd_rx_cfile command
        cmd = [
            "uhd_rx_cfile",
            "-f", str(int(center_freq)),
            "-r", str(int(self.sample_rate)),
            "-g", str(self.gain),
            "-N", str(num_samples),
            temp_file
        ]

        # Set environment and capture
        env = os.environ.copy()
        env['UHD_IMAGES_DIR'] = self.uhd_images_dir

        try:
            # Run capture (suppress output)
            result = subprocess.run(cmd, env=env, capture_output=True, timeout=10)

            # Read captured data
            if os.path.exists(temp_file):
                iq = np.fromfile(temp_file, dtype=np.complex64)
                os.remove(temp_file)
                return iq
            else:
                return None

        except subprocess.TimeoutExpired:
            print(f"Timeout capturing {center_freq/1e6:.1f} MHz")
            return None
        except Exception as e:
            print(f"Error capturing {center_freq/1e6:.1f} MHz: {e}")
            return None

    def analyze_spectrum(self, iq_samples, center_freq):
        """
        Analyze IQ samples and return spectrum data
        Returns: dict with frequencies, power, and detected signals
        """
        if iq_samples is None or len(iq_samples) == 0:
            return None

        # Compute FFT
        fft_result = np.fft.fftshift(np.fft.fft(iq_samples[:self.fft_size]))
        fft_power = np.abs(fft_result) ** 2
        fft_power_db = 10 * np.log10(fft_power + 1e-10)

        # Frequency bins
        freqs = np.fft.fftshift(np.fft.fftfreq(self.fft_size, 1/self.sample_rate))
        freqs += center_freq

        # Statistics
        avg_power = np.mean(fft_power_db)
        max_power = np.max(fft_power_db)
        noise_floor = np.percentile(fft_power_db, 50)

        # Detect signals (>15 dB above noise floor)
        threshold = noise_floor + 15
        signal_mask = fft_power_db > threshold

        # Find signal peaks
        signals = []
        if np.any(signal_mask):
            # Group consecutive bins into signals
            signal_regions = []
            in_signal = False
            start_idx = 0

            for i, is_signal in enumerate(signal_mask):
                if is_signal and not in_signal:
                    start_idx = i
                    in_signal = True
                elif not is_signal and in_signal:
                    signal_regions.append((start_idx, i))
                    in_signal = False

            if in_signal:
                signal_regions.append((start_idx, len(signal_mask)))

            # Extract signal info
            for start, end in signal_regions:
                peak_idx = start + np.argmax(fft_power_db[start:end])
                signals.append({
                    'frequency': freqs[peak_idx],
                    'power_db': fft_power_db[peak_idx],
                    'bandwidth': (end - start) * (self.sample_rate / self.fft_size),
                    'start_freq': freqs[start],
                    'end_freq': freqs[end-1]
                })

        return {
            'center_freq': center_freq,
            'frequencies': freqs,
            'power_db': fft_power_db,
            'avg_power': avg_power,
            'max_power': max_power,
            'noise_floor': noise_floor,
            'signals': signals,
            'timestamp': datetime.now().isoformat()
        }

    def scan_range(self, start_freq, end_freq, step=None, duration=0.1):
        """
        Scan a frequency range and return all detected signals

        Args:
            start_freq: Start frequency in Hz
            end_freq: End frequency in Hz
            step: Frequency step (default: sample_rate * 0.8 for 20% overlap)
            duration: Capture duration per step in seconds

        Returns:
            List of spectrum analysis results
        """
        if step is None:
            step = self.sample_rate * 0.8  # 20% overlap

        print(f"\n{'='*70}")
        print(f"WIDEBAND SPECTRUM SCAN")
        print(f"{'='*70}")
        print(f"Range: {start_freq/1e6:.3f} - {end_freq/1e6:.3f} MHz")
        print(f"Step: {step/1e6:.3f} MHz")
        print(f"Bandwidth per step: {self.sample_rate/1e6:.3f} MHz")

        total_steps = int((end_freq - start_freq) / step)
        print(f"Total steps: {total_steps}")
        print(f"Estimated time: {total_steps * (duration + 0.5):.1f} seconds")
        print(f"{'='*70}\n")

        results = []
        all_signals = []

        current_freq = start_freq
        step_num = 0

        while current_freq <= end_freq:
            step_num += 1

            # Progress indicator
            progress = (current_freq - start_freq) / (end_freq - start_freq) * 100
            print(f"[{progress:5.1f}%] Scanning {current_freq/1e6:8.3f} MHz... ", end='', flush=True)

            # Capture and analyze
            iq = self.capture_at_frequency(current_freq, duration)
            analysis = self.analyze_spectrum(iq, current_freq)

            if analysis:
                results.append(analysis)

                # Show results
                num_signals = len(analysis['signals'])
                if num_signals > 0:
                    print(f"✅ {num_signals} signal(s) detected!")
                    all_signals.extend(analysis['signals'])
                    for sig in analysis['signals']:
                        print(f"    → {sig['frequency']/1e6:.6f} MHz: {sig['power_db']:.1f} dB ({sig['bandwidth']/1e3:.1f} kHz)")
                else:
                    print(f"📻 Noise floor: {analysis['noise_floor']:.1f} dB")
            else:
                print("❌ Capture failed")

            current_freq += step

        print(f"\n{'='*70}")
        print(f"SCAN COMPLETE")
        print(f"{'='*70}")
        print(f"Total signals detected: {len(all_signals)}")

        return results, all_signals

    def save_results(self, results, signals, filename):
        """Save scan results to JSON file"""
        # Convert numpy arrays to lists for JSON serialization
        results_serializable = []
        for r in results:
            r_copy = r.copy()
            if 'frequencies' in r_copy:
                r_copy['frequencies'] = r_copy['frequencies'].tolist()
            if 'power_db' in r_copy:
                r_copy['power_db'] = r_copy['power_db'].tolist()
            results_serializable.append(r_copy)

        data = {
            'scan_parameters': {
                'sample_rate': self.sample_rate,
                'fft_size': self.fft_size,
                'gain': self.gain,
                'timestamp': datetime.now().isoformat()
            },
            'signals': signals,  # Already serializable
            'num_steps': len(results),
            'num_signals': len(signals)
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"\nResults saved to: {filename}")

    def print_signal_summary(self, signals):
        """Print a formatted summary of detected signals"""
        if not signals:
            print("\nNo signals detected.")
            return

        # Sort by power (strongest first)
        signals_sorted = sorted(signals, key=lambda x: x['power_db'], reverse=True)

        print(f"\n{'='*70}")
        print(f"DETECTED SIGNALS SUMMARY")
        print(f"{'='*70}")
        print(f"{'Rank':<6} {'Frequency (MHz)':<18} {'Power (dB)':<12} {'Bandwidth':<12} {'Type Estimate'}")
        print('-'*70)

        for i, sig in enumerate(signals_sorted[:50], 1):  # Top 50
            freq_mhz = sig['frequency'] / 1e6
            bw_khz = sig['bandwidth'] / 1e3

            # Estimate signal type based on frequency and bandwidth
            sig_type = self.estimate_signal_type(sig['frequency'], sig['bandwidth'])

            print(f"{i:<6} {freq_mhz:<18.6f} {sig['power_db']:<12.1f} {bw_khz:<12.1f} {sig_type}")

    def estimate_signal_type(self, freq, bandwidth):
        """Estimate signal type based on frequency and bandwidth"""
        freq_mhz = freq / 1e6
        bw_khz = bandwidth / 1e3

        # Frequency-based classification
        if 88 <= freq_mhz <= 108:
            return "FM Radio"
        elif 118 <= freq_mhz <= 137:
            return "Airband Voice"
        elif 137 <= freq_mhz <= 138:
            return "NOAA Satellite"
        elif 144 <= freq_mhz <= 148:
            return "2m Ham Radio"
        elif 156 <= freq_mhz <= 162:
            return "Marine VHF"
        elif 400 <= freq_mhz <= 512:
            if bw_khz < 25:
                return "PMR/Business"
            else:
                return "ISM / IoT"
        elif 700 <= freq_mhz <= 900:
            if bw_khz > 1000:
                return "LTE / 4G"
            else:
                return "Pager/Utility"
        elif 1090 <= freq_mhz <= 1091:
            return "ADS-B Aircraft"
        elif 1575 <= freq_mhz <= 1577:
            return "GPS L1"
        elif 1800 <= freq_mhz <= 1900:
            return "LTE / GSM"
        elif 2400 <= freq_mhz <= 2500:
            if bw_khz > 5000:
                return "WiFi 2.4 GHz"
            else:
                return "Bluetooth/ZigBee"
        elif 2600 <= freq_mhz <= 2700:
            return "LTE Band 7"
        else:
            return "Unknown"


def main():
    """Main scanning function with preset ranges"""

    scanner = SpectrumScanner(sample_rate=2e6, fft_size=2048, gain=40)

    # Define interesting frequency ranges to scan
    scan_profiles = {
        '1': {
            'name': 'FM Radio Broadcast',
            'start': 88e6,
            'end': 108e6,
            'step': 1.6e6,  # 80% of 2 MHz
        },
        '2': {
            'name': 'Aircraft (Airband + ADS-B)',
            'start': 118e6,
            'end': 137e6,
            'step': 1.6e6,
        },
        '3': {
            'name': 'VHF High (Ham 2m, Marine, Weather)',
            'start': 144e6,
            'end': 174e6,
            'step': 1.6e6,
        },
        '4': {
            'name': 'UHF (PMR, ISM 433, Ham 70cm)',
            'start': 400e6,
            'end': 470e6,
            'step': 1.6e6,
        },
        '5': {
            'name': 'LTE Band 20 (800 MHz)',
            'start': 790e6,
            'end': 862e6,
            'step': 1.6e6,
        },
        '6': {
            'name': 'GSM 900',
            'start': 925e6,
            'end': 960e6,
            'step': 1.6e6,
        },
        '7': {
            'name': 'ADS-B (1090 MHz)',
            'start': 1088e6,
            'end': 1092e6,
            'step': 1.6e6,
        },
        '8': {
            'name': 'LTE Band 3 (1800 MHz)',
            'start': 1805e6,
            'end': 1880e6,
            'step': 1.6e6,
        },
        '9': {
            'name': 'WiFi 2.4 GHz',
            'start': 2400e6,
            'end': 2500e6,
            'step': 1.6e6,
        },
        '10': {
            'name': 'LTE Band 7 (2600 MHz)',
            'start': 2620e6,
            'end': 2690e6,
            'step': 1.6e6,
        },
        'custom': {
            'name': 'Custom Range',
        }
    }

    print("\n" + "="*70)
    print(" "*20 + "WIDEBAND RF SCANNER")
    print("="*70)
    print("\nAvailable scan profiles:")
    print()

    for key, profile in scan_profiles.items():
        if key == 'custom':
            print(f"  {key}) {profile['name']} (enter manually)")
        else:
            start_mhz = profile['start'] / 1e6
            end_mhz = profile['end'] / 1e6
            span_mhz = (profile['end'] - profile['start']) / 1e6
            steps = int((profile['end'] - profile['start']) / profile['step'])
            time_est = steps * 0.6
            print(f"  {key}) {profile['name']:<35} ({start_mhz:.0f}-{end_mhz:.0f} MHz, ~{time_est:.0f}s)")

    print(f"\n  0) Full spectrum scan (70 MHz - 6 GHz) ⚠️  VERY LONG (~30 min)")
    print()

    choice = input("Select scan profile (or 'q' to quit): ").strip()

    if choice == 'q':
        return

    if choice == '0':
        # Full spectrum scan
        start_freq = 70e6
        end_freq = 6000e6
        step = 1.6e6
    elif choice in scan_profiles:
        profile = scan_profiles[choice]
        if choice == 'custom':
            try:
                start_freq = float(input("Start frequency (MHz): ")) * 1e6
                end_freq = float(input("End frequency (MHz): ")) * 1e6
                step = 1.6e6
            except ValueError:
                print("Invalid input!")
                return
        else:
            start_freq = profile['start']
            end_freq = profile['end']
            step = profile.get('step', 1.6e6)
    else:
        print("Invalid choice!")
        return

    # Confirm scan
    print(f"\nScanning {start_freq/1e6:.1f} - {end_freq/1e6:.1f} MHz")
    confirm = input("Proceed? (y/n): ").strip().lower()

    if confirm != 'y':
        print("Scan cancelled.")
        return

    # Perform scan
    start_time = time.time()
    results, signals = scanner.scan_range(start_freq, end_freq, step, duration=0.1)
    scan_time = time.time() - start_time

    # Print summary
    scanner.print_signal_summary(signals)

    print(f"\nScan completed in {scan_time:.1f} seconds")
    print(f"Scanned {(end_freq - start_freq)/1e6:.1f} MHz")
    print(f"Average scan rate: {(end_freq - start_freq)/1e6/scan_time:.2f} MHz/s")

    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"/home/static/sdr-utility/scans/scan_{timestamp}.json"
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    scanner.save_results(results, signals, output_file)

    # Export top signals to investigate
    if signals:
        top_signals_file = f"/home/static/sdr-utility/scans/top_signals_{timestamp}.txt"
        with open(top_signals_file, 'w') as f:
            f.write("TOP DETECTED SIGNALS - INVESTIGATION LIST\n")
            f.write("="*70 + "\n\n")

            signals_sorted = sorted(signals, key=lambda x: x['power_db'], reverse=True)
            for i, sig in enumerate(signals_sorted[:20], 1):  # Top 20
                f.write(f"{i}. {sig['frequency']/1e6:.6f} MHz\n")
                f.write(f"   Power: {sig['power_db']:.1f} dB\n")
                f.write(f"   Bandwidth: {sig['bandwidth']/1e3:.1f} kHz\n")
                f.write(f"   Type: {scanner.estimate_signal_type(sig['frequency'], sig['bandwidth'])}\n")
                f.write(f"   Capture command: uhd_rx_cfile -f {int(sig['frequency'])} -r 2e6 -N 4000000 -g 40 signal_{i}.cfile\n")
                f.write("\n")

        print(f"\nTop signals list saved to: {top_signals_file}")
        print("Use the capture commands to investigate specific signals!")


if __name__ == "__main__":
    main()
