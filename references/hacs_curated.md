# Curated HACS List (2026)

**When to use this**: Reference guide for selecting and installing community integrations, frontend cards, themes, and AppDaemon apps through HACS (Home Assistant Community Store).

**Last Updated**: 2026-02-18 | **Compatible with**: Home Assistant 2024.12+ / HACS 2.0+

---

## Table of Contents
1. [HACS Installation & Setup](#hacs-installation--setup)
2. [Essential Integrations (Backend)](#essential-integrations-backend)
3. [Advanced Integrations](#advanced-integrations)
4. [Frontend Cards & Plugins](#frontend-cards--plugins)
5. [Themes](#themes)
6. [AppDaemon Apps](#appdaemon-apps)
7. [Polish Language Support](#polish-language-support)
8. [Troubleshooting & Common Issues](#troubleshooting--common-issues)
9. [Deprecated Integrations & Alternatives](#deprecated-integrations--alternatives)
10. [Version Compatibility Matrix](#version-compatibility-matrix)

---

## HACS Installation & Setup

### Initial Installation (2026 Method)

**Prerequisites**: 
- Home Assistant OS/Supervised/Container installation
- GitHub account
- Network access to GitHub

**Installation Steps**:
```bash
# Method 1: Using wget (Supervised/OS)
wget -O - https://get.hacs.xyz | bash -

# Method 2: Manual installation
cd /config
mkdir -p custom_components
cd custom_components
git clone https://github.com/hacs/integration.git hacs

# Restart Home Assistant
# Then add HACS through: Settings → Devices & Services → Add Integration
```

**Configuration**:
1. Navigate to Settings → Devices & Services
2. Click "+ Add Integration" and search for "HACS"
3. Follow GitHub authentication flow (device code method)
4. Select integration categories: Integration, Lovelace, Theme, AppDaemon, NetDaemon
5. Acknowledge experimental features warning

**Common Setup Issues**:
- **GitHub rate limiting**: Create personal access token with `public_repo` scope
- **Cloudflare blocking**: Use `hacs.bypass_cloudflare: true` in configuration
- **Download failures**: Check `/config/custom_components/hacs/` permissions

---

## Essential Integrations (Backend)

### 1. Adaptive Lighting
**Repository**: `basnijholt/adaptive-lighting`  
**Version**: 1.19.0+ | **HA Requirement**: 2024.1+

**Description**: Dynamically adjusts color temperature and brightness throughout the day to match circadian rhythms. Essential for comfort and sleep quality.

**Use Cases**:
- Automatic warm/cool light transitions
- Sleep-friendly evening lighting
- Coordinating multiple light groups
- Manual override detection

**Installation**:
1. HACS → Integrations → Explore & Download → "Adaptive Lighting"
2. Restart Home Assistant
3. Settings → Devices & Services → Add Integration → Adaptive Lighting

**Configuration Example**:
```yaml
# Configure via UI or configuration.yaml
adaptive_lighting:
  - name: "Living Room"
    lights:
      - light.living_room_main
      - light.living_room_accent
    prefer_rgb_color: false
    transition: 45
    initial_transition: 2
    interval: 90
    min_brightness: 1
    max_brightness: 100
    min_color_temp: 2000
    max_color_temp: 5500
    sleep_brightness: 1
    sleep_color_temp: 2000
    sunrise_time: "07:00:00"
    sunset_time: "22:00:00"
```

**Gotchas**:
- Disable if manually adjusting lights (use `adaptive_lighting.set_manual_control`)
- RGB lights: Set `prefer_rgb_color: true` for better color control
- Performance: Increase `interval` for large light groups (90-120 seconds)
- Sleep mode: Must be manually enabled, doesn't auto-trigger

**Automation Integration**:
```yaml
automation:
  - alias: "Enable Adaptive Lighting Sleep Mode"
    trigger:
      - platform: time
        at: "22:00:00"
    action:
      - service: adaptive_lighting.set_manual_control
        data:
          entity_id: switch.adaptive_lighting_living_room
          manual_control: false
      - service: switch.turn_on
        target:
          entity_id: switch.adaptive_lighting_sleep_mode_living_room
```

---

### 2. Alarmo - Security System
**Repository**: `nielsfaber/alarmo`  
**Version**: 1.10.0+ | **HA Requirement**: 2024.1+

**Description**: Full-featured alarm system with arming modes, sensors, users, and automations. No subscription required.

**Use Cases**:
- DIY home security system
- Multi-zone alarm areas
- User code management
- Integration with door/window/motion sensors

**Installation**:
1. HACS → Integrations → "Alarmo"
2. Restart HA
3. Settings → Devices & Services → Add "Alarmo"

**Configuration Example**:
```yaml
# Configured via UI at /alarmo
# Create sensors, users, and automations in Alarmo panel

# Example automation
automation:
  - alias: "Alarmo Armed Away"
    trigger:
      - platform: state
        entity_id: alarm_control_panel.alarmo
        to: "armed_away"
    action:
      - service: notify.mobile_app
        data:
          message: "Alarm armed - away mode"
      - service: light.turn_off
        target:
          entity_id: all
```

**Gotchas**:
- Requires separate Alarmo dashboard card for UI
- Exit/entry delays must be configured per sensor
- Use MQTT alarm panel for remote arming via keypads
- Backup codes via Settings → Alarmo → Users

---

### 3. Powercalc - Virtual Power Sensors
**Repository**: `bramstroker/homeassistant-powercalc`  
**Version**: 1.13.0+ | **HA Requirement**: 2024.1+

**Description**: Creates virtual power sensors for devices without power monitoring. Includes database of 3000+ device profiles.

**Use Cases**:
- Energy monitoring without smart plugs
- Track total home consumption
- Solar/grid power calculations
- Cost tracking per device

**Installation**:
1. HACS → Integrations → "Powercalc"
2. Restart HA
3. Settings → Integrations → Add "Powercalc"

**Configuration Example**:
```yaml
# Method 1: Auto-discovery (uses built-in profiles)
powercalc:
  sensors:
    - entity_id: light.living_room
      # Automatically finds power profile

# Method 2: Manual power definition
powercalc:
  sensors:
    - entity_id: light.bedroom
      fixed:
        power: 15  # Watts
    
    - entity_id: media_player.tv
      linear:
        min_power: 20
        max_power: 150
      calibrate:
        - brightness: 1
          power: 20
        - brightness: 255
          power: 150

# Method 3: Composite sensor (multiple devices)
powercalc:
  sensors:
    - create_group: Home Total Power
      entities:
        - entity_id: light.all_lights
        - entity_id: media_player.all_media
        - entity_id: switch.all_switches
```

**Gotchas**:
- Only works with entities that report state changes
- Fixed power mode for always-on devices (routers, NAS)
- Check library for device profiles before manual config
- Energy dashboard integration: Enable "Include in energy dashboard"

---

### 4. Spook - Your Homie
**Repository**: `frenck/spook`  
**Version**: 3.0.0+ | **HA Requirement**: 2024.6+

**Description**: NOT a standard integration - adds powerful debugging, repair, and utility services. "The scary debugger that haunts your Home Assistant."

**Use Cases**:
- Deleting orphaned entities
- Repairing broken automations
- Advanced entity manipulation
- Database cleanup
- Missing entity discovery

**Installation**:
1. HACS → Integrations → "Spook"
2. Restart HA (no configuration needed)

**Key Services**:
```yaml
# Delete entity and all history
service: spook.delete_entity
data:
  entity_id: sensor.old_sensor

# Repair script/automation
service: spook.repair_automation
data:
  entity_id: automation.broken_automation

# List all entity IDs with pattern
service: spook.list_entities
data:
  pattern: "sensor.temp_*"

# Disable multiple entities at once
service: spook.disable_entity
data:
  entity_id:
    - sensor.unused_1
    - sensor.unused_2
```

**Gotchas**:
- Permanent deletions - no undo available
- Disabled by default on production systems
- Breaking changes possible (experimental)
- Read documentation before bulk operations

---

### 5. Local Tuya / Tuya Local
**Repository**: `rospogrigio/localtuya` or `make-all/tuya-local`  
**Version**: 5.2.0+ | **HA Requirement**: 2024.1+

**Description**: Control Tuya/Smart Life devices locally without cloud dependency. Faster response, works offline.

**Use Cases**:
- Cloud-free Tuya device control
- Faster response times
- Offline operation
- Privacy-focused smart home

**Installation**:
1. Obtain device Local Key (use tuya-cli or iot.tuya.com)
2. HACS → Integrations → "LocalTuya" or "Tuya Local"
3. Settings → Integrations → Add "LocalTuya"

**Configuration Example**:
```yaml
# Configured via UI, but manual option:
localtuya:
  - host: 192.168.1.100
    device_id: bf4a8f6d9a1e2c3d4e5f
    local_key: a1b2c3d4e5f6g7h8
    protocol_version: "3.3"
    entities:
      - platform: light
        friendly_name: Living Room Light
        id: 1
        color_mode: 21
        brightness: 22
        color_temp: 23
```

**Gotchas**:
- Local key changes after re-pairing device in Tuya app
- Protocol version varies (3.1, 3.3, 3.4) - check compatibility
- Some devices require cloud integration for initial setup
- Static IP required for reliability (set DHCP reservation)

---

### 6. Frigate Integration
**Repository**: `blakeblackshear/frigate-hass-integration`  
**Version**: 5.0.0+ | **HA Requirement**: 2024.1+ | **Frigate**: 0.13.0+

**Description**: Integrates Frigate NVR (AI object detection) with Home Assistant. Requires separate Frigate server.

**Use Cases**:
- AI-powered security cameras
- Person/vehicle/animal detection
- Event notifications with snapshots
- License plate recognition
- Face detection

**Installation Prerequisites**:
```yaml
# Install Frigate first (docker-compose.yml)
version: "3.9"
services:
  frigate:
    container_name: frigate
    image: ghcr.io/blakeblackshear/frigate:stable
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - /path/to/config:/config
      - /path/to/storage:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
```

**Integration Setup**:
1. HACS → Integrations → "Frigate"
2. Settings → Integrations → Add "Frigate"
3. Enter Frigate server URL: `http://frigate-server:5000`

**Configuration Example**:
```yaml
# Frigate config.yml
mqtt:
  enabled: true
  host: mqtt-broker

cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://camera-ip:554/stream
          roles:
            - detect
            - record
    detect:
      width: 1280
      height: 720
    objects:
      track:
        - person
        - car
        - dog
    zones:
      driveway:
        coordinates: 0,461,3,0,1919,0,1919,843,1699,492,1344,458,1346,422

# HA Automation
automation:
  - alias: "Person Detected at Front Door"
    trigger:
      - platform: state
        entity_id: binary_sensor.front_door_person_occupancy
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          message: "Person detected at front door"
          data:
            image: "/api/frigate/notifications/{{trigger.event.data.id}}/snapshot.jpg"
```

**Gotchas**:
- GPU required for real-time detection (Coral TPU recommended)
- High storage requirements for recordings
- RTSP stream must be accessible from Frigate server
- MQTT required for real-time updates
- Review RAM requirements (2GB+ per camera)

---

### 7. Browser Mod
**Repository**: `thomasloven/hass-browser_mod`  
**Version**: 2.3.0+ | **HA Requirement**: 2024.1+

**Description**: Turns browsers into controllable entities. Enables popups, TTS, notifications, and navigation control.

**Use Cases**:
- Wall-mounted tablet control
- Browser-specific notifications
- Dynamic popup dashboards
- Per-browser TTS
- Screen wake/sleep

**Installation**:
1. HACS → Frontend → "Browser Mod"
2. Add to Lovelace resources (usually automatic)
3. Restart HA

**Configuration Example**:
```yaml
# Create browser entity automatically on page load
# No configuration needed

# Example automation
automation:
  - alias: "Show Security Alert Popup"
    trigger:
      - platform: state
        entity_id: binary_sensor.front_door
        to: "on"
    action:
      - service: browser_mod.popup
        data:
          title: "Front Door Opened"
          content:
            type: picture-entity
            entity: camera.front_door
          browser_id: tablet_living_room

  - alias: "TTS Announcement to Kitchen Tablet"
    action:
      - service: browser_mod.tts
        data:
          message: "Dinner is ready"
          browser_id: tablet_kitchen

  - alias: "Navigate to Camera View"
    action:
      - service: browser_mod.navigate
        data:
          path: /lovelace/security
          browser_id: tablet_bedroom
```

**Gotchas**:
- Browser must stay open to maintain entity
- `browser_id` auto-generated - check Developer Tools → Services
- Popups require card-mod for advanced styling
- TTS uses browser's speech synthesis (language varies)
- Use `browser_mod.debug` to identify browser IDs

---

### 8. HASS.Agent (Windows Integration)
**Repository**: `LAB02-Research/HASS.Agent-Integration`  
**Version**: 2024.4.0+ | **HA Requirement**: 2024.1+

**Description**: Integrate Windows PCs as entities with sensors, commands, and notifications.

**Use Cases**:
- PC power management
- System monitoring (CPU, RAM, GPU)
- Execute commands on PC
- Receive notifications on Windows
- App detection (is Spotify playing?)

**Installation**:
1. Install HASS.Agent client on Windows PC
2. HACS → Integrations → "HASS.Agent"
3. Settings → Integrations → Add "HASS.Agent"
4. Configure via HASS.Agent Windows app

**Configuration Example**:
```yaml
# Example sensors (configured in HASS.Agent Windows app)
# - CPU Usage
# - RAM Usage
# - Active Window
# - Current User

# HA Automation
automation:
  - alias: "Turn off PC at night"
    trigger:
      - platform: time
        at: "23:00:00"
    condition:
      - condition: state
        entity_id: binary_sensor.pc_active_window
        state: "off"
    action:
      - service: button.press
        target:
          entity_id: button.desktop_shutdown

  - alias: "Notify PC when doorbell rings"
    trigger:
      - platform: state
        entity_id: binary_sensor.doorbell
        to: "on"
    action:
      - service: notify.hass_agent_desktop
        data:
          message: "Someone at the door"
          title: "Doorbell"
```

**Gotchas**:
- Windows PC must be on for sensors to update
- Requires .NET 6.0+ Runtime
- Firewall rules may block connection
- Use Quick Actions for frequently used commands

---

### 9. Adaptive Cover
**Repository**: `basbruss/adaptive-cover`  
**Version**: 0.6.0+ | **HA Requirement**: 2024.1+

**Description**: Automatically controls blinds/shades based on sun position, temperature, and weather.

**Use Cases**:
- Solar heat gain management
- Glare prevention
- Privacy automation
- Energy savings

**Installation**:
1. HACS → Integrations → "Adaptive Cover"
2. Settings → Integrations → Add "Adaptive Cover"

**Configuration Example**:
```yaml
adaptive_cover:
  - name: "Living Room Blinds"
    entities:
      - cover.living_room_blind_left
      - cover.living_room_blind_right
    sunset_position: 100  # Fully open
    sunset_offset: -30  # 30 min before sunset
    sunrise_position: 0  # Fully closed
    sunrise_offset: 30
    tilt_mode: true
    temperature_sensor: sensor.living_room_temperature
    weather_entity: weather.home
    min_temperature: 20
    max_temperature: 26
```

**Gotchas**:
- Requires weather integration for cloud detection
- Window azimuth must be configured correctly
- Manual override detection available
- Climate control integration recommended

---

### 10. Waste Collection Schedule
**Repository**: `mampfes/hacs_waste_collection_schedule`  
**Version**: 2.0.0+ | **HA Requirement**: 2024.1+

**Description**: Track garbage, recycling, and waste collection schedules. Supports 400+ service providers worldwide including Polish municipalities.

**Use Cases**:
- Trash collection reminders
- Multiple bin types tracking
- Calendar integration
- Notification automations

**Installation**:
1. HACS → Integrations → "Waste Collection Schedule"
2. Settings → Integrations → Add "Waste Collection Schedule"

**Configuration Example**:
```yaml
# configuration.yaml
waste_collection_schedule:
  sources:
    - name: waste_collection_schedule.source.ics
      args:
        url: https://your-municipality.pl/waste-calendar.ics
        split_at: ", "
      calendar_title: "Waste Collection"
    
    # Polish example: Warsaw
    - name: waste_collection_schedule.source.um_warszawa_pl
      args:
        city: "Warszawa"
        street: "Marszałkowska"
        house_number: "1"

# Automation
automation:
  - alias: "Waste Collection Reminder"
    trigger:
      - platform: time
        at: "19:00:00"
    condition:
      - condition: template
        value_template: >
          {{ state_attr('sensor.waste_collection', 'daysTo') == 0 }}
    action:
      - service: notify.mobile_app
        data:
          message: "Ustaw pojemniki - jutro wywóz: {{ states('sensor.waste_collection') }}"
```

**Gotchas**:
- Check source list for your municipality
- ICS calendar URL may require authentication
- Update frequency: once per day (midnight)
- Multiple sources possible for different waste types

---

### 11. Variable Integration
**Repository**: `snarky-snark/home-assistant-variables`  
**Version**: 3.5.0+ | **HA Requirement**: 2024.1+

**Description**: Create persistent variables for complex automations. Unlike input_text, these can store templates and complex data.

**Use Cases**:
- Counters and accumulators
- State machines
- Temporary data storage
- Cross-automation data sharing

**Installation**:
1. HACS → Integrations → "Variable"
2. Restart HA

**Configuration Example**:
```yaml
variable:
  last_motion:
    value: 'None'
    restore: false
  
  alarm_triggered_count:
    value: 0
    restore: true  # Persist across restarts
    attributes:
      icon: mdi:counter
      friendly_name: "Alarm Trigger Count"
  
  cleaning_schedule:
    value:
      - room: "Kitchen"
        last_cleaned: "2026-02-15"
      - room: "Bathroom"
        last_cleaned: "2026-02-17"

# Usage in automation
automation:
  - alias: "Track Last Motion"
    trigger:
      - platform: state
        entity_id: binary_sensor.motion_hall
        to: "on"
    action:
      - service: variable.set_variable
        data:
          variable: last_motion
          value: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"
      
      - service: variable.set_variable
        data:
          variable: alarm_triggered_count
          value: "{{ states('variable.alarm_triggered_count') | int + 1 }}"
```

**Gotchas**:
- Not designed for high-frequency updates
- Use `restore: false` for non-critical data (performance)
- Alternative: Use `input_text` with templates for simple cases

---

### 12. ics Calendar
**Repository**: `franc6/ics_calendar`  
**Version**: 4.2.0+ | **HA Requirement**: 2024.1+

**Description**: Import ICS calendar feeds (webcal://, https://) as HA calendar entities. Perfect for holidays, school schedules, and work calendars.

**Use Cases**:
- National holidays (Polish and others)
- Garbage collection schedules
- School/university calendars
- Work shift schedules

**Installation**:
1. HACS → Integrations → "iCalendar"
2. Restart HA
3. Configuration.yaml setup required

**Configuration Example**:
```yaml
# configuration.yaml
calendar:
  - platform: ics_calendar
    calendars:
      - name: "Polish Holidays"
        url: "https://calendar.google.com/calendar/ical/pl.polish%23holiday%40group.v.calendar.google.com/public/basic.ics"
        days: 365
      
      - name: "Work Schedule"
        url: "webcal://company.com/calendars/my-schedule.ics"
        days: 90
        include_all_day: true
      
      - name: "Kids School"
        url: "https://school.edu.pl/calendar/feed.ics"
        exclude: "Canceled|Optional"

# Automation example
automation:
  - alias: "Holiday Lighting"
    trigger:
      - platform: calendar
        entity_id: calendar.polish_holidays
        event: start
    action:
      - service: scene.turn_on
        target:
          entity_id: scene.holiday_lights
```

**Gotchas**:
- Refresh interval: 15 minutes (not configurable)
- Large calendars (1000+ events) slow down startup
- Use `days` parameter to limit range
- `exclude` supports regex patterns

---

### 13. Authenticated Integration
**Repository**: `custom-components/authenticated`  
**Version**: 2.5.0+ | **HA Requirement**: 2024.1+

**Description**: Tracks authentication events - successful logins, failed attempts, and 2FA usage. Security monitoring essential.

**Use Cases**:
- Login audit trail
- Failed login alerts
- Unauthorized access detection
- User activity monitoring

**Installation**:
1. HACS → Integrations → "Authenticated"
2. Restart HA
3. Auto-discovers authentication sensors

**Configuration Example**:
```yaml
# No configuration needed - auto-creates:
# - sensor.authenticated_last_success
# - sensor.authenticated_last_fail
# - sensor.authenticated_total_success
# - sensor.authenticated_total_fail

# Security automation
automation:
  - alias: "Failed Login Alert"
    trigger:
      - platform: state
        entity_id: sensor.authenticated_total_fail
    condition:
      - condition: template
        value_template: >
          {{ states('sensor.authenticated_total_fail') | int > 
             states('input_number.fail_threshold') | int }}
    action:
      - service: notify.admin
        data:
          message: >
            Failed login attempts: {{ states('sensor.authenticated_total_fail') }}
            Last attempt: {{ state_attr('sensor.authenticated_last_fail', 'username') }}
            IP: {{ state_attr('sensor.authenticated_last_fail', 'ip_address') }}
      
      - service: persistent_notification.create
        data:
          title: "Security Alert"
          message: "Multiple failed login attempts detected"
```

**Gotchas**:
- High database growth with many users
- Use recorder exclusions for history management
- Failed attempts include typos from legitimate users
- IP addresses may be internal (reverse proxy)

---

### 14. Circadian Lighting (Alternative to Adaptive Lighting)
**Repository**: `claytonjn/hass-circadian_lighting`  
**Version**: 2.0.0+ | **HA Requirement**: 2024.1+

**Description**: Original circadian lighting implementation. Less feature-rich than Adaptive Lighting but more stable for some users.

**When to use**: If Adaptive Lighting causes issues or you prefer simpler configuration.

**Configuration Example**:
```yaml
circadian_lighting:
  - name: "Main"
    min_colortemp: 2500
    max_colortemp: 5500
    transition: 60

light:
  - platform: circadian_lighting
    name: "Living Room Circadian"
    lights_ct:
      - light.living_room
```

---

### 15. MQTT Explorer Integration
**Repository**: `alexbelgium/hassio-addons`  
**Version**: Addon-based | **HA Requirement**: 2024.1+

**Description**: Web-based MQTT browser for debugging. Essential for troubleshooting Zigbee, Z-Wave, and custom MQTT devices.

**Use Cases**:
- MQTT message debugging
- Topic exploration
- Publish manual commands
- Integration testing

---

## Advanced Integrations

### 16. Node-RED Companion
**Repository**: `zachowj/hass-node-red`  
**Version**: 3.2.0+ | **HA Requirement**: 2024.1+

**Description**: Enhanced integration between Node-RED and HA. If you use Node-RED for complex automations, this is essential.

**Use Cases**:
- Visual automation programming
- Complex conditional logic
- API integration
- Data transformation

**Installation**:
1. Install Node-RED addon first
2. HACS → Integrations → "Node-RED Companion"
3. Configure webhook and entities

**Gotchas**:
- Requires Node-RED addon or external Node-RED instance
- Learning curve for Node-RED
- Backup flows separately from HA

---

### 17. Prometheus Exporter
**Repository**: `knyar/prometheus_exporter`  
**Version**: 2.4.0+ | **HA Requirement**: 2024.1+

**Description**: Export HA metrics to Prometheus for advanced monitoring and alerting.

**Use Cases**:
- Long-term metric storage
- Grafana dashboards
- Advanced alerting
- Multi-system monitoring

---

### 18. HACS Discovery
**Repository**: `custom-components/discovery`  
**Version**: 1.8.0+ | **HA Requirement**: 2024.1+

**Description**: Automatically discovers custom components and suggests HACS installations.

---

### 19. History Explorer Card
**Repository**: `alexarch21/history-explorer-card`  
**Version**: 1.4.0+ | **HA Requirement**: 2024.1+

**Description**: Advanced history viewing with zooming, panning, and multiple entity comparison.

---

### 20. Scheduler Component
**Repository**: `nielsfaber/scheduler-component`  
**Version**: 4.4.0+ | **HA Requirement**: 2024.1+

**Description**: UI-based scheduler for creating time-based automations without YAML.

**Use Cases**:
- User-friendly scheduling
- Non-technical user automation
- Thermostat schedules
- Light timers

---

### 21. Sun2
**Repository**: `pnbruckner/ha-sun2`  
**Version**: 3.1.0+ | **HA Requirement**: 2024.1+

**Description**: Enhanced sun integration with additional solar calculations (dawn, dusk, golden hour, blue hour).

**Use Cases**:
- Photography automation
- Precise lighting schedules
- Solar panel optimization

---

### 22. Places
**Repository**: `custom-components/places`  
**Version**: 2.6.0+ | **HA Requirement**: 2024.1+

**Description**: Reverse geocoding for device_tracker entities. Shows actual location names instead of coordinates.

**Use Cases**:
- Human-readable locations
- Arrival notifications ("John arrived at Grocery Store")
- Location-based automations

---

### 23. Lovelace Gen
**Repository**: `thomasloven/hass-lovelace_gen`  
**Version**: 1.1.0+ | **HA Requirement**: 2024.1+

**Description**: Jinja2 templates in Lovelace YAML. Create reusable card templates and loops.

**Use Cases**:
- DRY dashboard code
- Dynamic card generation
- Consistent styling

---

### 24. Auto Backup
**Repository**: `jcwillox/hass-auto-backup`  
**Version**: 1.5.0+ | **HA Requirement**: 2024.1+

**Description**: Automated backup scheduling with retention policies. Critical for disaster recovery.

**Use Cases**:
- Daily/weekly backups
- Cloud storage upload
- Backup before updates

---

### 25. Remote Home-Assistant
**Repository**: `custom-components/remote_homeassistant`  
**Version**: 4.0.0+ | **HA Requirement**: 2024.1+

**Description**: Connect multiple HA instances. Share entities between primary and remote installations.

**Use Cases**:
- Multi-location setups
- Vacation home integration
- Parent's home monitoring

---

### 26. Average Sensor
**Repository**: `Limych/ha-average`  
**Version**: 2.3.0+ | **HA Requirement**: 2024.1+

**Description**: Calculate average, min, max of multiple sensors.

**Configuration Example**:
```yaml
sensor:
  - platform: average
    name: "Average Temperature"
    entities:
      - sensor.bedroom_temperature
      - sensor.living_room_temperature
      - sensor.kitchen_temperature
    precision: 1
```

---

### 27. RESTful Switch
**Repository**: `custom-components/switch.rest`  
**Version**: 2.1.0+ | **HA Requirement**: 2024.1+

**Description**: Control devices via REST API as switches.

---

### 28. Passive BLE Monitor
**Repository**: `custom-components/ble_monitor`  
**Version**: 12.7.0+ | **HA Requirement**: 2024.1+

**Description**: Monitor Bluetooth Low Energy devices without active connection. Supports Xiaomi sensors.

**Gotchas**:
- Requires Bluetooth adapter with long-range support
- May interfere with ESPHome Bluetooth proxy

---

### 29. HACS Frontend Themes Repository
**Repository**: Multiple theme repositories  
**Version**: Various

**Description**: Centralized theme installations.

---

### 30. Presence Simulation
**Repository**: `slashback/presence_simulation`  
**Version**: 4.8.0+ | **HA Requirement**: 2024.1+

**Description**: Replay historical actions to simulate presence when away.

**Use Cases**:
- Vacation security
- Light patterns
- Device activity

---

## Frontend Cards & Plugins

### 1. Mushroom Cards ⭐
**Repository**: `piitaya/lovelace-mushroom`  
**Version**: 3.6.0+ | **HA Requirement**: 2024.1+

**Description**: Modern, minimalist card collection. The de facto standard for 2026 dashboards.

**Cards Included**:
- Entity card
- Light card
- Person card
- Template card
- Title card
- Chips card

**Installation**:
1. HACS → Frontend → "Mushroom"
2. Clear browser cache
3. Restart browser

**Example**:
```yaml
type: custom:mushroom-light-card
entity: light.living_room
show_brightness_control: true
show_color_control: true
use_light_color: true
layout: horizontal
```

**Gotchas**:
- Requires card-mod for advanced styling
- Template card syntax differs from standard templates
- Icons: Use `mdi:` prefix

---

### 2. Bubble Card
**Repository**: `Clooos/Bubble-Card`  
**Version**: 2.2.0+ | **HA Requirement**: 2024.1+

**Description**: Mobile-first card design with popups, sub-buttons, and modern UX.

**Card Types**:
- Pop-up card
- Button card
- Separator card
- Horizontal buttons stack
- Cover card

**Example**:
```yaml
type: custom:bubble-card
card_type: button
entity: light.living_room
name: "Living Room"
icon: mdi:sofa
show_state: true
sub_button:
  - entity: light.living_room_accent
    show_background: false
```

---

### 3. Mini Media Player
**Repository**: `kalkih/mini-media-player`  
**Version**: 1.16.0+ | **HA Requirement**: 2024.1+

**Description**: Compact media player with album art, shortcuts, and sound modes.

**Example**:
```yaml
type: custom:mini-media-player
entity: media_player.spotify
artwork: cover
hide:
  power: false
  source: false
  volume: false
shortcuts:
  columns: 4
  buttons:
    - name: "Morning Playlist"
      type: playlist
      id: spotify:playlist:abc123
    - name: "Relax"
      type: playlist
      id: spotify:playlist:def456
```

---

### 4. Auto-Entities Card
**Repository**: `thomasloven/lovelace-auto-entities`  
**Version**: 1.13.0+ | **HA Requirement**: 2024.1+

**Description**: Automatically populate cards based on entity filters. Essential for large installations.

**Example**:
```yaml
type: custom:auto-entities
card:
  type: entities
  title: Low Batteries
filter:
  include:
    - entity_id: "*_battery"
      state: "< 20"
  exclude:
    - state: "unavailable"
sort:
  method: state
  numeric: true
```

---

### 5. Card Mod
**Repository**: `thomasloven/lovelace-card-mod`  
**Version**: 3.4.0+ | **HA Requirement**: 2024.1+

**Description**: CSS styling for any card. Required for advanced customization.

**Example**:
```yaml
type: entities
entities:
  - light.living_room
card_mod:
  style: |
    ha-card {
      background: rgba(0, 0, 0, 0.5);
      border-radius: 20px;
      box-shadow: 0 4px 8px rgba(0,0,0,0.3);
    }
```

---

### 6. Plotly Graph Card
**Repository**: `dbuezas/lovelace-plotly-graph-card`  
**Version**: 2.7.0+ | **HA Requirement**: 2024.1+

**Description**: Interactive graphs with zooming, panning, and multiple Y-axes.

**Example**:
```yaml
type: custom:plotly-graph
entities:
  - entity: sensor.temperature_outside
    name: Outside
  - entity: sensor.temperature_inside
    name: Inside
    yaxis: y2
hours_to_show: 24
refresh_interval: 60
```

---

### 7. ApexCharts Card
**Repository**: `RomRider/apexcharts-card`  
**Version**: 2.11.0+ | **HA Requirement**: 2024.1+

**Description**: Advanced charting with statistical functions.

**Example**:
```yaml
type: custom:apexcharts-card
graph_span: 7d
series:
  - entity: sensor.power_consumption
    type: column
    func: max
    group_by:
      duration: 1h
```

---

### 8. Button Card
**Repository**: `custom-cards/button-card`  
**Version**: 4.1.0+ | **HA Requirement**: 2024.1+

**Description**: Highly customizable button with templates and styles.

**Example**:
```yaml
type: custom:button-card
entity: light.living_room
name: Living Room
icon: mdi:sofa
show_state: true
state:
  - value: "on"
    color: rgb(255, 200, 0)
    icon: mdi:lightbulb-on
  - value: "off"
    color: rgb(80, 80, 80)
```

---

### 9. Swipe Card
**Repository**: `bramkragten/swipe-card`  
**Version**: 5.0.0+ | **HA Requirement**: 2024.1+

**Description**: Swipeable card carousel for mobile dashboards.

---

### 10. Slider Entity Row
**Repository**: `thomasloven/lovelace-slider-entity-row`  
**Version**: 17.3.0+ | **HA Requirement**: 2024.1+

**Description**: Inline sliders in entities card.

---

### 11. Fold Entity Row
**Repository**: `thomasloven/lovelace-fold-entity-row`  
**Version**: 2.2.0+ | **HA Requirement**: 2024.1+

**Description**: Collapsible entity groups.

---

### 12. Multiple Entity Row
**Repository**: `benct/lovelace-multiple-entity-row`  
**Version**: 4.5.0+ | **HA Requirement**: 2024.1+

**Description**: Display multiple entities in one row.

---

### 13. Bar Card
**Repository**: `custom-cards/bar-card`  
**Version**: 3.2.0+ | **HA Requirement**: 2024.1+

**Description**: Visual bars for battery, storage, progress.

---

### 14. Vacuum Card
**Repository**: `denysdovhan/vacuum-card`  
**Version**: 2.8.0+ | **HA Requirement**: 2024.1+

**Description**: Beautiful vacuum cleaner controls.

---

### 15. Weather Card
**Repository**: `bramkragten/weather-card`  
**Version**: 1.6.0+ | **HA Requirement**: 2024.1+

**Description**: Animated weather card with forecast.

---

### 16. Vertical Stack In Card
**Repository**: `ofekashery/vertical-stack-in-card`  
**Version**: 0.4.0+ | **HA Requirement**: 2024.1+

**Description**: Stack cards in single card container.

---

### 17. Layout Card
**Repository**: `thomasloven/lovelace-layout-card`  
**Version**: 2.4.0+ | **HA Requirement**: 2024.1+

**Description**: Grid and masonry layouts.

---

### 18. State Switch
**Repository**: `thomasloven/lovelace-state-switch`  
**Version**: 1.9.0+ | **HA Requirement**: 2024.1+

**Description**: Display different cards based on state.

---

### 19. Compass Card
**Repository**: `tomvanswam/compass-card`  
**Version**: 2.0.0+ | **HA Requirement**: 2024.1+

**Description**: Wind direction and tracking display.

---

### 20. Sankey Chart Card
**Repository**: `MindFreeze/ha-sankey-chart`  
**Version**: 1.11.0+ | **HA Requirement**: 2024.1+

**Description**: Energy flow visualization.

---

### 21. Search Card
**Repository**: `postlund/search-card`  
**Version**: 1.3.0+ | **HA Requirement**: 2024.1+

**Description**: Search entities in dashboard.

---

### 22. Config Template Card
**Repository**: `iantrich/config-template-card`  
**Version**: 1.3.0+ | **HA Requirement**: 2024.1+

**Description**: Jinja templates in card config.

---

## Themes

### 1. iOS Themes (Light & Dark)
**Repository**: `basnijholt/lovelace-ios-themes`  
**Version**: 2.0.0+ | **HA Requirement**: 2024.1+

**Description**: iOS-style theme with light and dark modes.

**Installation**:
1. HACS → Frontend → "iOS Themes"
2. Add to configuration.yaml:
```yaml
frontend:
  themes: !include_dir_merge_named themes
```
3. Select in profile: iOS Dark Blue / iOS Light

---

### 2. Mushroom Themes
**Repository**: `piitaya/lovelace-mushroom-themes`  
**Version**: 3.2.0+ | **HA Requirement**: 2024.1+

**Description**: Complements Mushroom cards perfectly.

---

### 3. Noctis
**Repository**: `aFFekopp/noctis`  
**Version**: 2.1.0+ | **HA Requirement**: 2024.1+

**Description**: Dark theme with blue accents.

---

### 4. Clear Theme
**Repository**: `naofireblade/clear-theme`  
**Version**: 2.5.0+ | **HA Requirement**: 2024.1+

**Description**: Minimalist light theme.

---

### 5. Slate Theme
**Repository**: `seangreen2/slate_theme`  
**Version**: 8.4.0+ | **HA Requirement**: 2024.1+

**Description**: Material Design dark theme.

---

## AppDaemon Apps

### 1. Schedy - Advanced Scheduling
**Repository**: `efficiosoft/hass-apps`  
**Version**: 0.48.0+ | **HA Requirement**: 2024.1+

**Description**: Python-based scheduling system for thermostats and more.

**Use Cases**:
- Complex heating schedules
- Multi-room climate control
- Holiday/vacation modes

---

### 2. Presence Simulation App
**Repository**: Various AppDaemon apps repos  
**Version**: Varies

**Description**: More advanced than integration version.

---

### 3. Alexa Media Scripts
**Repository**: `alandtse/alexa_media_player`  
**Version**: 4.11.0+ | **HA Requirement**: 2024.1+

**Description**: Enhanced Alexa control scripts.

---

## Polish Language Support

### TTS - Polski
**Integration**: Google Translate TTS with `language: pl`

**Configuration**:
```yaml
tts:
  - platform: google_translate
    language: 'pl'
    base_url: http://homeassistant.local:8123
```

**Usage**:
```yaml
service: tts.google_translate_say
data:
  entity_id: media_player.salon
  message: "Witaj w domu! Temperatura to {{ states('sensor.temperature') }} stopni."
  language: 'pl'
```

---

### HACS UI - Polish Translation
**Note**: HACS includes Polish translations by default in 2026. Enable in HA profile settings.

---

### Garbage Collection - Polish Providers
See Waste Collection Schedule integration (#10) - supports major Polish municipalities.

---

## Troubleshooting & Common Issues

### HACS Not Appearing After Installation

**Symptoms**: HACS not visible in Integrations after installation.

**Solutions**:
1. Check `/config/custom_components/hacs/` exists
2. Verify permissions: `chmod -R 755 /config/custom_components/hacs`
3. Check logs: Settings → System → Logs (filter: `hacs`)
4. Clear browser cache: Ctrl+Shift+Delete
5. Force refresh: Ctrl+F5

---

### GitHub Rate Limiting

**Symptoms**: "Rate limit exceeded" errors.

**Solutions**:
1. Create GitHub Personal Access Token (PAT)
2. Settings → Integrations → HACS → Configure
3. Add token with `public_repo` scope
4. Increases limit from 60 to 5,000 requests/hour

---

### Integration Won't Load

**Symptoms**: Integration shows "Failed to load" or "Setup failed".

**Solutions**:
1. Check HA version compatibility
2. Update to latest integration version
3. Check dependencies (some require MQTT, etc.)
4. Review logs for specific errors
5. Try removing and re-adding integration

---

### Custom Card Not Showing

**Symptoms**: Card shows "Custom element doesn't exist: custom:card-name"

**Solutions**:
1. Clear browser cache completely
2. Check Resources: Settings → Dashboards → Resources
3. Ensure URL is `/hacsfiles/card-name/card.js`
4. Hard refresh: Ctrl+Shift+R
5. Check browser console (F12) for errors
6. Verify card is downloaded: `/config/www/community/card-name/`

---

### HACS Repository Not Found

**Symptoms**: Can't find integration in HACS.

**Solutions**:
1. Enable experimental repositories: HACS → Configuration
2. Add custom repository: HACS → ⋮ → Custom repositories
3. Check if repository moved or renamed
4. Verify repository still exists on GitHub

---

### Download Failures

**Symptoms**: "Could not download" errors.

**Solutions**:
1. Check internet connectivity
2. Verify GitHub isn't blocked by firewall
3. Check DNS resolution: `nslookup github.com`
4. Try again later (GitHub issues)
5. Manual installation as fallback

---

### Component Loaded Twice

**Symptoms**: Warning about "Platform X already configured".

**Solutions**:
1. Check for duplicate entries in configuration.yaml
2. Remove manual configuration if integration has UI setup
3. Search for `!include` directives that may duplicate config

---

## Deprecated Integrations & Alternatives

### 1. ~~Lovelace UI Minimalist~~ → Mushroom Cards
**Reason**: No longer maintained as of 2024.  
**Alternative**: Mushroom Cards + Card Mod provide same functionality with active development.

---

### 2. ~~Custom Updater~~ → HACS Built-in
**Reason**: Deprecated in favor of HACS.  
**Alternative**: HACS handles all custom component updates now.

---

### 3. ~~Tracker Card~~ → Built-in Map Card
**Reason**: Functionality integrated into core HA.  
**Alternative**: Use `type: map` card with device trackers.

---

### 4. ~~Calendar Card~~ → Built-in Calendar Card
**Reason**: Core HA now has excellent calendar support.  
**Alternative**: Native calendar card (2024.2+).

---

### 5. ~~Simple Thermostat~~ → Better Thermostat
**Repository**: `KartoffelToby/better_thermostat`  
**Reason**: Simple Thermostat abandoned.  
**Alternative**: Better Thermostat with TRV calibration and window detection.

---

### 6. ~~Hassio Google Drive Backup~~ → Built-in Cloud Backup
**Reason**: Integrated into HA Cloud.  
**Alternative**: Use Home Assistant Cloud backup or Auto Backup integration (#24).

---

### 7. ~~Alexa Media Player (HACS)~~ → Built-in Alexa Integration
**Reason**: Improved core integration in 2025.  
**Alternative**: Native Alexa integration (still use HACS for advanced features).

---

### 8. ~~Garbage Collection (old)~~ → Waste Collection Schedule
**Reason**: Original integration deprecated.  
**Alternative**: Waste Collection Schedule (#10) - much more feature-rich.

---

## Version Compatibility Matrix

| Integration | Min HA Version | HACS Version | Python | Notes |
|-------------|----------------|--------------|--------|-------|
| Adaptive Lighting | 2024.1.0 | 1.34.0+ | 3.11+ | Breaking changes in 1.19.0 |
| Alarmo | 2024.1.0 | Any | 3.11+ | UI requires 2024.2+ |
| Powercalc | 2024.1.0 | Any | 3.11+ | Library updated monthly |
| Spook | 2024.6.0 | Any | 3.12+ | Requires newer HA |
| Browser Mod | 2024.1.0 | Any | 3.11+ | v2.x breaking changes |
| Frigate | 2024.1.0 | Any | 3.11+ | Frigate 0.13+ required |
| Mushroom Cards | 2024.1.0 | Any | N/A | Frontend only |
| Bubble Card | 2024.1.0 | Any | N/A | Frontend only |

---

## Cross-References

**Related Documentation**:
- [Automation Patterns](automation_patterns.md) - Use with Browser Mod, Variable
- [Dashboard Design](dashboard_design.md) - Mushroom, Bubble Card examples
- [ESPHome Templates](esphome_templates.md) - Complement Frigate with ESP32-CAM

**External Links**:
- [HACS Official Documentation](https://hacs.xyz/)
- [HACS GitHub](https://github.com/hacs/integration)
- [Community Forum - HACS Category](https://community.home-assistant.io/c/hacs)

---

**Version History**:
- 2026-02-18: Expanded to 600+ lines with Polish support
- 2025-12-15: Added Spook, Browser Mod, Better Thermostat
- 2025-10-01: Marked deprecated integrations
- 2025-08-12: Initial curated list
