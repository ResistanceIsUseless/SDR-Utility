#!/usr/bin/env python3
"""
Quick signal power analyzer for captured IQ samples
Reads complex float32 samples and shows signal strength
"""

import sys
import struct
import math

def analyze_signal(filename, sample_rate=2e6):
    """Analyze IQ samples and show power statistics"""

    print(f"\nAnalyzing: {filename}")
    print(f"Sample Rate: {sample_rate/1e6} MS/s")
    print("-" * 50)

    try:
        with open(filename, 'rb') as f:
            # Read all samples (complex float32 = 8 bytes each)
            data = f.read()
            num_samples = len(data) // 8

            print(f"Total samples: {num_samples:,}")
            print(f"Duration: {num_samples/sample_rate:.2f} seconds")
            print(f"File size: {len(data)/1e6:.2f} MB")
            print()

            # Calculate power levels
            # Sample every 1000th sample for speed
            powers = []
            max_power = 0

            for i in range(0, len(data) - 8, 8000):  # Sample every 1000
                # Unpack complex float (I and Q)
                i_val, q_val = struct.unpack('ff', data[i:i+8])

                # Calculate power: I^2 + Q^2
                power = i_val * i_val + q_val * q_val
                powers.append(power)

                if power > max_power:
                    max_power = power

            if not powers:
                print("No samples to analyze")
                return

            # Statistics
            avg_power = sum(powers) / len(powers)

            # Convert to dB (relative to 1.0)
            avg_power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
            max_power_db = 10 * math.log10(max_power) if max_power > 0 else -100

            # Calculate noise floor estimate (10th percentile)
            sorted_powers = sorted(powers)
            noise_floor = sorted_powers[len(sorted_powers) // 10]
            noise_floor_db = 10 * math.log10(noise_floor) if noise_floor > 0 else -100

            # Signal detection (90th percentile)
            signal_peak = sorted_powers[int(len(sorted_powers) * 0.9)]
            signal_peak_db = 10 * math.log10(signal_peak) if signal_peak > 0 else -100

            snr = signal_peak_db - noise_floor_db

            print("Power Analysis:")
            print(f"  Average Power:   {avg_power_db:6.1f} dB")
            print(f"  Peak Power:      {max_power_db:6.1f} dB")
            print(f"  Noise Floor:     {noise_floor_db:6.1f} dB (10th percentile)")
            print(f"  Signal Peak:     {signal_peak_db:6.1f} dB (90th percentile)")
            print(f"  Estimated SNR:   {snr:6.1f} dB")
            print()

            # Interpretation
            print("Signal Strength Assessment:")
            if snr > 20:
                print("  ✓ STRONG SIGNAL detected!")
                print("    FM station should be clearly visible")
            elif snr > 10:
                print("  ✓ MODERATE SIGNAL detected")
                print("    FM station should be decodable")
            elif snr > 5:
                print("  ⚠ WEAK SIGNAL detected")
                print("    FM station may be barely visible")
            else:
                print("  ✗ NO CLEAR SIGNAL - mostly noise")
                print("    Possible issues:")
                print("      - Antenna not connected properly")
                print("      - Antenna not positioned well")
                print("      - No FM station at this frequency")
                print("      - Interference or local noise")

    except FileNotFoundError:
        print(f"Error: File not found: {filename}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: analyze_signal.py <sample_file.dat> [sample_rate]")
        print("\nExample:")
        print("  analyze_signal.py /tmp/test_txrx.dat 2000000")
        sys.exit(1)

    filename = sys.argv[1]
    sample_rate = float(sys.argv[2]) if len(sys.argv) > 2 else 2e6

    analyze_signal(filename, sample_rate)
