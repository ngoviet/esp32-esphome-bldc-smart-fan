# Home Assistant Dashboard Cards

Compact Mushroom Light Cards for T-Series fans. Each card is 45px tall with integrated brightness slider.

## Preview

Each card shows:
- Fan icon (pink)
- Device name
- Current state (ON/OFF)
- Brightness slider (controls fan speed)

## Installation

### Prerequisites

Install these HACS frontend components:

1. **[Mushroom Cards](https://github.com/piitaya/lovelace-mushroom)** — Beautiful unified dashboard cards
2. **[card-mod](https://github.com/thomasloven/lovelace-card-mod)** — Custom CSS styling for cards

### Add to Dashboard

1. In Home Assistant, go to **Settings → Dashboards → (your dashboard) → Edit**
2. Click **Add Card → Manual**
3. Paste the code below for each fan
4. Replace `t1_fan_speed` with your entity ID

## Card: T1 Fan

```yaml
type: custom:mushroom-light-card
entity: light.t1_fan_speed
show_brightness_control: true
show_color_control: false
layout: horizontal
fill_container: true
icon_color: pink
secondary_info: state
icon: mdi:fan
name: Quạt T1
card_mod:
  style: |
    ha-card {
      border: 1px solid #6e6e71;
      border-radius: 12px;
      box-shadow: 2px 2px 8px rgba(0,0,0,.12);
      padding: 5px !important;
      overflow: hidden;
      background: transparent;
      height: 45px !important;
      --card-primary-font-size: 14px;
      --card-secondary-font-size: 12px;
    }
    :host {
      height: 40px !important;
      --mush-icon-size: 25px;
      --mush-spacing: 6px;
      --control-height: 20px;
      --control-border-radius: 10px;
      --control-padding: 0px;
      --control-slider-thickness: 6px;
      --slider-thickness: 6px;
    }
    .content {
      height: 100% !important;
      align-items: center !important;
    }
```

## Card: T2 Fan

```yaml
type: custom:mushroom-light-card
entity: light.t2_fan_speed
show_brightness_control: true
show_color_control: false
layout: horizontal
fill_container: true
icon_color: cyan
secondary_info: state
icon: mdi:fan
name: Quạt T2
card_mod:
  style: |
    ha-card {
      border: 1px solid #6e6e71;
      border-radius: 12px;
      box-shadow: 2px 2px 8px rgba(0,0,0,.12);
      padding: 5px !important;
      overflow: hidden;
      background: transparent;
      height: 45px !important;
      --card-primary-font-size: 14px;
      --card-secondary-font-size: 12px;
    }
    :host {
      height: 40px !important;
      --mush-icon-size: 25px;
      --mush-spacing: 6px;
      --control-height: 20px;
      --control-border-radius: 10px;
      --control-padding: 0px;
      --control-slider-thickness: 6px;
      --slider-thickness: 6px;
    }
    .content {
      height: 100% !important;
      align-items: center !important;
    }
```

## Card: T3 Fan

```yaml
type: custom:mushroom-light-card
entity: light.t3_fan_speed
show_brightness_control: true
show_color_control: false
layout: horizontal
fill_container: true
icon_color: orange
secondary_info: state
icon: mdi:fan
name: Quạt T3
card_mod:
  style: |
    ha-card {
      border: 1px solid #6e6e71;
      border-radius: 12px;
      box-shadow: 2px 2px 8px rgba(0,0,0,.12);
      padding: 5px !important;
      overflow: hidden;
      background: transparent;
      height: 45px !important;
      --card-primary-font-size: 14px;
      --card-secondary-font-size: 12px;
    }
    :host {
      height: 40px !important;
      --mush-icon-size: 25px;
      --mush-spacing: 6px;
      --control-height: 20px;
      --control-border-radius: 10px;
      --control-padding: 0px;
      --control-slider-thickness: 6px;
      --slider-thickness: 6px;
    }
    .content {
      height: 100% !important;
      align-items: center !important;
    }
```

## Minimal Card (without custom styling)

If you don't have card-mod installed, use this simpler version:

```yaml
type: custom:mushroom-light-card
entity: light.t1_fan_speed
show_brightness_control: true
show_color_control: false
layout: horizontal
icon_color: pink
icon: mdi:fan
name: Quạt T1
```

## Row Layout (side-by-side)

For a compact row of 3 fans:

```yaml
type: horizontal-stack
cards:
  - type: custom:mushroom-light-card
    entity: light.t1_fan_speed
    show_brightness_control: true
    show_color_control: false
    layout: horizontal
    icon_color: pink
    icon: mdi:fan
    name: T1
    card_mod:
      style: |
        ha-card {
          height: 45px !important;
        }
        :host {
          --mush-icon-size: 25px;
          --control-height: 20px;
        }

  - type: custom:mushroom-light-card
    entity: light.t2_fan_speed
    show_brightness_control: true
    show_color_control: false
    layout: horizontal
    icon_color: cyan
    icon: mdi:fan
    name: T2
    card_mod:
      style: |
        ha-card {
          height: 45px !important;
        }
        :host {
          --mush-icon-size: 25px;
          --control-height: 20px;
        }

  - type: custom:mushroom-light-card
    entity: light.t3_fan_speed
    show_brightness_control: true
    show_color_control: false
    layout: horizontal
    icon_color: orange
    icon: mdi:fan
    name: T3
    card_mod:
      style: |
        ha-card {
          height: 45px !important;
        }
        :host {
          --mush-icon-size: 25px;
          --control-height: 20px;
        }
```
