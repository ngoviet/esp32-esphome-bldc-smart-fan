# T31 Fan Dashboard — YAML Snippet

Copy section bên dưới vào dashboard YAML raw editor.

## Yêu cầu

- `card-mod` (đã cài sẵn)
- `mushroom-light-card` + `mushroom-legacy-template-card`

```yaml
type: horizontal-stack
cards:
  # ============================================================
  # T31 Fan light control (speed)
  # ============================================================
  - type: custom:mushroom-light-card
    entity: light.t31_fan_speed_2
    show_brightness_control: true
    show_color_control: false
    layout: horizontal
    fill_container: true
    icon_color: teal
    secondary_info: state
    icon: mdi:fan
    name: T31 Fan
    card_mod:
      style: |
        :host {
          flex: 1 1 auto !important;
          width: auto !important;
        }
        ha-card {
          border: none !important;
          box-shadow: none !important;
          padding: 4px 2px 4px 8px !important;
          margin: 0 !important;
          background: transparent !important;
          --card-primary-font-size: 14px;
          --card-secondary-font-size: 12px;
        }
        :host {
          --mush-icon-size: 22px;
          --mush-spacing: 4px;
          --control-height: 18px;
          --control-border-radius: 9px;
          --control-padding: 1px;
          --control-slider-thickness: 6px;
          --slider-thickness: 6px;
        }
        .content {
          height: 100% !important;
          align-items: center !important;
        }

  # ============================================================
  # Swing toggle (đảo gió)
  # ============================================================
  - type: custom:mushroom-legacy-template-card
    primary: ""
    secondary: ""
    icon: mdi:sync
    icon_color: >
      {% if is_state('switch.t31_fan_dao_gio_2','on') %}
      teal{% else %}grey{% endif %}
    entity: switch.t31_fan_dao_gio_2
    tap_action:
      action: toggle
    card_mod:
      style: |
        :host {
          width: 48px !important;
          min-width: 48px !important;
          max-width: 48px !important;
          flex: 0 0 48px !important;
        }
        ha-card {
          border: none !important;
          box-shadow: none !important;
          padding: 0 !important;
          margin: 0 !important;
          background: transparent !important;
          --card-primary-font-size: 0px;
          --card-secondary-font-size: 0px;
        }
        :host {
          --mush-icon-size: 26px;
          --mush-spacing: 0px;
        }
card_mod:
  style: |
    :host {
      border: 2px solid #14b8a6;
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(20, 184, 166, 0.2);
      overflow: hidden;
    }
    ha-card {
      padding: 4px 4px !important;
      background: linear-gradient(135deg, #0f172a, #1e293b) !important;
    }
    #root {
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      width: 100% !important;
      gap: 0 !important;
    }
    #root > *:first-child {
      flex: 1 1 auto !important;
    }
    #root > *:last-child {
      flex: 0 0 48px !important;
      width: 48px !important;
      min-width: 48px !important;
      max-width: 48px !important;
    }
```
