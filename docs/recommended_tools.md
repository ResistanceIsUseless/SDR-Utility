# Recommended SDR Tools for CaribouLite

Based on your wideband sweep results, here are recommended tools to install:

## Already Have (DragonOS is well equipped!)
- rtl_433 - ISM band decoder ✓
- multimon-ng - Multi-decoder ✓
- URH - Universal Radio Hacker ✓
- GNU Radio - SDR framework ✓
- GQRX, SDR++ - GUI receivers ✓
- inspectrum - Signal analyzer ✓
- acarsdec - ACARS aircraft decoder ✓
- dumpvdl2 - VDL Mode 2 decoder ✓
- satdump - Satellite decoder ✓
- qsstv - SSTV image decoder ✓
- gr-gsm, gr-iridium - Cellular/sat decoders ✓
- fldigi - Digital modes ✓

## Recommended to Install

### High Priority
```bash
sudo apt install -y dump1090-fa gr-satellites direwolf freedv
```

**dump1090-fa** - ADS-B decoder for 1090 MHz aircraft transponders
- Real-time aircraft tracking
- Web interface with map
- Better than what we captured with rtl_433

**gr-satellites** - Satellite telemetry decoder
- Decode weather satellites (NOAA, Meteor-M)
- Amateur radio satellites
- Various telemetry formats

**direwolf** - APRS/Packet decoder
- Monitor amateur radio APRS beacons
- 144.39 MHz in North America, 144.80 MHz in Europe
- Integrates with mapping software

**freedv** - Digital voice decoder
- HF/VHF digital voice mode
- Used by ham radio operators

### Medium Priority
```bash
# These might require additional repos or manual install
```

**redsea** - RDS decoder for FM radio
- Decode station info, traffic alerts from FM broadcasts
- Works on 87.5-108 MHz FM band

**dump978** - UAT decoder for 978 MHz
- US-specific aircraft transponders
- Complements dump1090

**meteor_demod** - Meteor-M N2 decoder
- Russian weather satellite images
- 137 MHz band

**multimon-ng plugins** - Additional decoders
- POCSAG paging
- DTMF tones
- More digital modes

### Specialty Tools

**gpredict** - Satellite tracking
```bash
sudo apt install gpredict
```
- Track satellite passes
- Predict optimal receiving times
- Doppler correction

**SigDigger** - Signal analyzer
- Spectrum analysis
- Signal inspection
- Available from GitHub

## Installation Commands

### Quick install (high priority):
```bash
sudo apt update
sudo apt install -y dump1090-fa gr-satellites direwolf freedv gpredict
```

### Advanced (may need building from source):
- redsea: https://github.com/windytan/redsea
- dump978: https://github.com/flightaware/dump978
- meteor_demod: https://github.com/dbdexter-dev/meteor_demod

## Based on Your Sweep Results

You found active transmissions at:
- **732 MHz** - Weather sensors, remotes
- **2440 MHz** - More sensors, weather stations

### For weather sensor enthusiasts:
Consider running rtl_433 continuously on 732 MHz and 2440 MHz:
```bash
# Monitor 732 MHz continuously
rtl_433 -d driver=Cariboulite,channel=HiF -f 732M -F json > ~/weather_sensors.json &

# For data analysis
sudo apt install jq
cat ~/weather_sensors.json | jq .
```

### For aircraft tracking (if you have line of sight):
```bash
# Install and run dump1090
sudo apt install dump1090-fa
dump1090-fa --device-type soapysdr --device driver=Cariboulite,channel=HiF --freq 1090000000 --interactive
```

Access web interface at: http://localhost:8080

### For satellite reception:
1. Install gpredict to find satellite passes
2. Use satdump (already installed) for automated decoding
3. Point antenna at sky during passes

## Testing Your New Tools

### Test dump1090 (ADS-B aircraft):
```bash
timeout 60 dump1090-fa --device-type soapysdr --device driver=Cariboulite,channel=HiF --freq 1090000000 --interactive
```

### Test direwolf (APRS on 144.39 MHz):
```bash
rtl_fm -d driver=Cariboulite,channel=HiF -M fm -f 144.39M -s 22050 | direwolf -r 22050 -
```

### Test gr-satellites (for next NOAA pass):
```bash
# Check gpredict for next NOAA-15/18/19 pass
# Then run appropriate decoder from gr-satellites
```
