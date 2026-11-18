# T-Series Fan — Project Context

## Overview

Three identical ESP32-based BLDC fan controllers using ESPHome. Speed is controlled via variable-frequency CLK signal (100-320Hz, 50% fixed duty) on GPIO26. Each fan has an EC11 rotary encoder for local control and appears as a light entity in Home Assistant for remote control.

- **Framework:** ESPHome 2026.7.4 (venv `D:\code\esp32\esp32_luxpower_fan\.venv`, Arduino framework on ESP-IDF). Build/flash from PowerShell or .bat only — Git Bash (MSYS) makes ESP-IDF skip compiling.
- **Board:** esp32dev (ESP32, 240MHz, 4MB flash)
- **Control method:** LEDC frequency output — ESPHome has no built-in BLDC fan component
- **HA entity:** `light.monochromatic` (0-100% slider → 100-320Hz CLK)

## File Structure

```
esp32_t_series_fan/
  common/base.yaml       # ALL shared device logic + default substitutions (frequency mode)
  common/wifi.yaml       # Shared WiFi block (also used by motor-test)
  common/secrets.yaml    # WiFi credentials (gitignored) — must sit beside wifi.yaml
  devices/<name>/        # One folder per device: <name>.yaml + flash.bat (+ .esphome/ cache)
    t1-fan, mt1-fan,     # Frequency mode — only device_name
    pc1-fan, pc8-fan     #   (pc8 also sets board: nodemcu-32s)
    t2-fan, modem-fan    # Duty 25 kHz Nidec (inverted)
    t31-fan              # Duty + oscillation (base-oscillation.yaml)
    motor-test           # Standalone test firmware
  flash.ps1              # Universal: .\flash.ps1 -Device t1-fan -IP 192.168.20.201
```

**Architecture:** ESPHome `packages:` + `!include ../../common/...`. Device YAML sets `device_name` + only the substitutions that differ from `common/base.yaml` defaults (main-file substitutions override package ones). Modify one file → affects all fans.

## Key Design Decisions

- **Light as fan:** ESPHome's built-in fan platforms control duty cycle, not frequency. `light.monochromatic` with linear gamma gives a clean 0-100% → Hz mapping.
- **Antiflicker sync:** 2-second lockout after physical knob turn prevents HA from overwriting. Uses `millis() - disable_sync_until >= 2000` (rollover-safe unsigned subtraction).
- **Duty cycle:** 50% square wave locked. `init_freq` sets it once at boot; `apply_freq` only changes frequency. `write_action` restores duty to 50% when turning on (since `set_level(0.0f)` kills output when off).
- **No API encryption / OTA password:** User's network is trusted.
- **WiFi credentials:** `common/secrets.yaml` (gitignored) → `!secret` in `common/wifi.yaml`. ESPHome resolves `!secret` from the directory of the file using it, so secrets must stay in `common/`. Safe for public GitHub.

## Flash Commands

```powershell
.\flash.ps1 t1-fan 192.168.20.201   # T1
.\flash.ps1 t2-fan 192.168.20.178   # T2
.\flash.ps1 mt1-fan 192.168.20.155  # MT1 (formerly T3)
.\flash.ps1 t31-fan 192.168.20.177  # T31
.\flash.ps1 modem-fan 192.168.20.187
.\flash.ps1 pc1-fan 192.168.20.179  # P1 — HA light.tang_3_pc1_fan_speed
.\flash.ps1 pc8-fan 192.168.20.191  # P8 — HA light.pc8_fan_speed
```

Not in repo (built on another machine, ESPHome 2026.4.3): `mt2-fan` (.189), `t32-fan` (.183, experimental 3.32).

Double-click `devices\<name>\flash.bat` for quick flash.

## Algorithm

```
freq = (state × 220) + 100   // state: 0.0–1.0; freq_max 320 (400 quá nhanh, hạ 2026-10-20)
```
- 0% → OFF (set_level 0)
- 1% → 102 Hz
- 50% → 210 Hz
- 100% → 320 Hz

Encoder: 0–33 steps, each step = 3% brightness.

## GPIO

| Pin | Function |
|-----|----------|
| GPIO26 | LEDC CLK output (ch0) |
| GPIO32 | EC11 CLK (INPUT_PULLUP) |
| GPIO33 | EC11 DT (INPUT_PULLUP) |
| GPIO25 | EC11 SW (INPUT_PULLUP, inverted) |
