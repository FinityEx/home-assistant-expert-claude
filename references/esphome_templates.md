# ESPHome Configuration Patterns (2025/2026)

## Core Philosophy
**Modularize and Secure.** Use packages to avoid repetition and `secrets.yaml` for credentials.

## 1. Directory Structure
```text
esphome/
├── common/
│   ├── base.yaml         # WiFi, API, OTA, Logger
│   └── sensors_esp32.yaml
├── devices/
│   └── living_room_light.yaml
└── secrets.yaml
```

## 2. Common Package (`common/base.yaml`)
Include this in every device.
```yaml
substitutions:
  name: "default-name"
  friendly_name: "Default Device"

esphome:
  name: ${name}
  friendly_name: ${friendly_name}
  # Platform-specific config (can be overridden)
  platform: ESP32
  board: esp32dev

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  # Essential for recovery
  fallback_ap:
    ssid: "Fallback Hotspot"
    password: !secret ap_password

api:
  encryption:
    key: !secret api_key

ota:
  password: !secret ota_password

logger:
  level: DEBUG

# Minimal health sensors
sensor:
  - platform: uptime
    name: "Uptime"
  - platform: wifi_signal
    name: "WiFi Signal"
    update_interval: 60s
```

## 3. Device Configuration Example
```yaml
packages:
  base: !include common/base.yaml

substitutions:
  name: "kitchen-led"
  friendly_name: "Kitchen Under Cabinet"

# Hardware specific
esp32:
  board: esp32-c3-devkitm-1
  framework:
    type: esp-idf # Preferred for 2025

light:
  - platform: neopixelbus
    type: GRB
    variant: WS2812
    pin: GPIO8
    num_leds: 60
    name: "Light Strip"
```

## 4. Bluetooth Proxy (ESP32 only)
Turn any ESP32 into a BT proxy for Home Assistant.
```yaml
bluetooth_proxy:
  active: true
```

## 5. Security Checklist
- [ ] `api` encryption enabled?
- [ ] `ota` password set (unique if possible)?
- [ ] `wifi` fallback AP configured?
- [ ] `secrets.yaml` used for all passwords?
