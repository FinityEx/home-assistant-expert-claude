# ESPHome Templates Reference (2025/2026)

**When to use this**: Reference for all ESPHome device configurations, from basic sensors to advanced voice assistants. Use these templates as starting points for production-ready ESPHome devices.

## Core Philosophy
**Modular, Secure, and Maintainable.** Use package-based architecture to avoid repetition, `secrets.yaml` for all credentials, and follow ESP-IDF framework for ESP32-S3/C3 devices.

---

## Table of Contents
1. [Directory Structure & Package Architecture](#directory-structure--package-architecture)
2. [Board Configurations](#board-configurations)
3. [Common Base Package](#common-base-package)
4. [Voice Assistant Pipeline](#voice-assistant-pipeline)
5. [M5Stack Device Configurations](#m5stack-device-configurations)
6. [WLED Integration](#wled-integration)
7. [I2C Sensor Patterns](#i2c-sensor-patterns)
8. [Bluetooth Proxy](#bluetooth-proxy)
9. [Deep Sleep Patterns](#deep-sleep-patterns)
10. [OTA Update Strategies](#ota-update-strategies)
11. [GPIO Patterns](#gpio-patterns)
12. [UART/Serial Integration](#uartserial-integration)
13. [Display Patterns](#display-patterns)
14. [Lambda & Custom Components](#lambda--custom-components)
15. [Framework Decision Guide](#framework-decision-guide)
16. [Web Server Component](#web-server-component)
17. [Polish Language & Voice](#polish-language--voice)
18. [Security Best Practices](#security-best-practices)

---

## Directory Structure & Package Architecture

**When to use**: Always use package-based architecture for maintainability and DRY principles.

### Recommended Structure
```text
esphome/
├── common/
│   ├── base.yaml              # WiFi, API, OTA, logger
│   ├── base_esp32.yaml        # ESP32-specific base
│   ├── base_esp32s3.yaml      # ESP32-S3 with PSRAM
│   ├── base_esp8266.yaml      # ESP8266 specifics
│   ├── sensors_i2c.yaml       # Common I2C sensors
│   ├── voice_assistant.yaml   # Voice pipeline
│   └── bluetooth_proxy.yaml   # BLE proxy config
├── devices/
│   ├── living_room_temp.yaml
│   ├── bedroom_voice.yaml
│   ├── garage_door.yaml
│   └── garden_moisture.yaml
├── .gitignore                 # Exclude secrets
└── secrets.yaml               # All credentials
```

### .gitignore
```text
secrets.yaml
*.bin
.esphome/
```

---

## Board Configurations

### ESP32 (Original)
**When to use**: General purpose, well-supported, good for most projects

```yaml
esp32:
  board: esp32dev
  framework:
    type: arduino
    version: recommended
```

**Common boards**:
- `esp32dev` - Generic ESP32 development board
- `nodemcu-32s` - NodeMCU-32S
- `esp32-c3-devkitm-1` - ESP32-C3 DevKit
- `esp32-s3-devkitc-1` - ESP32-S3 DevKit

### ESP32-S3 with PSRAM
**When to use**: Voice assistants, displays, memory-intensive tasks

```yaml
esp32:
  board: esp32-s3-devkitc-1
  variant: esp32s3
  framework:
    type: esp-idf
    version: recommended
    sdkconfig_options:
      CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"
      CONFIG_ESP32S3_DATA_CACHE_64KB: "y"
      CONFIG_ESP32S3_DATA_CACHE_LINE_64B: "y"
      CONFIG_AUDIO_BOARD_CUSTOM: "y"

psram:
  mode: octal
  speed: 80MHz
```

### ESP32-C3 (RISC-V)
**When to use**: Low power, smaller projects, Bluetooth 5.0 LE

```yaml
esp32:
  board: esp32-c3-devkitm-1
  variant: esp32c3
  framework:
    type: esp-idf
    version: recommended
```

### ESP8266
**When to use**: Legacy devices, simple sensors, budget constraints

```yaml
esp8266:
  board: nodemcuv2
  framework:
    version: recommended
  restore_from_flash: true  # Persist state across reboots
```

---

## Common Base Package

**When to use**: Include in every device for consistency and security

### common/base.yaml
```yaml
substitutions:
  name: "device-name"
  friendly_name: "Device Name"
  device_description: "Description for logs"

esphome:
  name: ${name}
  friendly_name: ${friendly_name}
  comment: ${device_description}
  project:
    name: "homeassistant.esphome-device"
    version: "1.0"
  on_boot:
    priority: -100
    then:
      - logger.log: "Device started successfully"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  
  # Fast connect for known networks
  fast_connect: true
  
  # Power saving for battery devices
  # power_save_mode: LIGHT
  
  # Static IP for reliability (optional)
  # manual_ip:
  #   static_ip: 192.168.1.100
  #   gateway: 192.168.1.1
  #   subnet: 255.255.255.0
  
  # Fallback AP for recovery
  ap:
    ssid: "${friendly_name} Fallback"
    password: !secret ap_password

# Enable fallback portal
captive_portal:

api:
  encryption:
    key: !secret api_key
  reboot_timeout: 0s  # Disable auto-reboot on API disconnect

ota:
  - platform: esphome
    password: !secret ota_password
    safe_mode: true
    reboot_timeout: 10min
    num_attempts: 5

logger:
  level: INFO
  logs:
    sensor: WARN
    wifi: INFO
    api: INFO

# Health monitoring sensors
sensor:
  - platform: wifi_signal
    name: "WiFi Signal"
    update_interval: 60s
    entity_category: diagnostic
    
  - platform: uptime
    name: "Uptime"
    update_interval: 60s
    entity_category: diagnostic

text_sensor:
  - platform: wifi_info
    ip_address:
      name: "IP Address"
      entity_category: diagnostic
    mac_address:
      name: "MAC Address"
      entity_category: diagnostic
  
  - platform: version
    name: "ESPHome Version"
    entity_category: diagnostic

button:
  - platform: restart
    name: "Restart"
    entity_category: diagnostic
```

### secrets.yaml Template
```yaml
# WiFi
wifi_ssid: "YourSSID"
wifi_password: "YourWiFiPassword"
ap_password: "FallbackPassword123"

# API & OTA
api_key: "base64-encoded-key-here"
ota_password: "OTAPassword123"

# Voice Assistant (if needed)
tts_url: "http://homeassistant.local:8123"
wake_word_model: "okay_nabu"
```

---

## Voice Assistant Pipeline

**When to use**: Building voice assistants with microphone → wake word → STT → intent → TTS → speaker

### Complete Voice Pipeline
```yaml
# Include base configuration
packages:
  base: !include common/base.yaml

# ESP32-S3 required for voice processing
esp32:
  board: esp32-s3-devkitc-1
  variant: esp32s3
  framework:
    type: esp-idf
    sdkconfig_options:
      CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"

psram:
  mode: octal
  speed: 80MHz

# I2S Microphone
microphone:
  - platform: i2s_audio
    id: mic
    adc_type: external
    i2s_din_pin: GPIO2
    pdm: false
    sample_rate: 16000
    bits_per_sample: 32bit

# I2S Speaker
speaker:
  - platform: i2s_audio
    id: spkr
    dac_type: external
    i2s_dout_pin: GPIO3
    mode: mono
    sample_rate: 16000

# Voice Assistant
voice_assistant:
  id: va
  microphone: mic
  speaker: spkr
  use_wake_word: true
  
  # Noise suppression (ESP-IDF only)
  noise_suppression_level: 2
  auto_gain: 31dBFS
  volume_multiplier: 2.0
  
  on_listening:
    - light.turn_on:
        id: led
        effect: pulse
  
  on_stt_end:
    - light.turn_off: led
  
  on_tts_start:
    - light.turn_on:
        id: led
        brightness: 50%
  
  on_end:
    - light.turn_off: led
  
  on_error:
    - light.turn_on:
        id: led
        red: 100%
        green: 0%
        blue: 0%
    - delay: 1s
    - light.turn_off: led

# LED indicator
light:
  - platform: esp32_rmt_led_strip
    id: led
    rgb_order: GRB
    pin: GPIO27
    num_leds: 1
    rmt_channel: 0
    chipset: WS2812
    name: "Status LED"
    effects:
      - pulse:
          transition_length: 0.5s
          update_interval: 0.5s

# Manual trigger button
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO39
      inverted: true
      mode:
        input: true
        pullup: true
    name: "Push Button"
    on_press:
      - voice_assistant.start:
```

### Pipeline Configuration Options
```yaml
voice_assistant:
  # Wake word detection
  use_wake_word: true  # Enable wake word detection
  
  # Audio processing (ESP-IDF only)
  noise_suppression_level: 2  # 0-4, higher = more suppression
  auto_gain: 31dBFS  # Automatic gain control
  volume_multiplier: 4.0  # Increase speaker volume
  
  # Advanced timing
  vad_threshold: 3  # Voice activity detection sensitivity
  
  # Language
  # Configured in Home Assistant, not ESPHome
```

---

## M5Stack Device Configurations

### M5Stack Atom Echo
**When to use**: Compact voice assistant with built-in microphone and speaker

```yaml
substitutions:
  name: "atom-echo-kitchen"
  friendly_name: "Kitchen Voice"

packages:
  base: !include common/base.yaml

esp32:
  board: m5stack-atom
  framework:
    type: arduino

# I2S Audio for built-in components
i2s_audio:
  i2s_lrclk_pin: GPIO33
  i2s_bclk_pin: GPIO19

microphone:
  - platform: i2s_audio
    id: echo_microphone
    i2s_din_pin: GPIO23
    adc_type: external
    pdm: true

speaker:
  - platform: i2s_audio
    id: echo_speaker
    dac_type: external
    i2s_dout_pin: GPIO22
    mode: mono

voice_assistant:
  microphone: echo_microphone
  speaker: echo_speaker
  use_wake_word: true
  noise_suppression_level: 2
  auto_gain: 31dBFS
  volume_multiplier: 2.0

# LED indicator (built-in WS2812)
light:
  - platform: esp32_rmt_led_strip
    id: led
    name: "LED"
    pin: GPIO27
    num_leds: 1
    rmt_channel: 0
    chipset: WS2812
    rgb_order: GRB
    default_transition_length: 0s
    effects:
      - pulse:
      - strobe:

# Button (built-in)
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO39
      inverted: true
    name: "Button"
    on_multi_click:
      - timing:
          - ON for at most 1s
          - OFF for at least 0.5s
        then:
          - voice_assistant.start:
      - timing:
          - ON for at least 2s
        then:
          - voice_assistant.stop:
```

### M5Stack AtomS3 Lite with Display
**When to use**: Voice assistant with visual feedback on 128x128 LCD

```yaml
substitutions:
  name: "atoms3-living-room"
  friendly_name: "Living Room Voice"

packages:
  base: !include common/base.yaml

esp32:
  board: esp32-s3-devkitc-1
  variant: esp32s3
  framework:
    type: esp-idf
    sdkconfig_options:
      CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"

psram:
  mode: octal
  speed: 80MHz

# I2S Audio
i2s_audio:
  - id: i2s_in
    i2s_lrclk_pin: GPIO7
    i2s_bclk_pin: GPIO8
  - id: i2s_out
    i2s_lrclk_pin: GPIO5
    i2s_bclk_pin: GPIO6

microphone:
  - platform: i2s_audio
    i2s_audio_id: i2s_in
    id: mic
    adc_type: external
    i2s_din_pin: GPIO2
    pdm: false
    sample_rate: 16000
    bits_per_sample: 32bit

speaker:
  - platform: i2s_audio
    i2s_audio_id: i2s_out
    id: spkr
    dac_type: external
    i2s_dout_pin: GPIO4
    mode: mono

# ST7789 Display (128x128)
spi:
  clk_pin: GPIO17
  mosi_pin: GPIO21

display:
  - platform: st7789v
    model: TTGO TDisplay 135x240
    cs_pin: GPIO15
    dc_pin: GPIO33
    reset_pin: GPIO34
    rotation: 0
    lambda: |-
      if (id(va).is_running()) {
        it.print(64, 60, id(font), Color(255,255,255), TextAlign::CENTER, "Listening...");
      } else {
        it.print(64, 60, id(font), Color(100,100,100), TextAlign::CENTER, "Ready");
      }

font:
  - file: "fonts/arial.ttf"
    id: font
    size: 20

voice_assistant:
  id: va
  microphone: mic
  speaker: spkr
  use_wake_word: true
  on_listening:
    - display.page.show: listening_page
  on_idle:
    - display.page.show: idle_page

# Built-in button
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO41
      inverted: true
    name: "Button"
    on_press:
      - voice_assistant.start:
```

---

## WLED Integration

**When to use**: Integrate ESPHome devices with WLED for advanced LED effects

### WLED Sync Pattern
```yaml
# ESPHome device that mirrors WLED state
light:
  - platform: rgb
    name: "LED Strip"
    id: led_strip
    red: output_red
    green: output_green
    blue: output_blue

output:
  - platform: ledc
    pin: GPIO13
    id: output_red
  - platform: ledc
    pin: GPIO12
    id: output_green
  - platform: ledc
    pin: GPIO14
    id: output_blue

# MQTT subscription to WLED
mqtt:
  broker: !secret mqtt_broker
  username: !secret mqtt_user
  password: !secret mqtt_pass
  on_message:
    - topic: wled/livingroom/v
      then:
        - lambda: |-
            auto call = id(led_strip).turn_on();
            call.set_brightness(atof(x.c_str()) / 255.0);
            call.perform();
```

### Native WLED on ESPHome Device
```yaml
# Use WLED firmware instead of ESPHome for complex LED projects
# Flash WLED binary directly to ESP32/ESP8266
# Then control via Home Assistant WLED integration

# ESPHome sensors can coexist with WLED via UART/I2C bridge
# or use separate ESP for sensors
```

---

## I2C Sensor Patterns

**When to use**: Connect multiple I2C sensors to a single ESP device

### I2C Bus Configuration
```yaml
i2c:
  sda: GPIO21
  scl: GPIO22
  scan: true  # Scan and log all detected devices on boot
  frequency: 100kHz  # Default, increase to 400kHz if supported
```

### BME280 (Temperature, Humidity, Pressure)
```yaml
sensor:
  - platform: bme280
    temperature:
      name: "Temperature"
      oversampling: 16x
      filters:
        - offset: -0.5  # Calibration offset
    pressure:
      name: "Pressure"
      oversampling: 16x
    humidity:
      name: "Humidity"
      oversampling: 16x
    address: 0x76  # or 0x77
    update_interval: 60s
```

### BME680 (Air Quality)
```yaml
sensor:
  - platform: bme680
    temperature:
      name: "Temperature"
    pressure:
      name: "Pressure"
    humidity:
      name: "Humidity"
    gas_resistance:
      name: "Gas Resistance"
    address: 0x76
    update_interval: 60s
```

### SHT3x (Precision Temperature & Humidity)
```yaml
sensor:
  - platform: sht3xd
    temperature:
      name: "Temperature"
      accuracy: high
    humidity:
      name: "Humidity"
      accuracy: high
    address: 0x44
    update_interval: 30s
```

### AHT10/AHT20 (Budget Temp/Humidity)
```yaml
sensor:
  - platform: aht10
    temperature:
      name: "Temperature"
    humidity:
      name: "Humidity"
    update_interval: 30s
```

### BH1750 (Light Level)
```yaml
sensor:
  - platform: bh1750
    name: "Illuminance"
    address: 0x23
    update_interval: 30s
    resolution: 0.5  # lx resolution
```

### SGP30 (eCO2 and TVOC)
```yaml
sensor:
  - platform: sgp30
    eco2:
      name: "eCO2"
      accuracy_decimals: 0
    tvoc:
      name: "TVOC"
      accuracy_decimals: 0
    address: 0x58
    update_interval: 1s
    baseline:
      eco2_baseline: 0x8B1D  # Save and restore for accuracy
      tvoc_baseline: 0x8C52
```

### Multi-Sensor Configuration
```yaml
i2c:
  sda: GPIO21
  scl: GPIO22
  scan: true

sensor:
  # BME280 environmental
  - platform: bme280
    temperature:
      name: "BME280 Temperature"
    pressure:
      name: "Pressure"
    humidity:
      name: "BME280 Humidity"
    address: 0x76
    update_interval: 60s
  
  # BH1750 light
  - platform: bh1750
    name: "Illuminance"
    address: 0x23
    update_interval: 30s
  
  # TSL2561 alternative light sensor
  - platform: tsl2561
    name: "TSL2561 Illuminance"
    address: 0x39
    update_interval: 30s
    is_cs_package: false
```

---

## Bluetooth Proxy

**When to use**: Extend Bluetooth range for Home Assistant, track BLE devices

### Basic Bluetooth Proxy
```yaml
esp32:
  board: esp32dev
  framework:
    type: esp-idf  # Required for BLE proxy

esp32_ble_tracker:
  scan_parameters:
    interval: 1100ms
    window: 1100ms
    active: true

bluetooth_proxy:
  active: true
```

### Bluetooth Proxy with iBeacon
```yaml
esp32_ble_tracker:
  scan_parameters:
    active: true

bluetooth_proxy:
  active: true

esp32_ble_beacon:
  type: iBeacon
  uuid: "12345678-1234-1234-1234-123456789012"
```

### Passive BLE Scanner (Battery Sensors)
```yaml
esp32_ble_tracker:
  scan_parameters:
    interval: 300ms
    window: 30ms
    active: false  # Passive scanning for lower power

sensor:
  - platform: xiaomi_lywsd03mmc
    mac_address: "A4:C1:38:XX:XX:XX"
    temperature:
      name: "Temperature"
    humidity:
      name: "Humidity"
    battery_level:
      name: "Battery"
```

---

## Deep Sleep Patterns

**When to use**: Battery-powered sensors that update infrequently

### Basic Deep Sleep
```yaml
deep_sleep:
  id: deep_sleep_control
  run_duration: 10s  # Stay awake for 10 seconds
  sleep_duration: 10min  # Sleep for 10 minutes

sensor:
  - platform: dht
    pin: GPIO4
    temperature:
      name: "Temperature"
    humidity:
      name: "Humidity"
    update_interval: 5s  # Read within run_duration
```

### Deep Sleep with External Wake
```yaml
deep_sleep:
  id: deep_sleep_control
  run_duration: 5s
  sleep_duration: 1h
  wakeup_pin: GPIO39
  wakeup_pin_mode: INVERT_WAKEUP  # Wake on LOW

binary_sensor:
  - platform: gpio
    pin:
      number: GPIO39
      mode: INPUT_PULLUP
    name: "Door Sensor"
    on_press:
      - deep_sleep.prevent: deep_sleep_control  # Stay awake
    on_release:
      - delay: 5s
      - deep_sleep.enter: deep_sleep_control  # Go to sleep
```

### Conditional Deep Sleep
```yaml
deep_sleep:
  id: deep_sleep_control
  sleep_duration: 30min

switch:
  - platform: gpio
    name: "Keep Awake"
    pin: GPIO2
    id: keep_awake_switch
    on_turn_on:
      - deep_sleep.prevent: deep_sleep_control
    on_turn_off:
      - deep_sleep.allow: deep_sleep_control

# OTA updates require staying awake
api:
  on_client_connected:
    - deep_sleep.prevent: deep_sleep_control
  on_client_disconnected:
    - delay: 5min  # Wait for potential OTA
    - deep_sleep.allow: deep_sleep_control
```

---

## OTA Update Strategies

### Standard OTA
```yaml
ota:
  - platform: esphome
    password: !secret ota_password
    safe_mode: true
    reboot_timeout: 10min
    num_attempts: 5
```

### OTA with HTTP Pull
```yaml
ota:
  - platform: esphome
    password: !secret ota_password
  
  # Auto-update on boot from URL
  - platform: http_request
    on_boot:
      then:
        - delay: 30s
        - http_request.get:
            url: http://homeassistant.local:8123/local/firmware/device.bin
            on_response:
              - lambda: |-
                  if (status_code == 200) {
                    ESP_LOGI("OTA", "Firmware available, updating...");
                  }
```

### Safe Mode Button
```yaml
button:
  - platform: safe_mode
    name: "Safe Mode Boot"
    entity_category: diagnostic

# If device becomes unresponsive, trigger safe mode
# from Home Assistant, then flash fixed firmware
```

---

## GPIO Patterns

### Binary Sensor (Button)
```yaml
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO0
      mode:
        input: true
        pullup: true
      inverted: true
    name: "Button"
    filters:
      - delayed_on: 10ms  # Debounce
      - delayed_off: 10ms
    on_press:
      - logger.log: "Button pressed"
    on_release:
      - logger.log: "Button released"
    on_click:
      min_length: 50ms
      max_length: 350ms
      then:
        - logger.log: "Single click"
    on_double_click:
      then:
        - logger.log: "Double click"
```

### Switch (Relay)
```yaml
switch:
  - platform: gpio
    name: "Relay"
    pin: GPIO12
    id: relay_1
    restore_mode: RESTORE_DEFAULT_OFF  # State after reboot
    on_turn_on:
      - delay: 1s
      - logger.log: "Relay activated"
    interlock: &interlock_group [relay_1, relay_2]  # Prevent simultaneous activation

  - platform: gpio
    name: "Relay 2"
    pin: GPIO13
    id: relay_2
    interlock: *interlock_group
```

### PWM Output (LED Dimming)
```yaml
output:
  - platform: ledc
    pin: GPIO5
    id: pwm_output
    frequency: 1000Hz

light:
  - platform: monochromatic
    output: pwm_output
    name: "Dimmable LED"
    gamma_correct: 2.8  # Perceptual brightness correction
```

### PWM Fan Control
```yaml
output:
  - platform: ledc
    pin: GPIO14
    id: fan_pwm
    frequency: 25000Hz

fan:
  - platform: speed
    output: fan_pwm
    name: "PWM Fan"
    speed_count: 100  # 0-100% speed control

sensor:
  - platform: pulse_counter
    pin: GPIO27
    name: "Fan Speed"
    unit_of_measurement: "RPM"
    filters:
      - multiply: 0.5  # Convert pulses to RPM (depends on sensor)
```

### Servo Control
```yaml
output:
  - platform: ledc
    pin: GPIO18
    id: servo_pwm
    frequency: 50Hz

servo:
  - platform: ledc
    id: my_servo
    output: servo_pwm
    auto_detach_time: 2s  # Reduce jitter

button:
  - platform: template
    name: "Servo 0°"
    on_press:
      - servo.write:
          id: my_servo
          level: -100%  # -100% = 0°
  
  - platform: template
    name: "Servo 90°"
    on_press:
      - servo.write:
          id: my_servo
          level: 0%  # 0% = 90°
  
  - platform: template
    name: "Servo 180°"
    on_press:
      - servo.write:
          id: my_servo
          level: 100%  # 100% = 180°
```

---

## UART/Serial Integration

### Basic UART
```yaml
uart:
  tx_pin: GPIO1
  rx_pin: GPIO3
  baud_rate: 9600

sensor:
  - platform: pmsx003
    type: PMSX003
    pm_2_5:
      name: "PM2.5"
    pm_10_0:
      name: "PM10"
```

### Multiple UART Buses
```yaml
uart:
  - id: uart_bus_1
    tx_pin: GPIO1
    rx_pin: GPIO3
    baud_rate: 9600
  
  - id: uart_bus_2
    tx_pin: GPIO17
    rx_pin: GPIO16
    baud_rate: 115200

sensor:
  - platform: pmsx003
    uart_id: uart_bus_1
    type: PMSX003
    pm_2_5:
      name: "Particulate Matter 2.5"
  
  - platform: mhz19
    uart_id: uart_bus_2
    co2:
      name: "CO2"
    temperature:
      name: "Temperature"
```

### Custom UART Protocol (Lambda)
```yaml
uart:
  tx_pin: GPIO17
  rx_pin: GPIO16
  baud_rate: 9600

sensor:
  - platform: custom
    lambda: |-
      auto my_sensor = new UARTSensor(id(uart_bus));
      App.register_component(my_sensor);
      return {my_sensor};
    sensors:
      name: "Custom UART Sensor"
```

---

## Display Patterns

### SSD1306 OLED (I2C, 128x64)
```yaml
i2c:
  sda: GPIO21
  scl: GPIO22

font:
  - file: "fonts/arial.ttf"
    id: font_small
    size: 12
  - file: "fonts/arial.ttf"
    id: font_large
    size: 20

display:
  - platform: ssd1306_i2c
    model: "SSD1306 128x64"
    address: 0x3C
    lambda: |-
      it.print(0, 0, id(font_large), "Hello!");
      it.printf(0, 20, id(font_small), "Temp: %.1f°C", id(temperature).state);
      it.printf(0, 35, id(font_small), "Humidity: %.0f%%", id(humidity).state);
      it.strftime(0, 50, id(font_small), "%H:%M:%S", id(homeassistant_time).now());

time:
  - platform: homeassistant
    id: homeassistant_time
```

### ST7789 TFT (SPI, 240x240)
```yaml
spi:
  clk_pin: GPIO18
  mosi_pin: GPIO19

color:
  - id: my_red
    red: 100%
  - id: my_green
    green: 100%
  - id: my_blue
    blue: 100%

display:
  - platform: st7789v
    model: TTGO TDisplay 135x240
    cs_pin: GPIO5
    dc_pin: GPIO16
    reset_pin: GPIO23
    rotation: 270
    lambda: |-
      it.fill(Color(0, 0, 0));
      it.print(120, 80, id(font_large), id(my_green), TextAlign::CENTER, "ESPHome");
      it.printf(120, 120, id(font_small), id(my_blue), TextAlign::CENTER, "%.1f°C", id(temp).state);
```

### ILI9341 TFT (SPI, 320x240)
```yaml
spi:
  clk_pin: GPIO14
  mosi_pin: GPIO13
  miso_pin: GPIO12

display:
  - platform: ili9341
    model: TFT 2.4
    cs_pin: GPIO15
    dc_pin: GPIO2
    reset_pin: GPIO4
    rotation: 90
    lambda: |-
      it.rectangle(0, 0, 320, 240, id(my_blue));
      it.print(160, 100, id(font_large), id(my_red), TextAlign::CENTER, "Home Status");
      it.printf(160, 140, id(font_small), id(my_green), TextAlign::CENTER, 
                "Temp: %.1f°C", id(temperature).state);
```

### Display Pages
```yaml
display:
  - platform: ssd1306_i2c
    id: oled
    pages:
      - id: page1
        lambda: |-
          it.print(0, 0, id(font), "Page 1");
          it.printf(0, 20, id(font), "Temp: %.1f°C", id(temp).state);
      
      - id: page2
        lambda: |-
          it.print(0, 0, id(font), "Page 2");
          it.printf(0, 20, id(font), "Humidity: %.0f%%", id(humidity).state);

interval:
  - interval: 5s
    then:
      - display.page.show_next: oled
      - component.update: oled
```

---

## Lambda & Custom Components

### Inline Lambda
```yaml
sensor:
  - platform: template
    name: "Heat Index"
    lambda: |-
      float temp = id(temperature).state;
      float hum = id(humidity).state;
      // Heat index calculation
      float hi = -42.379 + 2.04901523*temp + 10.14333127*hum 
                 - 0.22475541*temp*hum - 0.00683783*temp*temp 
                 - 0.05481717*hum*hum + 0.00122874*temp*temp*hum 
                 + 0.00085282*temp*hum*hum - 0.00000199*temp*temp*hum*hum;
      return hi;
    update_interval: 60s
    unit_of_measurement: "°C"
```

### Global Variables
```yaml
globals:
  - id: motion_count
    type: int
    restore_value: yes  # Persist across reboots
    initial_value: '0'
  
  - id: last_motion_time
    type: unsigned long
    restore_value: no
    initial_value: '0'

binary_sensor:
  - platform: gpio
    pin: GPIO14
    name: "Motion"
    on_press:
      - lambda: |-
          id(motion_count) += 1;
          id(last_motion_time) = millis();
          ESP_LOGI("motion", "Motion count: %d", id(motion_count));
```

### Custom Sensor Class
```yaml
esphome:
  includes:
    - custom_sensor.h

sensor:
  - platform: custom
    lambda: |-
      auto my_sensor = new MyCustomSensor();
      App.register_component(my_sensor);
      return {my_sensor->temp_sensor, my_sensor->humidity_sensor};
    sensors:
      - name: "Custom Temperature"
        unit_of_measurement: °C
        accuracy_decimals: 1
      - name: "Custom Humidity"
        unit_of_measurement: "%"
        accuracy_decimals: 0
```

### custom_sensor.h
```cpp
#include "esphome.h"

class MyCustomSensor : public Component, public Sensor {
 public:
  Sensor *temp_sensor = new Sensor();
  Sensor *humidity_sensor = new Sensor();
  
  void setup() override {
    // Initialize hardware
  }
  
  void loop() override {
    // Read sensor
    float temp = read_temperature();
    float hum = read_humidity();
    
    temp_sensor->publish_state(temp);
    humidity_sensor->publish_state(hum);
  }
  
 private:
  float read_temperature() {
    // Implementation
    return 22.5;
  }
  
  float read_humidity() {
    // Implementation
    return 45.0;
  }
};
```

---

## Framework Decision Guide

### Arduino Framework
**When to use**:
- ESP8266 devices
- Simple sensors and switches
- Maximum library compatibility
- Proven stability

**Limitations**:
- No advanced ESP32-S3 features
- Limited PSRAM support
- No native Bluetooth 5.0

```yaml
esp32:
  board: esp32dev
  framework:
    type: arduino
    version: recommended
```

### ESP-IDF Framework
**When to use**:
- ESP32-S3, ESP32-C3, ESP32-C6
- Voice assistants (required)
- Bluetooth proxy
- PSRAM required
- Advanced power management
- Better performance

**Note**: Some Arduino libraries incompatible

```yaml
esp32:
  board: esp32-s3-devkitc-1
  framework:
    type: esp-idf
    version: recommended
    sdkconfig_options:
      CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"
```

### Framework Comparison
| Feature | Arduino | ESP-IDF |
|---------|---------|---------|
| ESP8266 Support | ✅ Yes | ❌ No |
| ESP32 Original | ✅ Yes | ✅ Yes |
| ESP32-S3/C3 Full Support | ⚠️ Limited | ✅ Yes |
| Voice Assistant | ❌ No | ✅ Yes |
| Bluetooth Proxy | ⚠️ Basic | ✅ Full |
| PSRAM | ⚠️ Limited | ✅ Full |
| Library Support | ✅ Most | ⚠️ Some |
| Build Time | ✅ Fast | ⚠️ Slower |
| Performance | ⚠️ Good | ✅ Better |

---

## Web Server Component

**When to use**: Local web UI for debugging, standalone operation without Home Assistant

```yaml
web_server:
  port: 80
  version: 2  # Version 2 recommended
  include_internal: true  # Show diagnostic entities
  ota: true  # Enable OTA via web interface
  auth:
    username: admin
    password: !secret web_password
  
  # Custom CSS
  css_url: https://example.com/custom.css
  
  # Custom JS
  js_url: https://example.com/custom.js
```

### Web Server Security
```yaml
web_server:
  port: 80
  auth:
    username: !secret web_user
    password: !secret web_pass
  
  # Only expose on specific network
  local_address: 192.168.1.100

# Disable if not needed for security
# web_server:
#   enable: false
```

---

## Polish Language & Voice

**When to use**: Voice assistants for Polish users

### Home Assistant Configuration
Polish language support is configured in Home Assistant, not ESPHome:

1. **Home Assistant Settings** → **Voice assistants** → **Add assistant**
2. Select **Language**: `pl` (Polish)
3. **Speech-to-Text**: Use Whisper with Polish model
4. **Text-to-Speech**: Use Piper with Polish voice (`pl_mls_5992`)
5. **Wake word**: Train custom Polish wake word or use English "Okay Nabu"

### ESPHome Configuration (Language-agnostic)
```yaml
voice_assistant:
  microphone: mic
  speaker: spkr
  use_wake_word: true
  # Language is set in Home Assistant, not here
  
  # Audio quality matters more for Polish
  noise_suppression_level: 3  # Higher for accented speech
  auto_gain: 31dBFS
  volume_multiplier: 3.0  # Ensure clear TTS playback
```

### Polish-Specific Considerations
- **Wake word**: "Hej Asystent" or similar (train custom)
- **TTS voice**: Install `pl_mls_5992` in Home Assistant
- **Microphone quality**: Critical for accented speech recognition
- **Noise suppression**: Set higher (3-4) for better accuracy

---

## Security Best Practices

### 1. Secrets Management
```yaml
# Never commit secrets.yaml to git
# Add to .gitignore

# secrets.yaml
wifi_ssid: "MyNetwork"
wifi_password: "SecurePassword123!"
api_key: "base64encodedkey=="
ota_password: "OTAPassword456!"
```

### 2. API Encryption
```yaml
api:
  encryption:
    key: !secret api_key  # Always encrypt API
  reboot_timeout: 0s  # Don't auto-reboot on disconnect
```

### 3. OTA Security
```yaml
ota:
  - platform: esphome
    password: !secret ota_password  # Never use default
    safe_mode: true  # Allow recovery
```

### 4. Network Security
```yaml
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  
  # Use static IP for critical devices
  manual_ip:
    static_ip: 192.168.1.100
    gateway: 192.168.1.1
    subnet: 255.255.255.0
  
  # Disable AP if not needed
  # ap:
  #   disabled: true
```

### 5. Disable Unnecessary Services
```yaml
# Disable web server in production
# web_server:
#   port: 80

# Disable logger over serial if exposed
logger:
  baud_rate: 0  # Disable serial logging

# Disable Bluetooth if not used
# esp32_ble_tracker:
#   active: false
```

### 6. Firmware Validation
```yaml
ota:
  - platform: esphome
    safe_mode: true
    
  # Only accept signed firmware (advanced)
  # on_begin:
  #   - lambda: |-
  #       if (!validate_signature()) {
  #         ESP_LOGE("OTA", "Invalid signature!");
  #         return;
  #       }
```

### 7. Physical Security
```yaml
# Disable physical buttons in production
# binary_sensor:
#   - platform: gpio
#     pin: GPIO0
#     name: "Config Button"
#     disabled_by_default: true  # Hide from HA

# Factory reset protection
deep_sleep:
  wakeup_pin: GPIO39
  # Requires physical access to wake
```

---

## Cross-References

- **Automation Patterns**: `automation_patterns.md` - Trigger voice assistant from automations
- **Dashboard Design**: `dashboard_design.md` - Display ESPHome sensor data
- **HACS Curated**: `hacs_curated.md` - ESPHome Dashboard add-on

---

## Common Troubleshooting

### Voice Assistant Not Responding
1. Check ESP-IDF framework (required for voice)
2. Verify PSRAM enabled and working
3. Increase `noise_suppression_level`
4. Check microphone wiring (I2S pins)
5. Monitor logs: `esphome logs device.yaml`

### OTA Upload Failed
1. Check password in secrets.yaml
2. Verify device on network: `ping device.local`
3. Enable safe mode and try again
4. Use USB fallback: `esphome run device.yaml`

### Sensor Reading Incorrect
1. Check I2C address: `i2c: scan: true`
2. Verify pull-up resistors (3.3kΩ on SDA/SCL)
3. Add calibration offset: `filters: - offset: -0.5`
4. Check power supply (voltage drop)

### Device Keeps Rebooting
1. Check power supply (insufficient current)
2. Disable watchdog: `api: reboot_timeout: 0s`
3. Monitor logs for crash reason
4. Reduce WiFi power: `wifi: output_power: 10dB`

---

## Version Notes

**Last Updated**: 2025-01-18
**ESPHome Version**: 2024.12.x and later
**Home Assistant Version**: 2024.12.x and later

This reference reflects best practices as of early 2025. Always check the official ESPHome documentation for the latest features and changes.
