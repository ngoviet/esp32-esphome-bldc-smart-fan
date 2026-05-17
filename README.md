# ESP32 ESPHome BLDC Smart Fan

Variable-speed brushless DC (BLDC) fan controller using ESP32 + ESPHome. Replace your old AC fan controller with a stepless, WiFi-connected speed control that integrates natively with Home Assistant.

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ngoviet-yellow?logo=buymeacoffee)](https://buymeacoffee.com/ngoviet)

## How It Works

Most BLDC ceiling fan drivers use a **variable-frequency square wave** (CLK signal) to set motor speed — NOT PWM duty cycle. The motor driver reads the CLK frequency and adjusts the motor accordingly:

| Speed | Frequency |
|-------|-----------|
| 0% (OFF) | No signal |
| 1% | 103 Hz |
| 50% | 250 Hz |
| 100% | 400 Hz |

The ESP32 generates this CLK signal via its **LEDC hardware peripheral** at a fixed 50% duty cycle. A physical **EC11 rotary encoder** provides local stepless control, while **Home Assistant** integration allows remote control and automation via ESPHome's native API.

ESPHome has no built-in BLDC fan component that supports CLK frequency control. This project uses `light.monochromatic` as a clean workaround — the brightness slider (0-100%) maps linearly to frequency (100-400 Hz). The fan appears in Home Assistant with a fan icon and full slider control.

## Features

- **Stepless speed control** — 0–100% via rotary encoder or Home Assistant slider
- **Instant response** — no transition lag, linear gamma
- **Anti-flicker sync** — physical knob and HA state stay synchronized, even after power loss
- **State persistence** — fan speed and on/off state survive reboots
- **Multi-fan ready** — easily manage multiple identical fans (T1, T2, T3...) from one codebase
- **Diagnostic sensors** — frequency (Hz), firmware version, WiFi RSSI all visible in HA
- **OTA updates** — flash firmware over WiFi without opening the enclosure

## Hardware Requirements

### Bill of Materials (per fan)

| Component | Qty | Notes |
|-----------|-----|-------|
| ESP32 Dev Board (esp32dev) | 1 | 240MHz, 4MB flash. Any ESP32-DevKitC/WROOM is fine |
| EC11 Rotary Encoder | 1 | 20-pulse mechanical type, with push button |
| BLDC Fan Driver Board | 1 | Must accept **frequency-based CLK input** (100-400Hz) |
| BLDC Ceiling Fan Motor | 1 | Match voltage/power to driver board |
| 3.3V Regulator (optional) | 1 | If fan driver needs different voltage logic |
| Wires + Connectors | - | Dupont, JST, or soldered |

> **Where to buy:** Find BLDC fan driver boards on Shopee/AliExpress by searching "BLDC fan driver CLK" or "quạt BLDC board". Common brands: Lishui, Vego, etc. The driver board should have a `PWM_IN` or `CLK` input pin that accepts a frequency-based speed signal.

### GPIO Wiring

```
ESP32              EC11 Encoder          BLDC Fan Driver
───────            ────────────          ───────────────
3.3V  ──────────── VCC (+)
GND   ─┬────────── GND              ─┬── GND
       │                              │
GPIO26 ───────────────────────────────┼── PWM_IN / CLK
                                      │
GPIO32 ──────────── CLK (signal A)    │
GPIO33 ──────────── DT  (signal B)    │
GPIO25 ──────────── SW  (push button)
```

### Wiring Diagram

```
         ESP32 Dev Board
    ┌─────────────────────────┐
    │  EN                  D23│
    │  D0                  D22│
    │  D2                  TX │
    │  D4                  RX │
    │  D5               D21   │
    │  D18              D19   │
    │  D15  3.3V──┬──GND      │
    │  D25──►SW   │           │
    │  D26──►PWM_IN          │
    │  D27──D32──►CLK        │
    │  D14──D33──►DT         │
    │  D12              D13  │
    │  D26              D25  │
    └─────────────────────────┘
           │     │     │
           │     │     └──► BLDC Driver PWM_IN
           │     └────────► EC11 DT
           └──────────────► EC11 CLK

    EC11 Encoder (front view, pins facing you)
    ┌──────────────┐
    │  O   O    O  │
    │ GND  +   SW  │──► ESP32 GPIO25
    │ CLK  DT      │──► ESP32 GPIO32, GPIO33
    └──────────────┘

    * Connect EC11 VCC to ESP32 3.3V
    * Connect EC11 GND to ESP32 GND
    * BLDC Driver GND MUST share ESP32 GND
```

> **Important:** The ESP32 and BLDC fan driver **must share a common ground (GND)**. The CLK signal is a voltage referenced to ground — without a shared ground, the driver cannot read the signal.

## Software Requirements

### ESPHome Installation

You need Python 3.9+ and ESPHome on your computer. ESPHome compiles firmware and flashes it to the ESP32.

```bash
# Install ESPHome via pip
pip install esphome

# Verify installation
esphome version
```

> **Note for Home Assistant users:** You can use the ESPHome addon/container, but this guide assumes **command-line ESPHome** (pip install). CLI is faster for iterative development and supports parallel flashing of multiple devices.

### Project Structure

```
esp32_t_series_fan/
├── common/
│   └── base.yaml         # ALL shared device logic (~180 lines)
├── t1-fan.yaml           # Device config: just substitutions + package include
├── t2-fan.yaml           # Same — only device_name differs
├── t3-fan.yaml           # Same
├── secrets.yaml          # Your WiFi credentials (gitignored)
├── flash.ps1             # PowerShell: .\flash.ps1 t1-fan 192.168.20.201
├── *.bat                 # Quick-flash per device
├── ha-dashboard.md       # Home Assistant dashboard card examples
└── .gitignore
```

**Why this structure?** All three fans share identical hardware and logic. Only the device name and friendly name differ. The `common/base.yaml` file contains ALL the device logic once — modify it, and all three fans get the update. Each `tX-fan.yaml` file is just ~20 lines of substitutions.

## Quick Start

### Step 1: Clone this repository

```bash
git clone https://github.com/ngoviet/esp32-esphome-bldc-smart-fan.git
cd esp32_t_series_fan
```

### Step 2: Configure your WiFi

Create `secrets.yaml` (this file is gitignored — do NOT commit it):

```yaml
wifi_ssid: "YourWiFiName"
wifi_password: "YourWiFiPassword"
```

### Step 3: Customize GPIO pins (if needed)

Open `t1-fan.yaml`. The default pins work for most setups but adjust if your wiring differs:

```yaml
substitutions:
  device_name: "t1-fan"
  device_friendly_name: "T1 Fan"
  clk_pin: "GPIO26"           # PWM output to fan driver
  encoder_clk_pin: "GPIO32"   # EC11 CLK
  encoder_dt_pin: "GPIO33"    # EC11 DT
  encoder_sw_pin: "GPIO25"    # EC11 push button
```

### Step 4: Flash the firmware

**Using PowerShell (recommended):**
```powershell
.\flash.ps1 t1-fan 192.168.20.201
```

**Using batch file (double-click):**
Double-click `t1-fan.bat`

**Using command line:**
```bash
esphome run t1-fan.yaml --device 192.168.20.201
```

First build takes ~2 minutes (compiles ESP-IDF + Arduino framework). Subsequent builds take ~30 seconds (incremental).

### Step 5: Add to Home Assistant

The device auto-discovers via mDNS (`t1-fan.local`). Go to **Settings → Devices & Services → ESPHome** and click **Configure**. The fan appears as both a **Light** entity (speed slider) and diagnostic sensors.

### Step 6: Add a dashboard card (optional)

See [ha-dashboard.md](ha-dashboard.md) for ready-to-use Mushroom Light Cards with custom styling. Each card is compact (45px height), shows the fan icon, speed slider, and current state.

## Multi-Fan Setup

For additional fans (T2, T3, etc.), simply copy `t1-fan.yaml`:

```bash
cp t1-fan.yaml t2-fan.yaml
```

Edit `t2-fan.yaml` and change only these two lines:
```yaml
  device_name: "t2-fan"
  device_friendly_name: "T2 Fan"
```

Flash:
```bash
.\flash.ps1 t2-fan 192.168.20.178
```

All other logic is inherited from `common/base.yaml`.

## Customization

### Adjusting Frequency Range

Different BLDC drivers use different frequency ranges. Edit the `substitutions:` block in your device YAML:

```yaml
  freq_min: "100"    # Minimum frequency (Hz) at 1% speed
  freq_max: "400"    # Maximum frequency (Hz) at 100% speed
```

### Fixing Encoder Bounce

Some EC11 variants produce 4 counts per detent instead of 1. If turning the knob causes erratic jumps, change:

```yaml
  encoder_resolution: "4"    # Hardware pulse division (default: "1")
```

The resolution setting enables the hardware debounce counter on the ESP32 rotary encoder peripheral.

### Updating Firmware Version

Increment `firmware_version` before each flash for easy tracking in Home Assistant:

```yaml
  firmware_version: "2.0.3"
```

The version appears in HA as `sensor.<device>_firmware_version`.

## Tuning Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `encoder_resolution` | `1` | EC11 bounces 4x per detent |
| `freq_min` / `freq_max` | `100` / `400` | Different BLDC driver spec |
| `default_frequency` | `150` | Startup speed after first flash |
| `logger_baud_rate` | `115200` | USB serial debugging |
| `clk_pin` | `GPIO26` | Different ESP32 pinout |
| `clk_channel` | `0` | If channel 0 conflicts with other peripherals |

## Home Assistant Entities

| Entity | Type | Description |
|--------|------|-------------|
| `light.tX_fan_speed` | Light | Speed slider (1-100% → 103-400Hz) |
| `sensor.tX_fan_fan_frequency` | Sensor | Actual CLK frequency in Hz |
| `sensor.tX_fan_firmware_version` | Sensor | Firmware version |
| `sensor.tX_fan_wifi_rssi` | Sensor | WiFi signal strength (dBm) |
| `text_sensor.tX_fan_wifi_ip` | Text | IP address |
| `text_sensor.tX_fan_wifi_ssid` | Text | Connected WiFi name |
| `binary_sensor.tX_fan_nut_an_ecc11` | Binary | Encoder button state |
| `button.tX_fan_restart_thiet_bi` | Button | Soft restart |

## Automation Ideas

### Auto-off after time
```yaml
alias: "Turn off T1 Fan after 2 hours"
trigger:
  - platform: state
    entity_id: light.t1_fan_speed
    to: "on"
    for: "02:00:00"
action:
  - service: light.turn_off
    target:
      entity_id: light.t1_fan_speed
```

### Fan speed based on temperature
```yaml
alias: "Fan speed by room temp"
trigger:
  - platform: numeric_state
    entity_id: sensor.room_temperature
    above: 28
action:
  - service: light.turn_on
    target:
      entity_id: light.t1_fan_speed
    data:
      brightness_pct: "{{ (trigger.to_state.state | float - 25) / 10 * 100 | round(0) }}"
```

### Button press → toggle all fans
```yaml
alias: "Toggle all fans"
action:
  - service: light.toggle
    target:
      entity_id:
        - light.t1_fan_speed
        - light.t2_fan_speed
        - light.t3_fan_speed
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Fan doesn't spin | Check GND shared between ESP32 and driver. Check PWM_IN wiring. |
| Speed jumps erratically | Set `encoder_resolution: "4"` in substitutions. |
| Fan spins at boot when should be off | Update to v2.0.2+ (fixed `on_boot` guard). |
| Fan stops briefly when changing speed | Normal — LEDC timer reconfigures on frequency change (~1ms gap). |
| HA shows wrong icon | This is expected — ESPHome has no native variable-frequency fan platform. The `mdi:fan` icon is already set. |
| "No such file: secrets.yaml" | Create `secrets.yaml` with your WiFi credentials. See Step 2 in Quick Start. |
| Build fails after pulling updated code | Delete `.esphome/build/` directory and recompile. |

## Technical Details

### Speed Control Algorithm

```
Frequency (Hz) = (Brightness × 300) + 100

Where:
  Brightness: 0.0–1.0 (0%–100% HA slider)
  Result: 100–400 Hz, always 50% duty cycle
```

- Below 1% brightness → Fan OFF (PWM output stopped)
- 1% = 103 Hz, 50% = 250 Hz, 100% = 400 Hz
- Delta = 300 Hz → each 1% step = exactly 3 Hz (integer, no rounding)

### Anti-Flicker Sync Mechanism

When you turn the physical knob:
1. A 2-second lockout prevents Home Assistant from overwriting the knob
2. After 2 seconds of no knob changes, HA state re-syncs the knob counter

This prevents the "flicker-fight" where you turn the knob and HA simultaneously changes it back. Uses **unsigned subtraction** for millis() rollover safety (~50-day uptime).

### Boot Behavior

- `freq_hz` global persists across power cycles (flash storage)
- Light state persists (ESPHome `RESTORE_DEFAULT_OFF`)
- `on_boot` at priority 200: only re-applies frequency if light was ON
- If light was OFF → fan stays off on boot

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes to `common/base.yaml` (affects all devices)
4. Test on your hardware
5. Submit a pull request

## Credits

- **Author:** [ngoviet](https://github.com/ngoviet)
- **Support:** [Buy Me a Coffee](https://buymeacoffee.com/ngoviet)
- Built with [ESPHome](https://esphome.io/)
- Inspired by the Vietnamese smart home community

## License

MIT License — see [LICENSE](LICENSE) file.
