# ESP32 ESPHome BLDC Smart Fan — T-Series

<!-- readme-axi type=esp32 -->

[![GitHub last commit](https://img.shields.io/github/last-commit/ngoviet/esp32-esphome-bldc-smart-fan)](https://github.com/ngoviet/esp32-esphome-bldc-smart-fan)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ESPHome](https://img.shields.io/badge/ESPHome-2026.4.3-blue)](https://esphome.io/)

[English](README.md) · **Tiếng Việt**

Bộ điều khiển quạt trần BLDC vô cấp kết nối WiFi, dùng board **ESP32** dev (30 chân hoặc 38 chân) +
**ESPHome**. Tích hợp sẵn với **Home Assistant** qua ESPHome API. Hỗ trợ **hai loại driver BLDC**:
điều khiển bằng tần số (T1-T3) và điều khiển bằng độ rộng xung PWM (T31, có đảo gió).

> 🇻🇳 Dự án do một người Việt tự xây dựng và duy trì — nếu nó giúp ích cho bạn, hãy
> [ủng hộ dự án](#ủng-hộ-dự-án).

## Mục lục

- [Tính năng](#tính-năng)
- [Phần cứng](#phần-cứng)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Cấu hình](#cấu-hình)
- [Home Assistant](#home-assistant)
- [Xử lý sự cố](#xử-lý-sự-cố)
- [Cách hoạt động](#cách-hoạt-động)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Phát triển](#phát-triển)

## Tính năng

- **Chỉnh tốc độ vô cấp** — 0–100% bằng núm xoay encoder hoặc thanh trượt Home Assistant
- **Hỗ trợ hai kiểu BLDC** — chế độ tần số (T1-T3) và chế độ duty cycle (T31)
- **Đảo gió bằng motor** (T31) — bật/tắt đảo gió độc lập qua MOSFET D4184
- **Phản hồi tức thì** — không trễ chuyển tiếp, hiệu chỉnh gamma tuyến tính
- **Đồng bộ chống nhấp nháy** — núm vặn thật và trạng thái HA luôn khớp nhau; khoá chống dội 2 giây
- **Giữ trạng thái** — tốc độ và trạng thái bật/tắt được giữ lại sau khi mất điện hay khởi động lại
- **Cập nhật firmware OTA** — flash qua WiFi, không cần mở hộp
- **Quản lý nhiều quạt** — mọi quạt dùng chung một codebase qua ESPHome packages
- **Sensor chẩn đoán** — thông số tốc độ (Hz hoặc %), phiên bản firmware, WiFi RSSI hiển thị trong HA
- **Chống glitch bằng micro-duty** — timer LEDC không bao giờ dừng; chuyển tốc độ mượt trên toàn dải

## Phần cứng

### Các model và loại driver BLDC

Dự án hỗ trợ hai kiến trúc driver quạt BLDC. Chọn theo mạch driver motor bạn đang có.

| Model | Board | Cách điều khiển | Tín hiệu CLK | Bổ sung |
|-------|-------|---------------|------------|--------|
| **T1 / T2 / T3** | ESP32 30 chân | **Tần số** (100–400 Hz, duty cố định 50%) | `inverted: false` | — |
| **T31** | ESP32 38 chân | **Duty cycle** (cố định 150 Hz, duty thay đổi 30–99.5%) | `inverted: true` (HIGH = dừng) | **Motor đảo gió** qua MOSFET D4184 (GPIO27) |

#### T1-T3: Điều khiển BLDC theo tần số

Phần lớn driver quạt trần BLDC (Lishui, Vego và các loại tương tự) dùng **sóng vuông tần số thay đổi** để đặt tốc độ motor. Driver đọc tần số tín hiệu CLK và chỉnh motor theo tỉ lệ:

| Độ sáng | Tần số |
|-----------|-----------|
| 0% (TẮT) | Không có tín hiệu |
| 1% | 103 Hz |
| 50% | 250 Hz |
| 100% | 400 Hz |

Duty cycle cố định 50%. **Ngoại vi phần cứng LEDC** của ESP32 tạo tín hiệu này trên GPIO26.

#### T31: Điều khiển BLDC theo duty cycle, có đảo gió

T31 dùng một loại driver BLDC khác, cần **PWM duty cycle thay đổi** ở tần số cố định (150 Hz). Cực tính tín hiệu bị đảo — **HIGH = motor dừng, độ rộng xung LOW = tốc độ**. Driver này hay gặp ở các quạt có motor đảo gió (swing) riêng.

| Độ sáng | Duty (đảo) | Tác dụng |
|-----------|----------------|--------|
| TẮT | 0.5% LOW (≈HIGH) | Motor dừng |
| 1% | 30% LOW | Tốc độ thấp nhất |
| 50% | 65% LOW | Tốc độ trung bình |
| 100% | 99.5% LOW | Tốc độ cao nhất |

**Điều khiển đảo gió:** motor đảo gió của T31 được chạy bằng **module MOSFET kép D4184** trên GPIO27. Một GPIO switch trong ESPHome bật/tắt motor đảo gió độc lập với tốc độ quạt chính — quạt có thể thổi cố định một hướng hoặc quét khắp phòng.

> **Vì sao 0.5%–99.5% mà không phải 0%–100%?** Output LEDC của ESPHome gọi `ledc_stop()` khi duty chạm đúng 0% hoặc 100%, gây glitch thoáng qua lúc khởi động lại. Giới hạn ở 0.5%–99.5% giúp timer LEDC chạy liên tục — chuyển tốc độ liền mạch, không hụt hay nhấp nháy.

### Danh sách linh kiện (mỗi quạt)

| Linh kiện | T1-T3 | T31 | Ghi chú |
|-----------|-------|-----|-------|
| Board ESP32 Dev | 30 chân | 38 chân | 240 MHz, flash 4 MB |
| Encoder xoay EC11 | ✓ | ✓ | 20 xung, có nút nhấn |
| Driver quạt BLDC (tần số) | ✓ | — | Đầu vào CLK 100–400 Hz |
| Driver quạt BLDC (duty cycle) | — | ✓ | PWM 150 Hz, logic đảo |
| Module MOSFET D4184 | — | ✓ | MOSFET kép cho motor đảo gió |
| Motor quạt trần BLDC | ✓ | ✓ | Điện áp khớp với mạch driver |
| Motor đảo gió | — | ✓ | Motor swing riêng (chỉ T31) |
| Dây nối | ✓ | ✓ | Đầu Dupont hoặc JST |

### Sơ đồ chân GPIO

#### T1 / T2 / T3 (ESP32 30 chân)

```
ESP32 GPIO    Function
──────────    ────────
GPIO26   →    CLK output (frequency signal to BLDC driver)
GPIO32   ←    EC11 CLK (rotary encoder, INPUT_PULLUP)
GPIO33   ←    EC11 DT  (rotary encoder, INPUT_PULLUP)
GPIO25   ←    EC11 SW  (push button, INPUT_PULLUP, inverted)
```

#### T31 (ESP32 38 chân)

```
ESP32 GPIO    Function
──────────    ────────
GPIO26   →    CLK output (duty-cycle PWM to BLDC driver, inverted)
GPIO27   →    D4184 MOSFET gate (oscillation swing motor ON/OFF)
GPIO32   ←    EC11 CLK (rotary encoder, INPUT_PULLUP)
GPIO33   ←    EC11 DT  (rotary encoder, INPUT_PULLUP)
GPIO25   ←    EC11 SW  (push button, INPUT_PULLUP, inverted)
```

> **Quan trọng:** mọi linh kiện (ESP32, driver BLDC, module MOSFET) **phải nối chung mass (GND)**. Tín hiệu CLK lấy điện áp so với mass — không chung GND thì driver không đọc được tín hiệu.

### Sơ đồ nối dây (T1-T3)

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

### Sơ đồ nối dây (T31)

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

> **Mua ở đâu:** tìm "BLDC fan driver board", "quạt trần BLDC" hoặc "mạch điều khiển quạt BLDC" trên Shopee, Lazada hay AliExpress. Hãng hay gặp: Lishui, Vego. Module MOSFET D4184 thì tìm "D4184 dual MOSFET" hoặc "mạch công tắc MOSFET D4184".

## Bắt đầu nhanh

### 0. Cài ESPHome CLI

```bash
pip install esphome
esphome version   # cần 2026.4.3 trở lên
```

> Người dùng Home Assistant OS có thể dùng add-on ESPHome. Hướng dẫn này dùng CLI để sửa – build nhanh hơn và flash song song nhiều thiết bị.

### 1. Clone

```bash
git clone https://github.com/ngoviet/esp32-esphome-bldc-smart-fan.git
cd esp32-esphome-bldc-smart-fan
```

### 2. Cấu hình WiFi

```bash
cp secrets_example.yaml secrets.yaml
```

Sửa `secrets.yaml`, điền thông tin WiFi của bạn:

```yaml
wifi_ssid: "YourWiFiSSID"
wifi_password: "YourWiFiPassword"
```

### 3. Nối dây phần cứng

Làm theo [sơ đồ chân GPIO](#sơ-đồ-chân-gpio) của model bạn dùng. Kiểm tra kỹ dây GND chung.

### 4. Flash firmware

```powershell
# PowerShell (khuyên dùng)
.\flash.ps1 -Device t1-fan -IP 192.168.20.201

# Hoặc nhấp đúp tệp .bat
# Hoặc gọi thẳng ESPHome CLI:
esphome run t1-fan.yaml --device 192.168.20.201
```

Lần build đầu mất khoảng 2 phút (biên dịch ESP-IDF + Arduino). Các lần sau khoảng 30 giây (build tăng dần).

### 5. Thêm vào Home Assistant

Thiết bị tự được phát hiện qua mDNS. Vào **Settings → Devices & Services → ESPHome** và bấm **Configure**. Quạt hiện ra dưới dạng thực thể **Light** (thanh trượt tốc độ) cùng các sensor chẩn đoán — xem [Home Assistant](#home-assistant).

### 6. Thêm thẻ dashboard (tuỳ chọn)

Chép YAML trong `ha-dashboard/` vào trình sửa raw của dashboard HA. Mỗi thẻ dùng `mushroom-light-card` + `mushroom-legacy-template-card` kèm CSS tuỳ chỉnh cho giao diện gọn, hiện đại.

## Cấu hình

### Substitutions (theo từng thiết bị)

| Tham số | Mặc định T1-T3 | Mặc định T31 | Mô tả |
|-----------|--------------|-------------|-------------|
| `device_name` | `t1-fan` | `t31-fan` | Tên node ESPHome (không dấu cách) |
| `clk_pin` | `GPIO26` | `GPIO26` | Chân output PWM LEDC |
| `clk_channel` | `0` | `8` | Kênh LEDC (T31 dùng kênh LS để tránh glitch) |
| `clk_inverted` | `false` | `true` | Đảo cực tính output LEDC |
| `speed_duty_mode_val` | `false` | `true` | `true` = chế độ duty cycle, `false` = chế độ tần số |
| `default_frequency` | `150` | `150` | Tần số gốc LEDC (Hz) |
| `freq_min` | `100` | `100` | Tần số nhỏ nhất (Hz) — chỉ ở chế độ tần số |
| `freq_max` | `400` | `400` | Tần số lớn nhất (Hz) — chỉ ở chế độ tần số |
| `encoder_resolution` | `1` | `1` | Số xung EC11 mỗi nấc (dùng `4` nếu bị dội) |
| `speed_param_name` | `Fan Frequency` | `Fan Duty` | Tên sensor chẩn đoán |
| `speed_param_unit` | `Hz` | `%` | Đơn vị sensor chẩn đoán |
| `firmware_version` | `2.0.2` | `2.0.3` | Phiên bản hiển thị trong HA |

### Lắp nhiều quạt

Chép cấu hình một thiết bị có sẵn rồi đổi tên:

```bash
cp t1-fan.yaml t4-fan.yaml
```

Sửa `t4-fan.yaml`:

```yaml
substitutions:
  device_name: "t4-fan"
  device_friendly_name: "T4 Fan"
  # ... giữ nguyên chân GPIO, dải tần số, v.v.
```

Flash:

```bash
.\flash.ps1 -Device t4-fan -IP 192.168.20.xxx
```

Mọi hành vi được kế thừa từ `common/base.yaml`. Không lặp lại logic.

### Hướng dẫn tinh chỉnh

| Hiện tượng | Tham số | Cách chỉnh |
|---------|-----------|--------|
| Núm vặn nhảy 4 bước mỗi nấc | `encoder_resolution` | Đặt thành `4` |
| Driver quạt dùng dải tần số khác | `freq_min` / `freq_max` | Đặt theo datasheet của driver |
| T31 tốc độ thấp nhất quá yếu, không khởi động được | Công thức duty trong write lambda | Tăng mức gốc `0.30f` (hiện là 30%) |
| T31 dừng quá đột ngột ở mức cao nhất | Trần duty | Chỉnh `0.995f` (hiện là 99.5%) |
| Flash lỗi (OTA timeout) | — | Flash lần đầu qua cổng serial (cổng COM) |

## Home Assistant

### Thực thể

#### Thực thể T1-T3

| Thực thể | Loại | Mô tả |
|--------|------|-------------|
| `light.<device>_speed` | Light | Thanh trượt tốc độ (1–100% → 103–400 Hz) |
| `sensor.<device>_fan_frequency` | Sensor | Tần số CLK thực tế (Hz) |
| `sensor.<device>_firmware_version` | Sensor | Chuỗi phiên bản firmware |
| `sensor.<device>_wifi_rssi` | Sensor | Cường độ sóng WiFi (dBm) |
| `text_sensor.<device>_wifi_ip` | Text Sensor | Địa chỉ IP thiết bị |
| `text_sensor.<device>_wifi_ssid` | Text Sensor | SSID WiFi đang kết nối |
| `button.<device>_restart_thiet_bi` | Button | Khởi động lại mềm |

#### Thực thể T31 (bổ sung)

| Thực thể | Loại | Mô tả |
|--------|------|-------------|
| `sensor.t31_fan_fan_duty` | Sensor | Duty cycle % (thông số tốc độ thực tế) |
| `switch.t31_fan_dao_gio` | Switch | Bật/tắt đảo gió (MOSFET GPIO27) |

### Ví dụ automation

#### Hẹn giờ tự tắt

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

#### Tốc độ theo nhiệt độ (chế độ tần số)

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

#### Tự chỉnh tốc độ theo công suất (xem ha-dashboard/)

Các tệp `ha-dashboard/01_p*_fan_speed_control.yaml` chứa automation dùng ngay, ánh xạ công suất tiêu thụ của thiết bị sang tốc độ quạt — hữu ích để làm mát dàn đào coin, server hay tủ điện.

## Xử lý sự cố

| Vấn đề | Nguyên nhân thường gặp | Cách khắc phục |
|---------|-------------|-----|
| Quạt không quay | Không chung GND | Nối GND ESP32 ↔ GND driver BLDC |
| Tốc độ nhảy lung tung | Encoder bị dội | Đặt `encoder_resolution: "4"` |
| Quạt vẫn quay chậm khi "TẮT" (T31) | Micro-duty quá cao | Hạ `0.005f` xuống `0.001f` ở nhánh OFF |
| Tốc độ bị hụt khi đổi tốc độ (T31) | Glitch `ledc_stop()` ở 0% hoặc 100% | Bảo đảm dải duty là 0.5%–99.5% |
| "No such file: secrets.yaml" | Thiếu tệp secrets | Chép `secrets_example.yaml` → `secrets.yaml` |
| Build lỗi sau khi pull | Cache build cũ | Xoá `.esphome/build/` rồi biên dịch lại |
| OTA lỗi (connection timeout) | Sóng WiFi quá yếu | Đưa ESP32 lại gần AP, hoặc flash qua serial |

## Cách hoạt động

### Thuật toán tốc độ — chế độ tần số (T1-T3)

```
frequency = (brightness × 300) + 100

Trong đó:
  brightness = 0.0 – 1.0 (thanh trượt Home Assistant)
  Kết quả: 100 – 400 Hz, duty luôn 50%
```

- Độ sáng dưới 1% → quạt TẮT (tắt output PWM)
- Chênh lệch = 300 Hz → mỗi bước 1% = đúng 3 Hz (tính số nguyên, không làm tròn)
- Script `apply_freq` cấu hình lại timer LEDC một cách nguyên tử với `mode: restart`

### Thuật toán tốc độ — chế độ duty cycle (T31)

```
duty = 0.30 + (brightness × 0.70)
duty clamped to [0.005, 0.995]

Trong đó:
  brightness = 0.0 – 1.0
  Kết quả: duty 30% – 99.5% ở tần số cố định 150 Hz (đảo: HIGH = dừng)
```

- Trạng thái TẮT: duty 0.5% → xung LOW ~33 µs mỗi chu kỳ 6.67 ms → motor coi như dừng
- Timer LEDC không bao giờ gọi `ledc_stop()` — chuyển tốc độ mượt trên toàn dải
- Cờ `syncing_from_ha` chặn callback encoder ghi hai lần khi HA chỉnh tốc độ

### Đồng bộ chống nhấp nháy

1. Vặn núm thật → `disable_sync_until = millis()` → khoá đồng bộ từ HA 2 giây
2. HA đổi độ sáng → `syncing_from_ha = true` → bỏ qua callback encoder → chỉ ghi LEDC một lần
3. An toàn khi tràn bộ đếm: `millis() - disable_sync_until >= 2000` dùng phép trừ không dấu

### Chọn kênh LEDC

T31 dùng **kênh 8** (low-speed) để tránh một lỗi phần cứng đã biết của ESP32: các kênh high-speed (0–7) lặng lẽ bỏ qua lệnh `ledcWrite()` trong cùng một chu kỳ PWM. Kênh low-speed áp dụng thay đổi ngay lập tức — rất quan trọng để chuyển duty cycle mượt ở 150 Hz.

## Cấu trúc dự án

```
esp32-esphome-bldc-smart-fan/
├── common/
│   ├── base.yaml                # Logic dùng chung — hai chế độ tần số + duty cycle
│   └── base-oscillation.yaml    # base.yaml + GPIO switch cho đảo gió T31
├── t1-fan.yaml                  # Cấu hình thiết bị T1 (chỉ substitutions)
├── t2-fan.yaml                  # Cấu hình thiết bị T2
├── t3-fan.yaml                  # Cấu hình thiết bị T3
├── t31-fan.yaml                 # Cấu hình thiết bị T31 (duty cycle + đảo gió)
├── ha-dashboard/                # Đoạn YAML dashboard Home Assistant
│   ├── dashboard_fan_p1.md
│   ├── dashboard_fan_p2.md
│   ├── dashboard_fan_p8.md
│   ├── dashboard_fan_t31.md
│   └── 01_p*_fan_speed_control.yaml   # Automation tự chỉnh tốc độ
├── secrets_example.yaml         # Mẫu thông tin WiFi (chép thành secrets.yaml)
├── secrets.yaml                 # Thông tin WiFi của bạn (đã gitignore — KHÔNG COMMIT)
├── flash.ps1                    # PowerShell: .\flash.ps1 -Device t1-fan -IP 192.168.20.201
├── *.bat                        # Flash nhanh cho từng thiết bị
├── README.md
└── .gitignore
```

**Kiến trúc:** ESPHome `packages:` + `!include`. YAML của mỗi thiết bị chỉ khai báo `substitutions:` và nạp logic dùng chung. Sửa `common/base.yaml` một lần — mọi quạt nhận bản cập nhật ở lần flash tiếp theo.

## Phát triển

### Đóng góp

1. Fork repo
2. Tạo nhánh tính năng (`git checkout -b feat/my-feature`)
3. Sửa code — logic dùng chung nên đặt trong `common/base.yaml`, thay đổi riêng từng model đặt trong YAML của thiết bị
4. Thử trên phần cứng thật
5. Gửi pull request

### Ghi công

- **Tác giả:** [ngoviet](https://github.com/ngoviet)
- Xây dựng bằng [ESPHome](https://esphome.io/) (Arduino framework trên ESP-IDF)
- Lấy cảm hứng từ cộng đồng nhà thông minh Việt Nam

<!-- support:start -->
## Ủng hộ dự án

<p align="center">
  <img src="https://raw.githubusercontent.com/ngoviet/.github/main/assets/support/banner.svg" width="720" alt="Built and maintained by one person in Việt Nam">
</p>

<p align="center">
  <a href="https://buymeacoffee.com/ngoviet"><img src="https://raw.githubusercontent.com/ngoviet/.github/main/assets/support/btn-coffee.svg" height="56" alt="Buy me a coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/ngoviet"><img src="https://raw.githubusercontent.com/ngoviet/.github/main/assets/support/btn-sponsors.svg" height="56" alt="GitHub Sponsors"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/ngoviet/.github/main/assets/support/vietqr-card.svg" width="300" alt="VietQR — MB Bank — NGO DUC VIET — 911051212">
</p>

<p align="center"><sub>🇻🇳 VietQR: quét bằng app ngân hàng bất kỳ, nội dung <code>Ung ho esp32-esphome-bldc-smart-fan</code>. Cảm ơn bạn đã giúp dự án tiếp tục phát triển!</sub></p>
<p align="center"><sub>Tiền mã hoá (mạng BEP20): <code>0xcbf0402b232cb24b4d998f09a4884f87b5f74750</code> · USDT · USDC · BNB · ETH · BTC</sub></p>
<!-- support:end -->

## Giấy phép

[MIT](LICENSE) © Ngô Đức Việt.
