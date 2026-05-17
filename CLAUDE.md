# T-Series Fan — Project Context

## Overview

Three identical ESP32-based BLDC fan controllers using ESPHome. Speed is controlled via variable-frequency CLK signal (100-400Hz, 50% fixed duty) on GPIO26. Each fan has an EC11 rotary encoder for local control and appears as a light entity in Home Assistant for remote control.

- **Framework:** ESPHome 2026.4.3 (pip install, Arduino framework on ESP-IDF)
- **Board:** esp32dev (ESP32, 240MHz, 4MB flash)
- **Control method:** LEDC frequency output — ESPHome has no built-in BLDC fan component
- **HA entity:** `light.monochromatic` (0-100% slider → 100-400Hz CLK)

## File Structure

```
esp32_t_series_fan/
  common/base.yaml       # ALL shared device logic (~180 lines)
  t1-fan.yaml            # Device config: substitutions only (~20 lines)
  t2-fan.yaml            # Same, just device_name differs
  t3-fan.yaml            # Same
  secrets.yaml           # WiFi credentials (gitignored)
  flash.ps1              # Universal: .\flash.ps1 -Device t1-fan -IP 192.168.20.201
  *.bat                  # Quick-flash per device
```

**Architecture:** ESPHome `packages:` + `!include`. Each device YAML defines `substitutions:` and includes `common/base.yaml`. Modify one file → affects all three fans.

## Key Design Decisions

- **Light as fan:** ESPHome's built-in fan platforms control duty cycle, not frequency. `light.monochromatic` with linear gamma gives a clean 0-100% → Hz mapping.
- **Antiflicker sync:** 2-second lockout after physical knob turn prevents HA from overwriting. Uses `millis() - disable_sync_until >= 2000` (rollover-safe unsigned subtraction).
- **Duty cycle:** 50% square wave locked. `init_freq` sets it once at boot; `apply_freq` only changes frequency. `write_action` restores duty to 50% when turning on (since `set_level(0.0f)` kills output when off).
- **No API encryption / OTA password:** User's network is trusted.
- **WiFi credentials:** `secrets.yaml` (gitignored) → `!secret` in `base.yaml`. Safe for public GitHub.

## Flash Commands

```powershell
.\flash.ps1 t1-fan 192.168.20.201   # T1
.\flash.ps1 t2-fan 192.168.20.178   # T2
.\flash.ps1 t3-fan 192.168.20.155   # T3
```

Double-click `.bat` files for quick flash.

## Algorithm

```
freq = (state × 300) + 100   // state: 0.0–1.0
```
- 0% → OFF (set_level 0)
- 1% → 103 Hz
- 50% → 250 Hz
- 100% → 400 Hz

Encoder: 0–33 steps, each step = 3% brightness.

## GPIO

| Pin | Function |
|-----|----------|
| GPIO26 | LEDC CLK output (ch0) |
| GPIO32 | EC11 CLK (INPUT_PULLUP) |
| GPIO33 | EC11 DT (INPUT_PULLUP) |
| GPIO25 | EC11 SW (INPUT_PULLUP, inverted) |
