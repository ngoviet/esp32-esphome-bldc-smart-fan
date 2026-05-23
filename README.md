# ESP32 ESPHome BLDC Smart Fan — T-Series

WiFi-connected stepless BLDC ceiling fan controller using ESP32 + ESPHome. Natively integrates with **Home Assistant** via ESPHome API. Supports **two BLDC driver types**: frequency-controlled (T1-T3) and duty-cycle PWM-controlled (T31 with oscillation).

[![GitHub last commit](https://img.shields.io/github/last-commit/ngoviet/esp32-esphome-bldc-smart-fan)](https://github.com/ngoviet/esp32-esphome-bldc-smart-fan)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ESPHome](https://img.shields.io/badge/ESPHome-2026.4.3-blue)](https://esphome.io/)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ngoviet-yellow?logo=buymeacoffee)](https://buymeacoffee.com/ngoviet)

---

## Models & BLDC Driver Types

This project supports two BLDC fan driver architectures. Choose based on your motor driver board.

| Model | Board | Control Method | CLK Signal | Extras |
|-------|-------|---------------|------------|--------|
| **T1 / T2 / T3** | ESP32 30-pin | **Frequency** (100–400 Hz, 50% fixed duty) | `inverted: false` | — |
| **T31** | ESP32 38-pin | **Duty-cycle** (fixed 150 Hz, 30–99.5% variable duty) | `inverted: true` (HIGH = stop) | **Oscillation motor** via D4184 MOSFET (GPIO27) |

### T1-T3: Frequency-Based BLDC Control

Most BLDC ceiling fan drivers (Lishui, Vego, and similar) use a **variable-frequency square wave** to set motor speed. The driver reads the CLK signal frequency and adjusts the motor proportionally:

| Brightness | Frequency |
|-----------|-----------|
| 0% (OFF) | No signal |
| 1% | 103 Hz |
| 50% | 250 Hz |
| 100% | 400 Hz |

Duty cycle is locked at 50%. The ESP32's **LEDC hardware peripheral** generates this signal on GPIO26.

### T31: Duty-Cycle BLDC Control with Oscillation

The T31 uses a different BLDC driver that requires a **variable duty-cycle PWM** at a fixed frequency (150 Hz). The signal polarity is inverted — **HIGH = motor stop, LOW pulse width = speed**. This driver is commonly found in fans with a separate oscillation (swing) motor.

| Brightness | Duty (inverted) | Effect |
|-----------|----------------|--------|
| OFF | 0.5% LOW (≈HIGH) | Motor stopped |
| 1% | 30% LOW | Minimum speed |
| 50% | 65% LOW | Medium speed |
| 100% | 99.5% LOW | Maximum speed |

**Oscillation control:** The T31's swing motor is driven by a **D4184 dual MOSFET module** on GPIO27. A GPIO switch in ESPHome toggles the oscillation motor independently from the main fan speed — you can have the fan blowing in a fixed direction or sweeping the room.

> **Why 0.5%–99.5% instead of 0%–100%?** ESPHome's LEDC output calls `ledc_stop()` when duty hits exactly 0% or 100%, which causes a momentary glitch when restarting. By clamping at 0.5%–99.5%, the LEDC timer runs continuously — speed transitions are seamleess with zero dips or flicker.

---

## Features

- **Stepless speed control** — 0–100% via rotary encoder knob or Home Assistant slider
- **Dual BLDC support** — frequency mode (T1-T3) and duty-cycle mode (T31)
- **Motorized oscillation** (T31) — independent swing toggle via D4184 MOSFET
- **Instant response** — no transition lag, linear gamma correction
- **Anti-flicker sync** — physical knob and HA state stay synchronized; 2-second debounce lockout
- **State persistence** — speed and on/off state survive power loss and reboots
- **OTA firmware updates** — flash over WiFi without opening the enclosure
- **Multi-fan management** — all fans share one codebase via ESPHome packages
- **Diagnostic sensors** — speed parameter (Hz or %), firmware version, WiFi RSSI visible in HA
- **Micro-duty anti-glitch** — LEDC timer never stops; clean speed transitions across the full range

---

## Hardware Requirements

### Bill of Materials (per fan)

| Component | T1-T3 | T31 | Notes |
|-----------|-------|-----|-------|
| ESP32 Dev Board | 30-pin | 38-pin | 240 MHz, 4 MB flash |
| EC11 Rotary Encoder | ✓ | ✓ | 20-pulse with push button |
| BLDC Fan Driver (frequency) | ✓ | — | 100–400 Hz CLK input |
| BLDC Fan Driver (duty-cycle) | — | ✓ | 150 Hz PWM, inverted logic |
| D4184 MOSFET Module | — | ✓ | Dual MOSFET for swing motor |
| BLDC Ceiling Fan Motor | ✓ | ✓ | Match voltage to driver board |
| Oscillation Motor | — | ✓ | Separate swing motor (T31 only) |
| Jumper Wires | ✓ | ✓ | Dupont or JST connectors |

### GPIO Pinout

#### T1 / T2 / T3 (30-pin ESP32)

```
ESP32 GPIO    Function
──────────    ────────
GPIO26   →    CLK output (frequency signal to BLDC driver)
GPIO32   ←    EC11 CLK (rotary encoder, INPUT_PULLUP)
GPIO33   ←    EC11 DT  (rotary encoder, INPUT_PULLUP)
GPIO25   ←    EC11 SW  (push button, INPUT_PULLUP, inverted)
```

#### T31 (38-pin ESP32)

```
ESP32 GPIO    Function
──────────    ────────
GPIO26   →    CLK output (duty-cycle PWM to BLDC driver, inverted)
GPIO27   →    D4184 MOSFET gate (oscillation swing motor ON/OFF)
GPIO32   ←    EC11 CLK (rotary encoder, INPUT_PULLUP)
GPIO33   ←    EC11 DT  (rotary encoder, INPUT_PULLUP)
GPIO25   ←    EC11 SW  (push button, INPUT_PULLUP, inverted)
```

> **Important:** All components (ESP32, BLDC driver, MOSFET module) **must share a common ground (GND)**. The CLK signal is voltage-referenced — without a shared ground the driver cannot interpret the signal.

### Wiring Diagram (T1-T3)

```
        ESP32 30-pin                     EC11 Encoder
   ┌──────────────────┐            ┌────────────────┐
   │                  │            │  VCC (+)  ──────→ 3.3V
   │ GPIO26 ──────────┼──→ BLDC Driver CLK/PWM_IN
   │ GPIO32 ──────────┼──→ EC11 CLK
   │ GPIO33 ──────────┼──→ EC11 DT
   │ GPIO25 ──────────┼──→ EC11 SW
   │ GND    ─┬────────┼──→ BLDC Driver GND
   │         │        │      EC11 GND
   │ 3.3V   ─┘        │
   └──────────────────┘
```

### Wiring Diagram (T31)

```
        ESP32 38-pin                     EC11 Encoder
   ┌──────────────────┐            ┌────────────────┐
   │                  │            │  VCC (+)  ──────→ 3.3V
   │ GPIO26 ──────────┼──→ BLDC Driver CLK/PWM_IN
   │ GPIO27 ──────────┼──→ D4184 MOSFET → Oscillation Motor
   │ GPIO32 ──────────┼──→ EC11 CLK
   │ GPIO33 ──────────┼──→ EC11 DT
   │ GPIO25 ──────────┼──→ EC11 SW
   │ GND    ─┬────────┼──→ BLDC Driver GND
   │         │        │      D4184 GND
   │         │        │      Oscillation Motor GND
   │ 3.3V   ─┘        │      EC11 GND
   └──────────────────┘
```

> **Where to buy:** Search "BLDC fan driver board", "quạt trần BLDC", or "mạch điều khiển quạt BLDC" on Shopee, Lazada, or AliExpress. Common brands include Lishui and Vego. For the D4184 MOSFET module, search "D4184 dual MOSFET" or "mạch công tắc MOSFET D4184".

---

## Software Requirements

### ESPHome CLI

```bash
pip install esphome
esphome version   # should be 2026.4.3+
```

> Home Assistant OS users can use the ESPHome add-on. This guide assumes CLI for faster iteration and parallel multi-device flashing.

### Project Structure

```
esp32_t_series_fan/
├── common/
│   ├── base.yaml                # Shared logic — frequency + duty-cycle dual mode
│   └── base-oscillation.yaml    # base.yaml + GPIO switch for T31 oscillation
├── t1-fan.yaml                  # T1 device config (substitutions only)
├── t2-fan.yaml                  # T2 device config
├── t3-fan.yaml                  # T3 device config
├── t31-fan.yaml                 # T31 device config (duty-cycle + oscillation)
├── ha-dashboard/                # Home Assistant dashboard YAML snippets
│   ├── dashboard_fan_p1.md
│   ├── dashboard_fan_p2.md
│   ├── dashboard_fan_p8.md
│   ├── dashboard_fan_t31.md
│   └── 01_p*_fan_speed_control.yaml   # Auto-speed automations
├── secrets_example.yaml         # WiFi credentials template (copy to secrets.yaml)
├── secrets.yaml                 # Your WiFi credentials (gitignored — DO NOT COMMIT)
├── flash.ps1                    # PowerShell: .\flash.ps1 -Device t1-fan -IP 192.168.20.201
├── *.bat                        # Quick-flash per device
├── README.md
└── .gitignore
```

**Architecture:** ESPHome `packages:` + `!include`. Each device YAML defines only `substitutions:` and includes the shared logic. Modify `common/base.yaml` once — all fans receive the update on next flash.

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/ngoviet/esp32-esphome-bldc-smart-fan.git
cd esp32_t_series_fan
```

### 2. Configure WiFi

```bash
cp secrets_example.yaml secrets.yaml
```

Edit `secrets.yaml` with your WiFi credentials:

```yaml
wifi_ssid: "YourWiFiSSID"
wifi_password: "YourWiFiPassword"
```

### 3. Wire the Hardware

Follow the GPIO pinout table above for your model. Double-check the shared GND connection.

### 4. Flash Firmware

```powershell
# PowerShell (recommended)
.\flash.ps1 -Device t1-fan -IP 192.168.20.201

# Or double-click the .bat file
# Or use ESPHome CLI directly:
esphome run t1-fan.yaml --device 192.168.20.201
```

First build takes ~2 minutes (compiles ESP-IDF + Arduino). Subsequent builds take ~30 seconds (incremental).

### 5. Add to Home Assistant

The device auto-discovers via mDNS. Navigate to **Settings → Devices & Services → ESPHome** and click **Configure**. The fan appears as a **Light** entity (speed slider) plus diagnostic sensors.

### 6. Add Dashboard Cards (optional)

Copy the YAML from `ha-dashboard/` into your HA dashboard raw editor. Each card uses `mushroom-light-card` + `mushroom-legacy-template-card` with custom CSS for a compact, modern look.

---

## Home Assistant Entities

### T1-T3 Entities

| Entity | Type | Description |
|--------|------|-------------|
| `light.<device>_speed` | Light | Speed slider (1–100% → 103–400 Hz) |
| `sensor.<device>_fan_frequency` | Sensor | Actual CLK frequency in Hz |
| `sensor.<device>_firmware_version` | Sensor | Firmware version string |
| `sensor.<device>_wifi_rssi` | Sensor | WiFi signal strength (dBm) |
| `text_sensor.<device>_wifi_ip` | Text Sensor | Device IP address |
| `text_sensor.<device>_wifi_ssid` | Text Sensor | Connected WiFi SSID |
| `button.<device>_restart_thiet_bi` | Button | Soft restart |

### T31 Entities (additional)

| Entity | Type | Description |
|--------|------|-------------|
| `sensor.t31_fan_fan_duty` | Sensor | Duty cycle % (actual speed parameter) |
| `switch.t31_fan_dao_gio` | Switch | Oscillation swing toggle (GPIO27 MOSFET) |

---

## Multi-Fan Setup

Copy an existing device config and change the name:

```bash
cp t1-fan.yaml t4-fan.yaml
```

Edit `t4-fan.yaml`:

```yaml
substitutions:
  device_name: "t4-fan"
  device_friendly_name: "T4 Fan"
  # ... same GPIO pins, frequency range, etc.
```

Flash:

```bash
.\flash.ps1 -Device t4-fan -IP 192.168.20.xxx
```

All behavior is inherited from `common/base.yaml`. No logic duplication.

---

## Configuration Reference

### Substitutions (per-device)

| Parameter | T1-T3 Default | T31 Default | Description |
|-----------|--------------|-------------|-------------|
| `device_name` | `t1-fan` | `t31-fan` | ESPHome node name (no spaces) |
| `clk_pin` | `GPIO26` | `GPIO26` | LEDC PWM output pin |
| `clk_channel` | `0` | `8` | LEDC channel (T31 uses LS channel to avoid glitch) |
| `clk_inverted` | `false` | `true` | Invert LEDC output polarity |
| `speed_duty_mode_val` | `false` | `true` | `true` = duty-cycle mode, `false` = frequency mode |
| `default_frequency` | `150` | `150` | LEDC base frequency (Hz) |
| `freq_min` | `100` | `100` | Minimum frequency (Hz) — frequency mode only |
| `freq_max` | `400` | `400` | Maximum frequency (Hz) — frequency mode only |
| `encoder_resolution` | `1` | `1` | EC11 pulses per detent (use `4` if bouncy) |
| `speed_param_name` | `Fan Frequency` | `Fan Duty` | Diagnostic sensor name |
| `speed_param_unit` | `Hz` | `%` | Diagnostic sensor unit |
| `firmware_version` | `2.0.2` | `2.0.3` | Version shown in HA |

---

## Automation Examples

### Auto-off Timer

```yaml
alias: "Turn off fan after 2 hours"
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

### Temperature-Based Speed (Frequency Mode)

```yaml
alias: "Fan speed by room temperature"
trigger:
  - platform: numeric_state
    entity_id: sensor.room_temperature
    above: 28
action:
  - service: light.turn_on
    target:
      entity_id: light.t1_fan_speed
    data:
      brightness_pct: >
        {{ ((trigger.to_state.state | float - 25) / 10 * 100) | round(0) }}
```

### Power-Based Auto Speed (see ha-dashboard/)

The `ha-dashboard/01_p*_fan_speed_control.yaml` files contain ready-to-use automations that map device power consumption to fan speed — useful for cooling mining rigs, servers, or electrical panels.

---

## Tuning Guide

| Symptom | Parameter | Change |
|---------|-----------|--------|
| Knob jumps 4 steps per click | `encoder_resolution` | Set to `4` |
| Fan driver uses different frequency range | `freq_min` / `freq_max` | Match driver datasheet |
| T31 minimum speed too weak to start | Write lambda duty formula | Increase `0.30f` base (currently 30%) |
| T31 stops too abruptly at max | Duty cap | Adjust `0.995f` (currently 99.5%) |
| Flash fails (OTA timeout) | — | Use serial flash (COM port) for first flash |

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Fan doesn't spin | No shared GND | Connect ESP32 GND ↔ BLDC driver GND |
| Speed jumps erratically | Encoder bounce | Set `encoder_resolution: "4"` |
| Fan creeps when "OFF" (T31) | Micro-duty too high | Lower `0.005f` to `0.001f` in OFF branch |
| Speed dips when changing speed (T31) | `ledc_stop()` glitch at 0% or 100% | Ensure duty range is 0.5%–99.5% |
| "No such file: secrets.yaml" | Missing secrets file | Copy `secrets_example.yaml` → `secrets.yaml` |
| Build fails after pull | Stale build cache | Delete `.esphome/build/` and recompile |
| OTA fails (connection timeout) | WiFi signal too weak | Move ESP32 closer to AP, or flash via serial |

---

## Technical Deep Dive

### Speed Algorithm — Frequency Mode (T1-T3)

```
frequency = (brightness × 300) + 100

Where:
  brightness = 0.0 – 1.0 (Home Assistant slider)
  Result: 100 – 400 Hz, constant 50% duty
```

- Below 1% brightness → Fan OFF (PWM output disabled)
- Delta = 300 Hz → each 1% step = exactly 3 Hz (integer math, zero rounding)
- `apply_freq` script reconfigures LEDC timer atomically with `mode: restart`

### Speed Algorithm — Duty-Cycle Mode (T31)

```
duty = 0.30 + (brightness × 0.70)
duty clamped to [0.005, 0.995]

Where:
  brightness = 0.0 – 1.0
  Result: 30% – 99.5% duty at fixed 150 Hz (inverted: HIGH = stop)
```

- OFF state: 0.5% duty → ~33 µs LOW pulse per 6.67 ms period → motor effectively stopped
- LEDC timer never calls `ledc_stop()` — clean transitions across entire range
- `syncing_from_ha` flag prevents encoder callback double-write when HA adjusts speed

### Anti-Flicker Sync

1. Physical knob turn → `disable_sync_until = millis()` → 2-second HA lockout
2. HA brightness change → `syncing_from_ha = true` → encoder callback suppressed → single LEDC write
3. Rollover-safe: `millis() - disable_sync_until >= 2000` uses unsigned subtraction

### LEDC Channel Selection

T31 uses **channel 8** (low-speed) to avoid a known ESP32 hardware issue where high-speed channels (0–7) silently ignore `ledcWrite()` updates within the same PWM period. Low-speed channels commit changes immediately — critical for smooth duty-cycle transitions at 150 Hz.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make changes — prefer `common/base.yaml` for shared logic, device YAML for model-specific changes
4. Test on real hardware
5. Submit a pull request

---

## Credits

- **Author:** [ngoviet](https://github.com/ngoviet)
- **Support:** [Buy Me a Coffee](https://buymeacoffee.com/ngoviet)
- Built with [ESPHome](https://esphome.io/) (Arduino framework on ESP-IDF)
- Inspired by the Vietnamese smart home community

---

## License

MIT License — see [LICENSE](LICENSE).
