#!/usr/bin/python3
"""
BLE PCAP Analyzer
Parses BLE packet captures to:
1. Enumerate discovered devices
2. Identify potentially sensitive data exposures
"""

import sys
import re
import struct
from collections import defaultdict
from datetime import datetime

try:
    from scapy.all import rdpcap, Packet
    from scapy.layers.bluetooth import *
except ImportError:
    print("ERROR: scapy not installed")
    print("Install with: python3 -m pip install scapy")
    sys.exit(1)


class BLEDevice:
    """Represents a discovered BLE device"""
    def __init__(self, addr):
        self.addr = addr
        self.name = None
        self.manufacturer = None
        self.services = set()
        self.rssi = []
        self.packet_count = 0
        self.adv_data = []
        self.flags = set()

    def add_rssi(self, rssi):
        if rssi:
            self.rssi.append(rssi)

    def avg_rssi(self):
        return sum(self.rssi) / len(self.rssi) if self.rssi else None


class SensitiveDataFinder:
    """Detects potentially sensitive data in BLE packets"""

    # Patterns for sensitive data
    PATTERNS = {
        'email': (r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'Email Address'),
        'phone': (r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', 'Phone Number'),
        'ssn': (r'\b\d{3}-\d{2}-\d{4}\b', 'SSN'),
        'credit_card': (r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', 'Credit Card Pattern'),
        'password_keyword': (r'(?i)(password|passwd|pwd|pass|secret|token|api[_-]?key)[\s:=]+[^\s]+', 'Password/Secret Keyword'),
        'api_key': (r'(?i)(api[_-]?key|apikey|api[_-]?secret)[\s:="\']+([\w\-]{16,})', 'API Key'),
        'auth_token': (r'(?i)(auth[_-]?token|bearer|jwt)[\s:="\']+([\w\-\.]{20,})', 'Auth Token'),
        'private_key': (r'-----BEGIN (RSA |EC )?PRIVATE KEY-----', 'Private Key'),
        'aws_key': (r'AKIA[0-9A-Z]{16}', 'AWS Access Key'),
    }

    # Known sensitive UUIDs
    SENSITIVE_UUIDS = {
        '0x2a37': 'Heart Rate Measurement',
        '0x2a29': 'Manufacturer Name',
        '0x2a24': 'Model Number',
        '0x2a25': 'Serial Number',
        '0x2a27': 'Hardware Revision',
        '0x2a26': 'Firmware Revision',
        '0x2a50': 'PnP ID',
        '0x2a00': 'Device Name',
        '0x180f': 'Battery Service',
        '0x1800': 'Generic Access',
        '0x1801': 'Generic Attribute',
    }

    def __init__(self):
        self.findings = []

    def analyze_bytes(self, data, source, context=""):
        """Analyze byte data for sensitive patterns"""
        if not data:
            return

        # Try to decode as string
        try:
            text = data.decode('utf-8', errors='ignore')
            if len(text) > 3:  # Only check meaningful strings
                for pattern_name, (pattern, description) in self.PATTERNS.items():
                    matches = re.finditer(pattern, text)
                    for match in matches:
                        self.findings.append({
                            'type': 'SENSITIVE_DATA',
                            'severity': 'HIGH',
                            'category': description,
                            'data': match.group(0)[:100],  # Limit length
                            'source': source,
                            'context': context
                        })
        except:
            pass

        # Check for long unencrypted data transmissions
        if len(data) > 100:
            self.findings.append({
                'type': 'UNENCRYPTED_DATA',
                'severity': 'MEDIUM',
                'category': 'Large Unencrypted Transmission',
                'data': f'{len(data)} bytes',
                'source': source,
                'context': context
            })

    def check_uuid(self, uuid, value, source):
        """Check if UUID is potentially sensitive"""
        uuid_str = str(uuid).lower()
        if uuid_str in self.SENSITIVE_UUIDS:
            self.findings.append({
                'type': 'SENSITIVE_UUID',
                'severity': 'MEDIUM',
                'category': self.SENSITIVE_UUIDS[uuid_str],
                'data': value[:100] if value else 'N/A',
                'source': source,
                'context': f'UUID: {uuid_str}'
            })


def parse_manufacturer_data(data):
    """Parse manufacturer-specific advertising data"""
    if len(data) < 2:
        return None
    company_id = struct.unpack('<H', data[:2])[0]

    # Known company IDs
    companies = {
        0x004C: 'Apple',
        0x0006: 'Microsoft',
        0x00E0: 'Google',
        0x0075: 'Samsung',
        0x0087: 'Garmin',
        0x02E5: 'Fitbit',
    }

    return companies.get(company_id, f'Unknown (0x{company_id:04X})')


def parse_catsniffer_packet(raw_data):
    """Parse CatSniffer Radio Packet format"""
    # CatSniffer header format (17 bytes):
    # Version (1B) | Length (2B) | Interface Type (1B) | Interface ID (2B) |
    # Protocol (1B) | PHY (1B) | Frequency (4B) | Channel (2B) | RSSI (1B) | Status (1B)

    if len(raw_data) < 17:
        return None, None, None

    # Parse header
    version = raw_data[0]
    length = struct.unpack('<H', raw_data[1:3])[0]
    protocol = raw_data[6]
    rssi = struct.unpack('b', raw_data[14:15])[0]  # signed byte
    status = raw_data[15]

    # Extract BLE payload (skip 17-byte header)
    ble_payload = raw_data[17:]

    return ble_payload, rssi, (status & 0x80) != 0  # FCS OK if bit 7 is set


def analyze_pcap(filename):
    """Main analysis function"""
    print(f"[*] Analyzing BLE PCAP: {filename}")
    print(f"[*] Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    try:
        packets = rdpcap(filename)
    except Exception as e:
        print(f"ERROR: Could not read PCAP file: {e}")
        sys.exit(1)

    devices = {}
    sensitive_finder = SensitiveDataFinder()
    total_packets = len(packets)

    print(f"[*] Total packets: {total_packets}\n")

    # Parse packets
    for i, pkt in enumerate(packets):
        if i % 100 == 0 and i > 0:
            print(f"[*] Processing packet {i}/{total_packets}...", end='\r')

        try:
            raw_data = bytes(pkt)

            # Parse CatSniffer packet format
            ble_payload, rssi, fcs_ok = parse_catsniffer_packet(raw_data)

            if not ble_payload or len(ble_payload) < 6:
                continue

            # BLE packet structure (simplified):
            # For advertising: Access Address (4B) + Header (2B) + AdvA (6B) + Data

            # Skip access address and header (6 bytes) to get to MAC address
            if len(ble_payload) >= 12:
                # The advertiser address (AdvA) is typically at offset 6
                mac_bytes = ble_payload[6:12]
                mac = ':'.join(f'{b:02x}' for b in reversed(mac_bytes))  # BLE uses little-endian

                if mac not in devices:
                    devices[mac] = BLEDevice(mac)

                devices[mac].packet_count += 1
                devices[mac].add_rssi(rssi)

            # Analyze BLE payload for sensitive content
            sensitive_finder.analyze_bytes(ble_payload, mac if mac in devices else "unknown", f"Packet #{i}")

            # Parse BLE advertising data (AD structures)
            # AD structure format: Length (1B) | Type (1B) | Data (variable)
            # Advertising data starts after: Access Addr (4B) + Header (2B) + AdvA (6B) = offset 12
            if len(ble_payload) > 12:
                ad_data = ble_payload[12:]  # Skip to advertising data
                offset = 0

                while offset < len(ad_data) - 1:
                    ad_length = ad_data[offset]
                    if ad_length == 0 or offset + ad_length >= len(ad_data):
                        break

                    ad_type = ad_data[offset + 1]
                    ad_value = ad_data[offset + 2:offset + 1 + ad_length]

                    # Check for device name (0x08 = short name, 0x09 = complete name)
                    if ad_type in [0x08, 0x09]:
                        try:
                            name = ad_value.decode('utf-8', errors='ignore').strip()
                            if name and len(name) > 1 and name.isprintable():
                                if mac in devices and not devices[mac].name:
                                    devices[mac].name = name
                        except:
                            pass

                    # Check for manufacturer data (0xFF)
                    elif ad_type == 0xFF:
                        mfg_name = parse_manufacturer_data(ad_value)
                        if mfg_name and mac in devices and not devices[mac].manufacturer:
                            devices[mac].manufacturer = mfg_name

                    offset += 1 + ad_length

        except Exception as e:
            # Skip problematic packets
            continue

    print(" " * 80, end='\r')  # Clear progress line

    # Print results
    print("=" * 80)
    print("DISCOVERED BLE DEVICES")
    print("=" * 80)

    if not devices:
        print("No BLE devices found. This could mean:")
        print("  - PCAP file doesn't contain BLE data")
        print("  - Data is encrypted/encoded differently")
        print("  - Try using: tshark -r file.pcap -Y 'btle' to verify BLE packets")
    else:
        print(f"\nTotal devices discovered: {len(devices)}\n")

        # Sort by packet count
        sorted_devices = sorted(devices.values(), key=lambda d: d.packet_count, reverse=True)

        for idx, dev in enumerate(sorted_devices, 1):
            print(f"\n[{idx}] Device: {dev.addr}")
            print(f"    Name:         {dev.name or 'Unknown'}")
            print(f"    Manufacturer: {dev.manufacturer or 'Unknown'}")
            print(f"    Packets:      {dev.packet_count}")
            if dev.avg_rssi():
                print(f"    Avg RSSI:     {dev.avg_rssi():.1f} dBm")

    # Print sensitive data findings
    print("\n" + "=" * 80)
    print("SENSITIVE DATA ANALYSIS")
    print("=" * 80)

    if not sensitive_finder.findings:
        print("\n✓ No obvious sensitive data patterns detected")
        print("  Note: This doesn't guarantee safety - encrypted or encoded data")
        print("  may still contain sensitive information.")
    else:
        print(f"\n⚠ Found {len(sensitive_finder.findings)} potential security concerns:\n")

        # Group by severity
        by_severity = defaultdict(list)
        for finding in sensitive_finder.findings:
            by_severity[finding['severity']].append(finding)

        for severity in ['HIGH', 'MEDIUM', 'LOW']:
            if severity in by_severity:
                print(f"\n{severity} SEVERITY ({len(by_severity[severity])} findings):")
                print("-" * 80)
                for finding in by_severity[severity][:10]:  # Limit output
                    print(f"\n  Type:     {finding['category']}")
                    print(f"  Source:   {finding['source']}")
                    print(f"  Data:     {finding['data']}")
                    if finding['context']:
                        print(f"  Context:  {finding['context']}")

                if len(by_severity[severity]) > 10:
                    print(f"\n  ... and {len(by_severity[severity]) - 10} more")

    # Summary recommendations
    print("\n" + "=" * 80)
    print("SECURITY RECOMMENDATIONS")
    print("=" * 80)
    print("""
1. Device Enumeration:
   - Review all discovered devices for unauthorized BLE peripherals
   - Check manufacturer IDs for unknown/suspicious vendors
   - Monitor for devices appearing unexpectedly

2. Sensitive Data:
   - Any plaintext credentials should trigger immediate password changes
   - Unencrypted health data may violate HIPAA/privacy regulations
   - API keys/tokens found should be rotated immediately

3. Further Analysis:
   - Use Wireshark to inspect individual packets manually
   - Check for BLE pairing/bonding attempts (potential MITM)
   - Look for service UUIDs that reveal device capabilities
   - Export specific device traffic for deeper inspection

4. Export for Wireshark:
   wireshark {0}

5. Filter by device in tshark:
   tshark -r {0} -Y 'btle.advertising_address == XX:XX:XX:XX:XX:XX'
""".format(filename))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: ble-pcap-analyzer.py <pcap_file>")
        print("\nExample:")
        print("  ble-pcap-analyzer.py ble_capture.pcap")
        print("  ble-pcap-analyzer.py ~/Tools/CatSniffer-Tools/pycatsniffer_bv3/dumps/pcaps/ble_*.pcap")
        sys.exit(1)

    pcap_file = sys.argv[1]
    analyze_pcap(pcap_file)
