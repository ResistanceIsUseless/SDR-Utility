#!/usr/bin/env python3
"""
Analyze RF spectrum from IQ capture files
"""
import numpy as np
import sys

def analyze_cfile(filename, sample_rate=2e6, center_freq=100e6):
    """Analyze a .cfile (complex float32) capture"""
    print(f"\n{'='*60}")
    print(f"Analyzing: {filename}")
    print(f"Sample Rate: {sample_rate/1e6:.2f} MS/s")
    print(f"Center Frequency: {center_freq/1e6:.2f} MHz")
    print(f"{'='*60}\n")

    # Read IQ samples (complex float32)
    try:
        iq = np.fromfile(filename, dtype=np.complex64)
    except:
        print(f"Error: Could not read {filename}")
        return

    num_samples = len(iq)
    duration = num_samples / sample_rate

    print(f"Samples: {num_samples:,}")
    print(f"Duration: {duration:.3f} seconds")
    print(f"File Size: {num_samples * 8 / 1024 / 1024:.1f} MB\n")

    # Calculate power statistics
    power = np.abs(iq) ** 2
    avg_power = np.mean(power)
    max_power = np.max(power)
    std_power = np.std(power)

    print(f"Power Statistics:")
    print(f"  Average Power: {10*np.log10(avg_power):.2f} dB")
    print(f"  Peak Power: {10*np.log10(max_power):.2f} dB")
    print(f"  Std Dev: {10*np.log10(std_power):.2f} dB")
    print(f"  Peak/Avg Ratio: {10*np.log10(max_power/avg_power):.2f} dB\n")

    # FFT analysis (use first 1024k samples for speed)
    fft_size = min(1024*1024, num_samples)
    samples_for_fft = iq[:fft_size]

    # Compute FFT
    fft_result = np.fft.fftshift(np.fft.fft(samples_for_fft))
    fft_power = np.abs(fft_result) ** 2
    fft_power_db = 10 * np.log10(fft_power + 1e-10)  # Avoid log(0)

    # Find frequency bins
    freqs = np.fft.fftshift(np.fft.fftfreq(fft_size, 1/sample_rate)) + center_freq

    # Find peaks
    threshold = np.percentile(fft_power_db, 99)  # Top 1%
    peak_indices = np.where(fft_power_db > threshold)[0]

    print(f"FFT Analysis (threshold: {threshold:.1f} dB):")
    print(f"  FFT Size: {fft_size:,} samples")
    print(f"  Frequency Resolution: {sample_rate/fft_size:.2f} Hz")
    print(f"  Number of Peaks Found: {len(peak_indices)}\n")

    # Show top 10 peaks
    if len(peak_indices) > 0:
        peak_powers = fft_power_db[peak_indices]
        sorted_idx = np.argsort(peak_powers)[::-1][:10]

        print("Top 10 Frequency Peaks:")
        print(f"{'Freq (MHz)':<15} {'Power (dB)':<15} {'Offset (kHz)'}")
        print("-" * 50)
        for idx in sorted_idx:
            peak_idx = peak_indices[idx]
            freq = freqs[peak_idx]
            power = fft_power_db[peak_idx]
            offset = (freq - center_freq) / 1e3
            print(f"{freq/1e6:<15.6f} {power:<15.2f} {offset:+.1f}")

    # Detect activity
    noise_floor = np.percentile(fft_power_db, 50)  # Median
    signal_present = np.any(fft_power_db > noise_floor + 20)  # 20dB above noise

    print(f"\nSignal Detection:")
    print(f"  Noise Floor: {noise_floor:.1f} dB")
    print(f"  Signal Present: {'YES - Active transmissions detected!' if signal_present else 'NO - Only noise'}")

    # Bandwidth occupancy
    active_bins = np.sum(fft_power_db > noise_floor + 10) / fft_size * 100
    print(f"  Bandwidth Occupancy: {active_bins:.2f}%")

if __name__ == "__main__":
    # Analyze captures
    captures = [
        ("~/sdr-utility/captures/fm/fm_100mhz_2s.cfile", 2e6, 100e6),
        ("~/sdr-utility/captures/adsb/adsb_1090mhz_2s.cfile", 2e6, 1090e6),
        ("~/sdr-utility/captures/ism433/ism_433mhz_2s.cfile", 2e6, 433.92e6),
    ]

    for filename, sr, cf in captures:
        # Expand ~ to home directory
        import os
        filename = os.path.expanduser(filename)
        if os.path.exists(filename):
            analyze_cfile(filename, sr, cf)
        else:
            print(f"\nFile not found: {filename}")

    print(f"\n{'='*60}")
    print("Analysis Complete!")
    print(f"{'='*60}\n")
