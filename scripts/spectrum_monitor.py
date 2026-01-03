#!/usr/bin/env python3
"""
Real-time Spectrum Monitor with Live Data Stream

Displays:
- Top: Live spectrum waterfall and FFT
- Bottom: Decoded data stream from detected signals
"""

import numpy as np
import subprocess
import os
import sys
import time
from datetime import datetime
from collections import deque
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.gridspec import GridSpec

class SpectrumMonitor:
    def __init__(self, center_freq=100e6, sample_rate=2e6, gain=40, fft_size=2048):
        self.center_freq = center_freq
        self.sample_rate = sample_rate
        self.gain = gain
        self.fft_size = fft_size
        self.uhd_images_dir = "/usr/share/uhd/4.9.0/images"

        # Waterfall history
        self.waterfall_history = deque(maxlen=100)

        # Detected signals history
        self.signal_log = deque(maxlen=50)

        # For live capture
        self.capture_process = None

    def capture_chunk(self):
        """Capture a chunk of samples from USRP to temp file"""
        import tempfile

        with tempfile.NamedTemporaryFile(suffix='.cfile', delete=False) as tmp:
            temp_file = tmp.name

        # Capture samples (small duration for real-time feel)
        num_samples = self.fft_size * 2  # Get 2x for smoother updates

        cmd = [
            "uhd_rx_cfile",
            "-f", str(int(self.center_freq)),
            "-r", str(int(self.sample_rate)),
            "-g", str(self.gain),
            "-N", str(num_samples),
            temp_file
        ]

        env = os.environ.copy()
        env['UHD_IMAGES_DIR'] = self.uhd_images_dir

        try:
            subprocess.run(cmd, env=env, stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL, timeout=5)
            return temp_file
        except:
            if os.path.exists(temp_file):
                os.unlink(temp_file)
            return None

    def read_iq_chunk(self):
        """Capture and read chunk of IQ data"""
        temp_file = self.capture_chunk()
        if temp_file is None:
            return None

        try:
            iq = np.fromfile(temp_file, dtype=np.complex64)
            os.unlink(temp_file)
            return iq[:self.fft_size] if len(iq) >= self.fft_size else None
        except:
            if os.path.exists(temp_file):
                os.unlink(temp_file)
            return None

    def analyze_chunk(self, iq_samples):
        """Analyze IQ chunk and return spectrum + detected signals"""
        if iq_samples is None or len(iq_samples) < self.fft_size:
            return None, []

        # Compute FFT
        fft_result = np.fft.fftshift(np.fft.fft(iq_samples[:self.fft_size]))
        fft_power = np.abs(fft_result) ** 2
        fft_power_db = 10 * np.log10(fft_power + 1e-10)

        # Frequency bins
        freqs = np.fft.fftshift(np.fft.fftfreq(self.fft_size, 1/self.sample_rate))
        freqs += self.center_freq

        # Detect signals
        noise_floor = np.percentile(fft_power_db, 50)
        threshold = noise_floor + 15

        signal_mask = fft_power_db > threshold
        signals = []

        if np.any(signal_mask):
            # Find peaks
            peak_indices = np.where(signal_mask)[0]
            if len(peak_indices) > 0:
                # Group nearby bins
                groups = []
                current_group = [peak_indices[0]]

                for idx in peak_indices[1:]:
                    if idx - current_group[-1] <= 3:  # Within 3 bins
                        current_group.append(idx)
                    else:
                        groups.append(current_group)
                        current_group = [idx]
                groups.append(current_group)

                # Extract signal info
                for group in groups[:10]:  # Max 10 signals
                    peak_idx = group[np.argmax([fft_power_db[i] for i in group])]
                    signals.append({
                        'freq': freqs[peak_idx],
                        'power': fft_power_db[peak_idx],
                        'bandwidth': len(group) * (self.sample_rate / self.fft_size)
                    })

        return {
            'freqs': freqs,
            'power_db': fft_power_db,
            'noise_floor': noise_floor,
            'signals': signals
        }, signals

    def decode_signal_type(self, freq, bandwidth):
        """Estimate what the signal might be"""
        freq_mhz = freq / 1e6
        bw_khz = bandwidth / 1e3

        if 88 <= freq_mhz <= 108:
            if bw_khz > 100:
                return f"FM Radio Station ({freq_mhz:.3f} MHz)"
            else:
                return f"FM Subcarrier ({freq_mhz:.3f} MHz)"
        elif 118 <= freq_mhz <= 137:
            return f"Aviation Voice ({freq_mhz:.3f} MHz)"
        elif 1090 <= freq_mhz <= 1091:
            return f"ADS-B Aircraft ({freq_mhz:.3f} MHz)"
        elif 433 <= freq_mhz <= 434:
            return f"ISM Device ({freq_mhz:.3f} MHz, {bw_khz:.1f} kHz)"
        elif 700 <= freq_mhz <= 900:
            if bw_khz > 1000:
                return f"LTE Cell ({freq_mhz:.3f} MHz)"
            else:
                return f"Pager/Utility ({freq_mhz:.3f} MHz)"
        else:
            return f"Unknown ({freq_mhz:.3f} MHz, {bw_khz:.1f} kHz)"

    def visualize_live(self, duration=60):
        """Create live visualization with spectrum and data stream"""

        print(f"\n{'='*70}")
        print(f"LIVE SPECTRUM MONITOR")
        print(f"{'='*70}")
        print(f"Center Frequency: {self.center_freq/1e6:.3f} MHz")
        print(f"Sample Rate: {self.sample_rate/1e6:.3f} MS/s")
        print(f"Bandwidth: {self.sample_rate/1e6:.3f} MHz")
        print(f"Duration: {duration} seconds")
        print(f"{'='*70}\n")
        print("Starting live capture...")

        # Setup plot
        fig = plt.figure(figsize=(14, 10))
        gs = GridSpec(3, 2, figure=fig, height_ratios=[2, 2, 1])

        # Spectrum plot (top left)
        ax_spectrum = fig.add_subplot(gs[0, :])
        ax_spectrum.set_title(f'Live Spectrum - {self.center_freq/1e6:.3f} MHz', fontsize=14, fontweight='bold')
        ax_spectrum.set_xlabel('Frequency (MHz)')
        ax_spectrum.set_ylabel('Power (dB)')
        ax_spectrum.grid(True, alpha=0.3)

        # Waterfall plot (middle)
        ax_waterfall = fig.add_subplot(gs[1, :])
        ax_waterfall.set_title('Waterfall (Time vs Frequency)', fontsize=14, fontweight='bold')
        ax_waterfall.set_xlabel('Frequency (MHz)')
        ax_waterfall.set_ylabel('Time (seconds ago)')

        # Data stream (bottom)
        ax_data = fig.add_subplot(gs[2, :])
        ax_data.set_title('Detected Signals Stream', fontsize=12, fontweight='bold')
        ax_data.axis('off')

        # Initialize plots
        line_spectrum, = ax_spectrum.plot([], [], 'b-', linewidth=1, label='Current')
        line_noise, = ax_spectrum.plot([], [], 'r--', linewidth=1, label='Noise Floor')
        ax_spectrum.legend()

        waterfall_img = None
        data_text = ax_data.text(0.02, 0.98, '', transform=ax_data.transAxes,
                                  verticalalignment='top', fontfamily='monospace',
                                  fontsize=8)

        plt.tight_layout()

        # Animation update function
        frame_count = [0]
        start_time = time.time()

        def update(frame):
            if time.time() - start_time > duration:
                plt.close()
                return

            # Read and analyze chunk
            iq = self.read_iq_chunk()
            result, signals = self.analyze_chunk(iq)

            if result is None:
                return

            frame_count[0] += 1

            # Update spectrum plot
            freqs_mhz = result['freqs'] / 1e6
            line_spectrum.set_data(freqs_mhz, result['power_db'])
            line_noise.set_data([freqs_mhz[0], freqs_mhz[-1]],
                               [result['noise_floor'], result['noise_floor']])

            ax_spectrum.set_xlim(freqs_mhz[0], freqs_mhz[-1])
            ax_spectrum.set_ylim(result['noise_floor'] - 10,
                                np.max(result['power_db']) + 5)

            # Update waterfall
            self.waterfall_history.append(result['power_db'])

            if len(self.waterfall_history) > 1:
                nonlocal waterfall_img
                waterfall_data = np.array(self.waterfall_history)

                if waterfall_img is None:
                    waterfall_img = ax_waterfall.imshow(
                        waterfall_data,
                        aspect='auto',
                        cmap='viridis',
                        extent=[freqs_mhz[0], freqs_mhz[-1],
                               len(self.waterfall_history) * 0.1, 0],
                        interpolation='bilinear'
                    )
                    plt.colorbar(waterfall_img, ax=ax_waterfall, label='Power (dB)')
                else:
                    waterfall_img.set_data(waterfall_data)
                    waterfall_img.set_extent([freqs_mhz[0], freqs_mhz[-1],
                                             len(self.waterfall_history) * 0.1, 0])

            # Update data stream
            timestamp = datetime.now().strftime("%H:%M:%S")

            if signals:
                for sig in signals:
                    decoded = self.decode_signal_type(sig['freq'], sig['bandwidth'])
                    log_entry = f"[{timestamp}] {sig['power']:6.1f}dB | {decoded}"
                    self.signal_log.append(log_entry)

            # Display last 15 log entries
            log_text = "\n".join(list(self.signal_log)[-15:])
            data_text.set_text(log_text)

            # Update title with stats
            elapsed = time.time() - start_time
            fps = frame_count[0] / elapsed
            ax_spectrum.set_title(
                f'Live Spectrum - {self.center_freq/1e6:.3f} MHz | ' +
                f'Signals: {len(signals)} | FPS: {fps:.1f} | Elapsed: {elapsed:.1f}s',
                fontsize=14, fontweight='bold'
            )

        # Start animation
        ani = animation.FuncAnimation(fig, update, interval=100, blit=False, cache_frame_data=False)

        plt.show()
        print("\nMonitoring complete.")

    def terminal_monitor(self, duration=60):
        """Terminal-based monitor (no GUI needed)"""

        print(f"\n{'='*70}")
        print(f"TERMINAL SPECTRUM MONITOR")
        print(f"{'='*70}")
        print(f"Center Frequency: {self.center_freq/1e6:.3f} MHz")
        print(f"Sample Rate: {self.sample_rate/1e6:.3f} MS/s")
        print(f"Bandwidth: ±{self.sample_rate/2e6:.3f} MHz")
        print(f"Duration: {duration} seconds")
        print(f"{'='*70}\n")

        start_time = time.time()
        frame = 0

        try:
            while time.time() - start_time < duration:
                # Read chunk
                iq = self.read_iq_chunk()
                result, signals = self.analyze_chunk(iq)

                if result is None:
                    continue

                frame += 1
                elapsed = time.time() - start_time

                # Clear screen
                os.system('clear' if os.name == 'posix' else 'cls')

                # Header
                print(f"\n{'='*70}")
                print(f"LIVE SPECTRUM | {self.center_freq/1e6:.3f} MHz | Frame: {frame} | {elapsed:.1f}s")
                print(f"{'='*70}\n")

                # Spectrum bar chart (ASCII)
                self.draw_ascii_spectrum(result['power_db'], result['freqs'], result['noise_floor'])

                print(f"\n{'='*70}")
                print(f"DETECTED SIGNALS ({len(signals)} active)")
                print(f"{'='*70}\n")

                if signals:
                    print(f"{'Frequency':<18} {'Power':<12} {'Type'}")
                    print('-'*70)
                    for sig in signals[:10]:  # Top 10
                        decoded = self.decode_signal_type(sig['freq'], sig['bandwidth'])
                        print(f"{sig['freq']/1e6:<18.6f} {sig['power']:<12.1f} {decoded}")
                else:
                    print("No signals detected above threshold")

                print(f"\n{'='*70}")
                print("Press Ctrl+C to stop")
                print(f"{'='*70}")

                time.sleep(0.5)  # Update every 500ms

        except KeyboardInterrupt:
            print("\n\nStopping monitor...")
            print("Cleanup complete.")

    def draw_ascii_spectrum(self, power_db, freqs, noise_floor, width=60, height=20):
        """Draw ASCII art spectrum"""

        # Downsample for display
        bins = min(width, len(power_db))
        indices = np.linspace(0, len(power_db)-1, bins, dtype=int)

        power_display = power_db[indices]
        freqs_display = freqs[indices]

        # Normalize to height
        min_db = noise_floor - 5
        max_db = np.max(power_display)
        range_db = max_db - min_db

        if range_db == 0:
            range_db = 1

        print(f"Power Range: {min_db:.1f} to {max_db:.1f} dB | Noise: {noise_floor:.1f} dB\n")

        # Draw spectrum
        for h in range(height, 0, -1):
            threshold_db = min_db + (h / height) * range_db
            line = ""

            for p in power_display:
                if p >= threshold_db:
                    line += "█"
                elif p >= threshold_db - (range_db / height / 2):
                    line += "▄"
                else:
                    line += " "

            # Add dB scale
            db_label = f"{threshold_db:5.1f} dB |"
            print(f"{db_label} {line}")

        # Frequency axis
        print(" " * 11 + "-" * width)
        freq_start = freqs_display[0] / 1e6
        freq_end = freqs_display[-1] / 1e6
        print(f" " * 11 + f"{freq_start:.2f} MHz" + " " * (width - 20) + f"{freq_end:.2f} MHz")


def main():
    """Main function with options"""

    print("\n" + "="*70)
    print(" " * 20 + "SPECTRUM MONITOR")
    print("="*70)
    print("\nMonitor Modes:")
    print("  1) Graphical (matplotlib) - Spectrum + Waterfall + Data Stream")
    print("  2) Terminal (ASCII) - Real-time text display")
    print()

    mode = input("Select mode (1 or 2): ").strip()

    print("\nFrequency Presets:")
    print("  1) FM Radio (100 MHz)")
    print("  2) ADS-B Aircraft (1090 MHz)")
    print("  3) ISM 433 MHz")
    print("  4) LTE Band 20 (806 MHz)")
    print("  5) Custom")
    print()

    preset = input("Select preset (1-5): ").strip()

    freq_map = {
        '1': 100e6,
        '2': 1090e6,
        '3': 433.92e6,
        '4': 806e6
    }

    if preset in freq_map:
        center_freq = freq_map[preset]
    elif preset == '5':
        try:
            center_freq = float(input("Enter frequency (MHz): ")) * 1e6
        except:
            print("Invalid frequency!")
            return
    else:
        print("Invalid preset!")
        return

    try:
        duration = int(input("Duration (seconds, default 60): ").strip() or "60")
    except:
        duration = 60

    # Create monitor
    monitor = SpectrumMonitor(center_freq=center_freq, sample_rate=2e6, gain=40)

    if mode == '1':
        print("\nLaunching graphical monitor...")
        monitor.visualize_live(duration=duration)
    elif mode == '2':
        print("\nLaunching terminal monitor...")
        monitor.terminal_monitor(duration=duration)
    else:
        print("Invalid mode!")


if __name__ == "__main__":
    main()
