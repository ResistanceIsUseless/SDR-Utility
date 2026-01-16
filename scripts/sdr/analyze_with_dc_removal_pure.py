#!/usr/bin/env python3
"""
Analyze SDR IQ samples with DC offset removal (pure Python, no numpy)
"""

import struct
import math
import sys

def percentile(data, p):
    """Calculate percentile of sorted data"""
    sorted_data = sorted(data)
    k = (len(sorted_data) - 1) * p / 100
    f = math.floor(k)
    c = math.ceil(k)
    if f == c:
        return sorted_data[int(k)]
    d0 = sorted_data[int(f)] * (c - k)
    d1 = sorted_data[int(c)] * (k - f)
    return d0 + d1

def analyze_iq_file(filename, sample_rate=2e6):
    """Analyze IQ samples with DC removal"""

    try:
        with open(filename, 'rb') as f:
            data = f.read()

        if len(data) < 8000:
            print(f"ERROR: File too small ({len(data)} bytes)")
            return None

        # Parse IQ samples (complex float32)
        num_samples = len(data) // 8
        i_vals = []
        q_vals = []

        for idx in range(num_samples):
            offset = idx * 8
            i_val, q_val = struct.unpack('ff', data[offset:offset+8])
            i_vals.append(i_val)
            q_vals.append(q_val)

        # Calculate DC offset
        dc_i = sum(i_vals) / len(i_vals)
        dc_q = sum(q_vals) / len(q_vals)
        dc_magnitude = math.sqrt(dc_i**2 + dc_q**2)

        # Calculate RAW power (before DC removal)
        raw_powers = []
        for i, q in zip(i_vals, q_vals):
            power = i**2 + q**2
            if not math.isnan(power) and not math.isinf(power) and power > 0:
                raw_powers.append(power)

        raw_avg_power = sum(raw_powers) / len(raw_powers) if raw_powers else 0
        raw_peak_power = max(raw_powers) if raw_powers else 0

        print(f"\n{'='*60}")
        print(f"File: {filename}")
        print(f"Samples: {num_samples:,}")
        print(f"\nRAW (Before DC Removal):")
        print(f"  Average I: {dc_i:.6f}")
        print(f"  Average Q: {dc_q:.6f}")
        print(f"  DC Magnitude: {dc_magnitude:.6f}")
        if raw_avg_power > 0:
            print(f"  Avg Power (dB): {10 * math.log10(raw_avg_power):.1f} dB")
        if raw_peak_power > 0:
            print(f"  Peak Power (dB): {10 * math.log10(raw_peak_power):.1f} dB")

        # Remove DC offset and recalculate power
        powers_dc_removed = []
        iq_magnitudes = []

        for i, q in zip(i_vals, q_vals):
            i_corrected = i - dc_i
            q_corrected = q - dc_q
            power = i_corrected**2 + q_corrected**2
            magnitude = math.sqrt(i_corrected**2 + q_corrected**2)

            if not math.isnan(power) and not math.isinf(power) and power > 0:
                powers_dc_removed.append(power)
                iq_magnitudes.append(magnitude)

        if len(powers_dc_removed) < 100:
            print("\nERROR: Not enough valid samples after DC removal")
            return None

        # Calculate statistics
        avg_power = sum(powers_dc_removed) / len(powers_dc_removed)
        peak_power = percentile(powers_dc_removed, 95)
        noise_floor = percentile(powers_dc_removed, 10)

        # Calculate standard deviation
        variance = sum((p - avg_power)**2 for p in powers_dc_removed) / len(powers_dc_removed)
        std_power = math.sqrt(variance)

        # Calculate SNR
        if noise_floor > 0 and peak_power > noise_floor:
            snr_db = 10 * math.log10(peak_power / noise_floor)
        else:
            snr_db = 0

        # Power in dBFS (full scale = 1.0)
        avg_power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
        peak_power_db = 10 * math.log10(peak_power) if peak_power > 0 else -100
        noise_floor_db = 10 * math.log10(noise_floor) if noise_floor > 0 else -100

        # Modulation index
        modulation_index = (std_power / avg_power) if avg_power > 0 else 0

        # Max IQ magnitude
        max_iq = max(iq_magnitudes) if iq_magnitudes else 0

        print(f"\nDC OFFSET REMOVED:")
        print(f"  DC I offset: {dc_i:.6f}")
        print(f"  DC Q offset: {dc_q:.6f}")
        print(f"  DC magnitude: {dc_magnitude:.6f}")

        print(f"\nAFTER DC REMOVAL:")
        print(f"  Valid samples: {len(powers_dc_removed):,}")
        print(f"  Noise floor: {noise_floor_db:.1f} dBFS")
        print(f"  Average power: {avg_power_db:.1f} dBFS")
        print(f"  Peak power (95%): {peak_power_db:.1f} dBFS")
        print(f"  SNR: {snr_db:.1f} dB")
        print(f"  Modulation index: {modulation_index:.3f}")
        print(f"  Max IQ magnitude: {max_iq:.3f}")

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
        if max_iq > 0.9:
            print(f"  ⚠️  WARNING: SATURATION DETECTED")

        print(f"{'='*60}\n")

        return {
            'snr_db': snr_db,
            'avg_power_db': avg_power_db,
            'peak_power_db': peak_power_db,
            'noise_floor_db': noise_floor_db,
            'modulation_index': modulation_index,
            'dc_magnitude': dc_magnitude,
            'max_iq': max_iq
        }

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: analyze_with_dc_removal_pure.py <iq_file>")
        sys.exit(1)

    filename = sys.argv[1]
    result = analyze_iq_file(filename)

    if result:
        print("Analysis complete!")
    else:
        print("Analysis failed!")
        sys.exit(1)
