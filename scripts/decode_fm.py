#!/usr/bin/env python3
"""
Simple FM demodulator for IQ captures
"""
import numpy as np
import sys
import os

def fm_demodulate(iq_samples, sample_rate=2e6, audio_rate=48000):
    """
    FM demodulate IQ samples
    Returns audio samples
    """
    # Calculate instantaneous frequency
    # f(t) = (1/2π) × d(phase)/dt

    # Get phase
    phase = np.angle(iq_samples)

    # Unwrap phase to avoid discontinuities
    phase_unwrapped = np.unwrap(phase)

    # Differentiate to get instantaneous frequency
    inst_freq = np.diff(phase_unwrapped)

    # Normalize and convert to audio
    audio = inst_freq / np.pi  # Normalize to [-1, 1]

    # Decimate to audio sample rate
    decimation = int(sample_rate / audio_rate)
    audio_decimated = audio[::decimation]

    return audio_decimated

def analyze_fm_station(filename, center_freq=100e6, sample_rate=2e6, station_offset=0):
    """
    Analyze and demodulate FM station from capture
    """
    print(f"\n{'='*60}")
    print(f"FM Demodulation")
    print(f"File: {os.path.basename(filename)}")
    print(f"Center Freq: {center_freq/1e6:.3f} MHz")
    print(f"Station Offset: {station_offset/1e3:+.1f} kHz")
    print(f"Target Freq: {(center_freq + station_offset)/1e6:.3f} MHz")
    print(f"{'='*60}\n")

    # Read IQ samples
    iq = np.fromfile(filename, dtype=np.complex64)
    print(f"Loaded {len(iq):,} IQ samples ({len(iq)/sample_rate:.1f} seconds)")

    # Frequency shift to baseband if needed
    if station_offset != 0:
        t = np.arange(len(iq)) / sample_rate
        shift = np.exp(-2j * np.pi * station_offset * t)
        iq = iq * shift
        print(f"Frequency shifted by {station_offset/1e3:+.1f} kHz")

    # Low-pass filter (simple moving average for demo)
    # FM station bandwidth is ~200 kHz
    filter_taps = 50
    iq_filtered = np.convolve(iq, np.ones(filter_taps)/filter_taps, mode='same')

    # FM demodulate
    audio = fm_demodulate(iq_filtered, sample_rate, audio_rate=48000)

    print(f"Demodulated to {len(audio):,} audio samples")

    # Analyze audio
    rms = np.sqrt(np.mean(audio**2))
    peak = np.max(np.abs(audio))

    print(f"\nAudio Statistics:")
    print(f"  RMS Level: {20*np.log10(rms):.1f} dB")
    print(f"  Peak Level: {20*np.log10(peak):.1f} dB")
    print(f"  Dynamic Range: {20*np.log10(peak/rms):.1f} dB")

    # Check if signal is present
    if rms > 0.01:  # Threshold for valid audio
        print(f"  Status: ✅ FM SIGNAL DETECTED - Station is transmitting!")

        # Save audio
        output_file = filename.replace('.cfile', f'_fm_{(center_freq+station_offset)/1e6:.3f}MHz.wav')
        save_wav(audio, output_file, 48000)
        print(f"\nSaved audio to: {output_file}")
        return True
    else:
        print(f"  Status: ❌ No FM signal (noise only)")
        return False

def save_wav(audio, filename, sample_rate=48000):
    """Save audio as WAV file"""
    import wave
    import struct

    # Normalize to 16-bit range
    audio = np.clip(audio, -1, 1)
    audio_int16 = (audio * 32767).astype(np.int16)

    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(audio_int16.tobytes())

if __name__ == "__main__":
    capture_file = os.path.expanduser("~/sdr-utility/captures/fm/fm_100mhz_2s.cfile")

    # Try to demodulate different FM stations we detected
    stations = [
        ("100.0 MHz", 0),           # Center frequency
        ("100.31 MHz", 311.1e3),    # Strong station at +311 kHz
        ("100.65 MHz", 650.6e3),    # Station at +650 kHz
        ("99.37 MHz", -632.5e3),    # Station at -632 kHz
    ]

    detected = 0
    for name, offset in stations:
        if analyze_fm_station(capture_file, 100e6, 2e6, offset):
            detected += 1

    print(f"\n{'='*60}")
    print(f"Summary: Detected {detected}/{len(stations)} FM stations")
    print(f"{'='*60}\n")
