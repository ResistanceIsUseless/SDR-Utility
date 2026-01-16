#!/usr/bin/env python3
"""
Analyze SDR IQ samples with DC offset removal and proper signal detection
"""

import struct
import math
import numpy as np
import sys

def analyze_iq_file(filename, sample_rate=2e6):
    """Analyze IQ samples with DC removal and spectral analysis"""

    try:
        with open(filename, 'rb') as f:
            data = f.read()

        if len(data) < 8000:
            print(f"ERROR: File too small ({len(data)} bytes)")
            return None

        # Parse IQ samples (complex float32)
        num_samples = len(data) // 8
        iq_samples = np.zeros(num_samples, dtype=np.complex64)

        for i in range(num_samples):
            offset = i * 8
            i_val, q_val = struct.unpack('ff', data[offset:offset+8])
            iq_samples[i] = complex(i_val, q_val)

        # Calculate statistics BEFORE DC removal
        raw_power = np.abs(iq_samples) ** 2
        raw_avg_power = np.mean(raw_power)
        raw_peak_power = np.max(raw_power)

        print(f"\n{'='*60}")
        print(f"File: {filename}")
        print(f"Samples: {num_samples:,}")
        print(f"\nRAW (Before DC Removal):")
        print(f"  Average I: {np.mean(iq_samples.real):.6f}")
        print(f"  Average Q: {np.mean(iq_samples.imag):.6f}")
        print(f"  RMS Power: {math.sqrt(raw_avg_power):.6f}")
        if raw_avg_power > 0:
            print(f"  Avg Power (dB): {10 * math.log10(raw_avg_power):.1f} dB")
        if raw_peak_power > 0:
            print(f"  Peak Power (dB): {10 * math.log10(raw_peak_power):.1f} dB")

        # REMOVE DC OFFSET
        dc_offset = np.mean(iq_samples)
        iq_samples_dc_removed = iq_samples - dc_offset

        print(f"\nDC OFFSET REMOVED:")
        print(f"  DC I offset: {dc_offset.real:.6f}")
        print(f"  DC Q offset: {dc_offset.imag:.6f}")
        print(f"  DC magnitude: {abs(dc_offset):.6f}")

        # Calculate power after DC removal
        power = np.abs(iq_samples_dc_removed) ** 2

        # Filter out zeros and invalid values
        valid_power = power[np.isfinite(power) & (power > 0)]

        if len(valid_power) < 100:
            print("\nERROR: Not enough valid samples after DC removal")
            return None

        # Calculate statistics
        avg_power = np.mean(valid_power)
        peak_power = np.percentile(valid_power, 95)  # 95th percentile
        noise_floor = np.percentile(valid_power, 10)  # 10th percentile
        std_power = np.std(valid_power)

        # Calculate SNR
        if noise_floor > 0 and peak_power > noise_floor:
            snr = peak_power / noise_floor
            snr_db = 10 * math.log10(snr)
        else:
            snr_db = 0

        # Calculate power in dBFS (assuming full scale = 1.0)
        avg_power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
        peak_power_db = 10 * math.log10(peak_power) if peak_power > 0 else -100
        noise_floor_db = 10 * math.log10(noise_floor) if noise_floor > 0 else -100

        # Check for modulation (variance in power)
        variance = np.var(valid_power)
        modulation_index = (std_power / avg_power) if avg_power > 0 else 0

        print(f"\nAFTER DC REMOVAL:")
        print(f"  Valid samples: {len(valid_power):,}")
        print(f"  Noise floor: {noise_floor_db:.1f} dBFS")
        print(f"  Average power: {avg_power_db:.1f} dBFS")
        print(f"  Peak power (95%): {peak_power_db:.1f} dBFS")
        print(f"  SNR: {snr_db:.1f} dB")
        print(f"  Modulation index: {modulation_index:.3f}")

        # Signal classification
        print(f"\nSIGNAL CLASSIFICATION:")
        if snr_db < 3:
            print("  Status: NOISE ONLY")
        elif snr_db < 10:
            print("  Status: WEAK SIGNAL")
        elif snr_db < 20:
            print("  Status: GOOD SIGNAL")
        else:
            print("  Status: STRONG SIGNAL")

        if modulation_index < 0.1:
            print("  Modulation: NONE (likely carrier/noise)")
        elif modulation_index < 0.5:
            print("  Modulation: LOW (simple carrier)")
        else:
            print("  Modulation: HIGH (complex signal)")

        # Check for saturation
        max_iq = np.max(np.abs(iq_samples_dc_removed))
        if max_iq > 0.9:
            print(f"  WARNING: SATURATION DETECTED (max IQ: {max_iq:.3f})")

        print(f"{'='*60}\n")

        return {
            'snr_db': snr_db,
            'avg_power_db': avg_power_db,
            'peak_power_db': peak_power_db,
            'noise_floor_db': noise_floor_db,
            'modulation_index': modulation_index,
            'dc_magnitude': abs(dc_offset),
            'max_iq': max_iq
        }

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: analyze_with_dc_removal.py <iq_file>")
        sys.exit(1)

    filename = sys.argv[1]
    result = analyze_iq_file(filename)

    if result:
        print("Analysis complete!")
    else:
        print("Analysis failed!")
        sys.exit(1)
