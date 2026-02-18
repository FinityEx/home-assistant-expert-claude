# Home Assistant Comprehensive Troubleshooting Guide
**Updated: 2026-02-18**

This guide provides systematic troubleshooting for Home Assistant issues, focusing on symptoms, root causes, and proven fixes.

---

## Table of Contents
1. [Log Analysis Patterns](#log-analysis-patterns)
2. [Common Error Messages & Solutions](#common-error-messages--solutions)
3. [Integration-Specific Troubleshooting](#integration-specific-troubleshooting)
4. [Network Debugging](#network-debugging)
5. [Database Corruption Recovery](#database-corruption-recovery)
6. [Supervisor/OS Troubleshooting](#supervisoros-troubleshooting)
7. [Add-on Crash Debugging](#add-on-crash-debugging)
8. [Entity Unavailable Systematic Diagnosis](#entity-unavailable-systematic-diagnosis)
9. [Performance Degradation Diagnosis](#performance-degradation-diagnosis)
10. [Memory/CPU Issue Identification](#memorycpu-issue-identification)

---

## Log Analysis Patterns

### Accessing Logs on HA OS
```bash
# SSH into Home Assistant OS
ssh root@homeassistant.local

# View real-time logs
ha core logs -f

# View supervisor logs
ha supervisor logs -f

# View specific add-on logs (example: Mosquitto broker)
ha addons logs addon_core_mosquitto -f

# Download full log
ha core logs > /root/home-assistant.log
```

### Key Log Patterns to Look For

#### Critical Startup Issues
```
ERROR (MainThread) [homeassistant.setup] Setup failed for <integration>: Unable to import component
```
**Meaning**: Integration failed to load, usually missing dependency or corrupted installation.

#### Authentication Failures
```
WARNING (MainThread) [homeassistant.components.http.ban] Login attempt or request with invalid authentication from <IP>
```
**Meaning**: Failed login attempts - check for brute force attacks.

#### Network Connectivity
```
ERROR (MainThread) [homeassistant.helpers.entity] Update for <entity> fails
TimeoutError: [Errno 110] Connection timed out
```
**Meaning**: Device unreachable on network.

#### Database Issues
```
ERROR (Recorder) [homeassistant.components.recorder.util] Error executing query: database is locked
```
**Meaning**: Database corruption or I/O performance issues.

#### Memory Pressure
```
WARNING (MainThread) [homeassistant.helpers] High memory usage detected (95%)
```
**Meaning**: System running out of RAM.

---

## Common Error Messages & Solutions

### 1. Platform Not Found

**Symptoms:**
```
ERROR (MainThread) [homeassistant.setup] Unable to prepare setup for platform sensor.template: Platform not found (no component sensor).
```

**Cause:** Typo in configuration or deprecated syntax.

**Fix:**
```yaml
# Wrong:
sensor:
  - platform: template
    
# Correct (2026 syntax):
template:
  - sensor:
      - name: "My Sensor"
        state: "{{ states('sensor.other') }}"
```

**Prevention:** Use YAML validation before restart.

---

### 2. Invalid Config

**Symptoms:**
```
Invalid config for [automation]: required key not provided @ data['action']
```

**Cause:** Missing required field in configuration.

**Fix:**
```bash
# Check configuration before restart
ha core check

# View detailed errors
ha core logs | grep -A 5 "Invalid config"
```

**Related Issues:** Often occurs with `trigger`, `condition`, or `action` fields.

---

### 3. Template Rendering Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.helpers.template] Template variable error: 'None' has no attribute 'state'
```

**Cause:** Entity doesn't exist or hasn't loaded yet.

**Fix:**
```yaml
# Bad:
state: "{{ states.sensor.temperatura_salon.state }}"

# Good (with default):
state: "{{ states('sensor.temperatura_salon') | float(0) }}"
```

**Prevention:** Always use default values and `states()` function.

---

### 4. Unknown User Referenced

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.automation] Error while executing automation: unknown user
```

**Cause:** User referenced in automation no longer exists.

**Fix:**
```bash
# List all users
ha auth list

# Update automation to use existing user ID or remove user-specific trigger
```

---

### 5. Device Not Found

**Symptoms:**
```
WARNING (MainThread) [homeassistant.helpers.entity_platform] device_id abc123 not found
```

**Cause:** Device registry entry exists but device was removed.

**Fix:**
```bash
# Via Developer Tools → Services:
# service: homeassistant.reload_config_entry
# data:
#   entry_id: <config_entry_id>

# Or delete orphaned device via UI: Settings → Devices & Services → Devices
```

---

### 6. Blocking Call in Event Loop

**Symptoms:**
```
WARNING (MainThread) [homeassistant.util.async] Detected blocking call inside the event loop
```

**Cause:** Synchronous I/O operation in async context.

**Fix:**
- Update integration to latest version
- Report to integration developer if custom component

**Prevention:** Always use async methods in integrations.

---

### 7. Recorder Backlog

**Symptoms:**
```
WARNING (Recorder) [homeassistant.components.recorder] Ended unfinished session (id=123)
WARNING (Recorder) [homeassistant.components.recorder.util] The recorder backlog queue reached the maximum size of 30000
```

**Cause:** Database write speed can't keep up with event rate.

**Fix:**
```yaml
# configuration.yaml
recorder:
  purge_keep_days: 7
  commit_interval: 5
  exclude:
    domains:
      - media_player
      - automation
    entity_globs:
      - sensor.temperatura_*_history
```

**Prevention:** Exclude high-frequency entities, use external DB (PostgreSQL/MariaDB).

---

### 8. SSL Certificate Verification Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.integration] SSL: CERTIFICATE_VERIFY_FAILED
```

**Cause:** Self-signed certificate or expired cert.

**Fix:**
```yaml
# For development only - NOT for production:
verify_ssl: false

# Proper fix: Install valid certificate or add CA cert
```

---

### 9. Component Already Set Up

**Symptoms:**
```
ERROR (MainThread) [homeassistant.setup] Integration 'mqtt' is already being set up
```

**Cause:** Duplicate configuration or reload during startup.

**Fix:**
- Remove duplicate entries from configuration.yaml
- Wait for startup to complete before reloading

---

### 10. Port Already in Use

**Symptoms:**
```
ERROR (MainThread) [homeassistant.core] Error starting Home Assistant: [Errno 98] Address already in use
```

**Cause:** Another process using port 8123.

**Fix:**
```bash
# Find process using port
netstat -tulpn | grep :8123

# Kill the process
kill -9 <PID>

# Or change HA port in configuration.yaml:
http:
  server_port: 8124
```

---

### 11. YAML Syntax Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.config] Invalid config for [automation]: mapping values are not allowed here
```

**Cause:** Incorrect YAML indentation or structure.

**Fix:**
```bash
# Use YAML validator
ha core check

# Common mistakes:
# - Mixing tabs and spaces
# - Missing colons
# - Incorrect list formatting
```

---

### 12. Integration Failed to Set Up

**Symptoms:**
```
ERROR (MainThread) [homeassistant.config_entries] Error setting up entry Example for integration_name
```

**Cause:** Integration dependency missing or configuration invalid.

**Fix:**
```bash
# Reload the integration
ha integration reload <integration_name>

# Check logs for specific error
ha core logs | grep -A 10 "<integration_name>"

# Reinstall if custom component
```

---

### 13. Entity Registry ID Collision

**Symptoms:**
```
ERROR (MainThread) [homeassistant.helpers.entity_registry] Entity id already registered: sensor.temperatura_salon
```

**Cause:** Multiple entities trying to use same entity_id.

**Fix:**
```bash
# Via UI: Settings → Devices & Services → Entities
# Find duplicates and rename/delete

# Or edit .storage/core.entity_registry (NOT recommended)
```

---

### 14. API Quota Exceeded

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.weather] API quota exceeded
```

**Cause:** Too many API calls to cloud service.

**Fix:**
```yaml
# Increase scan_interval
sensor:
  - platform: weather_service
    scan_interval: 1800  # 30 minutes
```

**Related Issues:** OpenWeatherMap, DarkSky migrations.

---

### 15. Timeout During Setup

**Symptoms:**
```
ERROR (MainThread) [homeassistant.config_entries] Timeout during setup of config entry
```

**Cause:** Device/service not responding during discovery.

**Fix:**
- Check network connectivity
- Increase timeout if device is slow
- Restart the device/service

---

### 16. Unknown Service

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.automation] Service not found: light.turn_on
```

**Cause:** Domain not loaded or typo in service name.

**Fix:**
```bash
# Check available services
ha core info | grep services

# Verify integration is loaded
ha integration list | grep light
```

---

### 17. Database Migration Failed

**Symptoms:**
```
ERROR (Recorder) [homeassistant.components.recorder.migration] Migration from schema version X to Y failed
```

**Cause:** Corrupted database or incompatible schema.

**Fix:**
```bash
# Backup current database
cd /root/config
cp home-assistant_v2.db home-assistant_v2.db.backup

# Delete and let HA create new one (loses history)
rm home-assistant_v2.db

# Or attempt manual migration with SQLite tools
```

---

### 18. UPnP/IGD Setup Failed

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.upnp] Unable to setup UPnP/IGD
```

**Cause:** Router doesn't support UPnP or it's disabled.

**Fix:**
- Enable UPnP in router settings
- Or manually forward ports
- Disable UPnP integration if not needed

---

### 19. Webhook ID Not Found

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.webhook] Received webhook for unknown ID
```

**Cause:** Webhook registration lost after restart.

**Fix:**
- Re-register mobile app/webhook service
- Check webhook URL configuration

---

### 20. ZHA/Zigbee Coordinator Not Found

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.zha] Couldn't open serial port /dev/ttyUSB0
```

**Cause:** USB device path changed or unplugged.

**Fix:**
```bash
# Find USB devices
ls -la /dev/serial/by-id/

# Update configuration with persistent path:
zha:
  usb_path: /dev/serial/by-id/usb-Silicon_Labs_slae.sh_cc2652rb_stick_-_slaesh_s_iot_stuff_00_12_4B_00_21_CC_EE_89-if00-port0
```

---

### 21. Bluetooth Adapter Not Found

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.bluetooth] No Bluetooth adapters found
```

**Cause:** Bluetooth hardware missing or not enabled.

**Fix:**
```bash
# Check Bluetooth status
bluetoothctl list

# Enable if disabled
hciconfig hci0 up

# On HA OS, may need to enable in hardware settings
```

---

### 22. MQTT Connection Refused

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.mqtt] Failed to connect to MQTT server: [Errno 111] Connection refused
```

**Cause:** MQTT broker not running or wrong configuration.

**Fix:**
```bash
# Check broker status
ha addons info core_mosquitto
ha addons logs core_mosquitto

# Verify configuration:
mqtt:
  broker: core-mosquitto  # or IP address
  port: 1883
  username: mqtt_user
  password: !secret mqtt_password
```

---

### 23. ESPHome API Encryption Key Mismatch

**Symptoms:**
```
WARNING (MainThread) [aioesphomeapi] esp_device.local: Connection failed: Invalid encryption key
```

**Cause:** Encryption key in HA doesn't match device.

**Fix:**
```yaml
# In ESPHome device config:
api:
  encryption:
    key: "your-32-char-base64-key=="

# Must match in HA configuration entry
```

---

### 24. Lovelace Resource Failed to Load

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.lovelace] Unable to load resource /local/custom-card.js
```

**Cause:** File missing or wrong path.

**Fix:**
```bash
# Check file exists
ls -la /root/config/www/custom-card.js

# Clear browser cache (Ctrl+F5)

# Verify resource configuration in Lovelace
```

---

### 25. Script Already Running

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.script] Script script.my_script already running
```

**Cause:** Script configured with mode: single and called again.

**Fix:**
```yaml
script:
  my_script:
    mode: restart  # or queued, parallel
    sequence:
      - service: light.turn_on
```

---

### 26. Area Not Found

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.automation] Area salon not found
```

**Cause:** Area referenced doesn't exist or was renamed.

**Fix:**
- Create area: Settings → Areas
- Or update automation with correct area name

---

### 27. Custom Component Import Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.loader] Unable to import custom_component: No module named 'dependency'
```

**Cause:** Custom component missing Python dependencies.

**Fix:**
```bash
# SSH into HA OS
# Install missing dependency (not recommended for HA OS)
# Better: Contact component developer to add manifest requirements
```

---

### 28. Stream Component Failed

**Symptoms:**
```
ERROR (stream_worker) [homeassistant.components.stream] Error demuxing stream
```

**Cause:** Camera stream incompatible or network issues.

**Fix:**
```yaml
# Try different stream settings
camera:
  - platform: generic
    stream_source: rtsp://camera_ip/stream
    rtsp_transport: tcp  # Change from udp
```

---

### 29. Notification Service Not Found

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.notify] Service mobile_app_my_phone not found
```

**Cause:** Mobile app not registered or disconnected.

**Fix:**
- Reinstall Home Assistant mobile app
- Check Settings → Devices & Services → Mobile App
- Re-authenticate

---

### 30. OAuth2 Token Expired

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.integration_name] Token expired
```

**Cause:** Cloud service authentication expired.

**Fix:**
- Go to Settings → Devices & Services
- Reconfigure the integration
- Re-authenticate with cloud service

---

### 31. MediaExtractor Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.media_extractor] Could not retrieve data from URL
```

**Cause:** URL no longer valid or format unsupported.

**Fix:**
- Update to latest HA version
- Check if source changed API

---

### 32. Binary Sensor Unknown State

**Symptoms:**
```
WARNING (MainThread) [homeassistant.helpers.state] binary_sensor has unknown state
```

**Cause:** Sensor hasn't reported yet or connectivity lost.

**Fix:**
```yaml
# Add availability template
binary_sensor:
  - platform: template
    sensors:
      czujnik_ruchu_salon:
        value_template: "{{ states('binary_sensor.motion_salon') }}"
        availability_template: "{{ states('binary_sensor.motion_salon') != 'unavailable' }}"
```

---

### 33. Backup Failed - Disk Space

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.backup] Not enough disk space for backup
```

**Cause:** Insufficient storage on device.

**Fix:**
```bash
# Check disk usage
df -h

# Clean old backups
ha backups list
ha backups remove <slug>

# Or move backups to external storage
```

---

### 34. Energy Dashboard Missing Data

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.energy] Sensor sensor.energy is missing required device class
```

**Cause:** Sensor not properly configured for energy dashboard.

**Fix:**
```yaml
sensor:
  - platform: template
    sensors:
      energia_salon:
        device_class: energy
        unit_of_measurement: "kWh"
        state_class: total_increasing
```

---

### 35. Zone Not Working

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.zone] Invalid zone configuration: latitude required
```

**Cause:** Missing required zone fields.

**Fix:**
```yaml
zone:
  - name: Dom
    latitude: 52.2297
    longitude: 21.0122
    radius: 100
    icon: mdi:home
```

---

### 36. History Stats Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.history_stats] Cannot calculate history statistics
```

**Cause:** Referenced entity has no history.

**Fix:**
```yaml
# Ensure entity is recorded
recorder:
  include:
    entities:
      - binary_sensor.drzwi_salon
```

---

### 37. REST API Call Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.rest] Error fetching data: 404 Client Error
```

**Cause:** API endpoint changed or credentials invalid.

**Fix:**
- Update API URL
- Check API key/credentials
- Verify service is online

---

### 38. Cover Position Error

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.cover] Cover does not support position
```

**Cause:** Cover device doesn't support position control.

**Fix:**
```yaml
# Use open/close instead of set_position
service: cover.open_cover
target:
  entity_id: cover.roleta_salon
```

---

### 39. Weather Entity Deprecated Attributes

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.weather] temperature attribute is deprecated
```

**Cause:** Using old attribute names.

**Fix:**
```jinja2
{# Old: #}
{{ state_attr('weather.home', 'temperature') }}

{# New: #}
{{ state_attr('weather.home', 'temp') }}
```

---

### 40. Input Select Invalid Option

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.input_select] Option invalid_option not found
```

**Cause:** Trying to select option that doesn't exist.

**Fix:**
```yaml
input_select:
  tryb_ogrzewania:
    options:
      - "Eco"
      - "Komfort"
      - "Nieobecność"
    initial: "Komfort"
```

---

### 41. Device Tracker Not Home

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.device_tracker] All known devices are away
```

**Cause:** GPS/network-based tracking failing.

**Fix:**
- Check mobile app permissions
- Verify zone configuration
- Check known_devices.yaml

---

### 42. Alexa Integration Connection Lost

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.alexa] Connection to Alexa API lost
```

**Cause:** AWS service issue or credential problem.

**Fix:**
- Wait for AWS service recovery
- Re-link skill in Alexa app
- Check HA Cloud subscription

---

### 43. Group Contains Unknown Entities

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.group] Group salon_lights contains unknown entities
```

**Cause:** Entity in group doesn't exist.

**Fix:**
```yaml
group:
  salon_lights:
    name: "Światła Salon"
    entities:
      - light.lampa_salon
      - light.led_strip_tv
      # Remove non-existent entities
```

---

### 44. TTS Service Not Available

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.tts] Service google_translate_say not found
```

**Cause:** TTS platform not configured or loaded.

**Fix:**
```yaml
tts:
  - platform: google_translate
    language: 'pl'
```

---

### 45. Calendar Event Parse Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.calendar] Unable to parse calendar event
```

**Cause:** Invalid iCal format from calendar source.

**Fix:**
- Check calendar source is valid
- Update calendar integration
- Verify timezone settings

---

### 46. Shopping List Not Loading

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.shopping_list] Error loading shopping list
```

**Cause:** Corrupted .storage file.

**Fix:**
```bash
# Backup and remove corrupted file
cd /root/config/.storage
cp shopping_list shopping_list.backup
rm shopping_list
# Restart HA to recreate
```

---

### 47. Blueprint Import Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.blueprint] Error importing blueprint
```

**Cause:** Invalid blueprint YAML or network issue.

**Fix:**
- Verify blueprint URL is correct
- Check blueprint syntax
- Try manual import via file

---

### 48. Scene Not Applying

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.scene] Scene salon_wieczor contains unavailable entities
```

**Cause:** Entities in scene are offline.

**Fix:**
```bash
# Check entity availability
ha core entities | grep unavailable

# Update scene to remove/fix entities
```

---

### 49. Python Script Error

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.python_script] Error executing script: NameError
```

**Cause:** Python syntax error or undefined variable.

**Fix:**
```python
# Debug python_script
# Check /config/python_scripts/ for errors
# Add logging: logger.info(f"Debug: {variable}")
```

---

### 50. Persistent Notification Not Dismissing

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.persistent_notification] Notification ID not found
```

**Cause:** Notification already dismissed or ID mismatch.

**Fix:**
```yaml
service: persistent_notification.dismiss
data:
  notification_id: "exact_id_used_when_created"
```

---

### 51. SQL Sensor Query Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.sql] Error executing query: no such table
```

**Cause:** Table doesn't exist in database.

**Fix:**
```yaml
# Verify table name in recorder database
sensor:
  - platform: sql
    db_url: !secret db_url
    queries:
      - name: "Liczba stanów"
        query: "SELECT COUNT(*) FROM states;"
        column: "COUNT(*)"
```

---

### 52. Command Line Sensor Timeout

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.command_line] Command timeout after 15 seconds
```

**Cause:** Command takes too long to execute.

**Fix:**
```yaml
sensor:
  - platform: command_line
    command: "long_running_command"
    command_timeout: 60  # Increase timeout
```

---

### 53. HTTP 429 Too Many Requests

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.integration] HTTP 429: Too Many Requests
```

**Cause:** API rate limit exceeded.

**Fix:**
- Increase scan_interval
- Reduce polling frequency
- Contact service provider for rate limit increase

---

### 54. Climate Preset Mode Not Supported

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.climate] Preset mode away not supported
```

**Cause:** Climate device doesn't support requested preset.

**Fix:**
```yaml
# Check supported presets
service: climate.set_preset_mode
data:
  preset_mode: eco  # Use supported preset
```

---

### 55. Light Color Temp Out of Range

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.light] Color temperature 2000 out of range
```

**Cause:** Requested color temp outside device capabilities.

**Fix:**
```yaml
service: light.turn_on
data:
  entity_id: light.lampa_biurkowa
  color_temp: 250  # Use value in supported range (153-500)
```

---

## Integration-Specific Troubleshooting

### Zigbee (ZHA/Zigbee2MQTT)

#### Connection Issues

**Symptoms:**
- Zigbee coordinator offline
- "Failed to connect to Zigbee coordinator"

**Cause:** USB device disconnected or driver issue.

**Fix:**
```bash
# Check USB device
ls -la /dev/serial/by-id/

# If device missing, check dmesg
dmesg | tail -50

# Use persistent device path in ZHA config
zha:
  usb_path: /dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0
  baudrate: 115200

# Restart ZHA integration
ha integration reload zha
```

**Prevention:** Use by-id paths, avoid USB hubs, use quality USB extension cable.

---

#### Pairing Problems

**Symptoms:**
- Device won't pair
- "Interview failed"
- Device pairs but no entities created

**Cause:** Weak signal, interference, or unsupported device quirk.

**Fix:**
```bash
# Step 1: Check signal strength
# In ZHA, view device details → LQI/RSSI values
# Should be > 100 LQI, < 100 RSSI

# Step 2: Pair closer to coordinator
# Move device within 2-3 meters during pairing

# Step 3: Remove device and re-pair
# Hold reset button for 10+ seconds
# Enable pairing mode: Settings → Devices → Add Integration → ZHA

# Step 4: For Zigbee2MQTT, check if quirk needed
# View: http://homeassistant.local:8099 (Z2M web UI)
# Check "Exposes" tab for supported features
```

**Prevention:** Build strong mesh with powered routers, update coordinator firmware.

**Related Issues:** Battery-powered devices may need multiple pairing attempts.

---

#### Device Unavailable

**Symptoms:**
```
WARNING (MainThread) [homeassistant.components.zha] Device czujnik_temperatury_salon unavailable
```

**Cause:** Device offline, battery dead, or mesh path broken.

**Fix:**
```bash
# Step 1: Check device availability in ZHA
# Settings → Devices & Services → ZHA → Device

# Step 2: For battery devices, replace battery

# Step 3: Reconfigure device
# In ZHA device page → "Reconfigure device"

# Step 4: Check mesh routing
# Ensure powered routers between device and coordinator

# Step 5: For persistent issues, re-pair device
# Remove from ZHA and pair again
```

**Prevention:** Regular battery replacement schedule, document battery types.

---

### Bluetooth

#### Connection Issues

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.bluetooth] Bluetooth adapter hci0 not found
```

**Cause:** Bluetooth hardware disabled or not available.

**Fix:**
```bash
# Check Bluetooth status
bluetoothctl list
# Should show: Controller XX:XX:XX:XX:XX:XX

# Enable Bluetooth
hciconfig hci0 up

# If adapter missing, check hardware
lsusb | grep -i bluetooth

# On HA OS, may require hardware config
# Settings → System → Hardware → Show all hardware
```

---

#### Bluetooth Proxies

**Symptoms:**
- ESPHome proxy not appearing
- Devices not discovered through proxy

**Cause:** Proxy not configured correctly or network issue.

**Fix:**
```yaml
# ESPHome proxy config
esp32_ble_tracker:
  scan_parameters:
    interval: 1100ms
    window: 1100ms
    active: true

bluetooth_proxy:
  active: true

# In HA, check: Settings → Devices & Services → ESPHome
# Proxy should show "Bluetooth proxy: Active"
```

**Prevention:** Use multiple proxies for coverage, keep firmware updated.

---

#### Range Issues

**Symptoms:**
- Devices only work when very close
- Intermittent connections

**Cause:** Bluetooth range limited (10-30m), interference.

**Fix:**
1. Deploy ESPHome Bluetooth proxies throughout home
2. Use ESP32 devices (better range than ESP8266)
3. Position proxies away from WiFi routers and USB 3.0 ports
4. Reduce scan interval to save power while maintaining coverage

```yaml
# Optimal ESPHome BLE proxy config
esp32_ble_tracker:
  scan_parameters:
    interval: 320ms  # Balance between responsiveness and power
    window: 30ms
    active: false    # Passive scanning for better battery life on devices

bluetooth_proxy:
  active: true
```

---

### MQTT

#### Broker Connection Failed

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.mqtt] Failed to connect to MQTT server at core-mosquitto:1883: [Errno 111] Connection refused
```

**Cause:** Mosquitto not running or configuration error.

**Fix:**
```bash
# Check Mosquitto status
ha addons info core_mosquitto

# View logs
ha addons logs core_mosquitto

# Start if stopped
ha addons start core_mosquitto

# Check Mosquitto configuration
# Add-ons → Mosquitto broker → Configuration
# Ensure logins configured:
{
  "logins": [
    {
      "username": "mqtt_user",
      "password": "secure_password"
    }
  ]
}

# Update HA MQTT config
mqtt:
  broker: core-mosquitto
  port: 1883
  username: mqtt_user
  password: !secret mqtt_password
```

---

#### Topic Issues

**Symptoms:**
- Messages not received
- Sensors showing "unavailable"

**Cause:** Topic subscription incorrect or device not publishing.

**Fix:**
```bash
# Install MQTT Explorer add-on to debug

# Or use mosquitto_sub
docker exec addon_core_mosquitto mosquitto_sub -h core-mosquitto -t '#' -v -u mqtt_user -P password

# Check specific topic
mosquitto_sub -h core-mosquitto -t 'zigbee2mqtt/czujnik_salon' -v

# Publish test message
mosquitto_pub -h core-mosquitto -t 'test/topic' -m 'hello' -u mqtt_user -P password
```

**Common topic patterns:**
- Zigbee2MQTT: `zigbee2mqtt/[device_friendly_name]`
- Tasmota: `stat/[device_name]/RESULT`
- ESPHome: `[device_name]/sensor/[sensor_name]/state`

---

#### Authentication Errors

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.mqtt] Connection failed: not authorised
```

**Cause:** Wrong username/password or ACL restrictions.

**Fix:**
```bash
# Verify credentials in Mosquitto config
ha addons config core_mosquitto

# Test connection with mosquitto_pub
docker exec addon_core_mosquitto mosquitto_pub -h localhost -t test -m test -u mqtt_user -P password

# If ACL enabled, check permissions
# Mosquitto config → customize → active: false (to disable ACL)
```

---

### ESPHome

#### OTA Update Failures

**Symptoms:**
```
ERROR [esphome.ota] OTA update failed: Upload timeout
```

**Cause:** Network congestion, device rebooted, or WiFi instability.

**Fix:**
```bash
# Step 1: Try wired upload via ESPHome Web
# https://web.esphome.io/ → Connect via USB

# Step 2: Increase OTA timeout
# In ESPHome device config:
ota:
  safe_mode: true
  password: !secret ota_password
  reboot_timeout: 10min

# Step 3: Use legacy OTA if newer fails
# Add to config:
ota:
  platform: esphome

# Step 4: If device in boot loop, enable safe mode
# Power cycle device 5 times rapidly
# LED should indicate safe mode
# Upload minimal config to recover
```

**Prevention:** Test config on one device before bulk updates, stable WiFi.

---

#### API Encryption Issues

**Symptoms:**
```
WARNING [aioesphomeapi] esp_device.local: Connection failed: Handshake failed
ERROR [homeassistant.components.esphome] Can't connect to ESP device: Invalid encryption key
```

**Cause:** Encryption key mismatch between device and HA.

**Fix:**
```yaml
# In ESPHome device configuration:
api:
  encryption:
    key: "base64-encoded-32-char-key=="

# Key is auto-generated on first compile
# Copy from ESPHome logs when compiling

# If lost, regenerate and re-flash:
# 1. Remove encryption: section from config
# 2. Compile and upload via USB
# 3. Add new encryption: key:
# 4. Compile and OTA upload

# In HA, delete old integration and re-add
# Settings → Devices & Services → ESPHome → Delete
# Re-add with new encryption key
```

---

#### WiFi Connection Problems

**Symptoms:**
```
WARNING [wifi] WiFi network 'MySSID' not found
ERROR [wifi] WiFi connection failed
```

**Cause:** Wrong credentials, signal too weak, or WiFi channel issues.

**Fix:**
```yaml
wifi:
  ssid: "MySSID"
  password: !secret wifi_password
  
  # Add fallback AP for recovery
  ap:
    ssid: "ESP_Fallback"
    password: "recovery123"
  
  # Power settings for stability
  power_save_mode: none
  
  # Manual IP if DHCP issues
  manual_ip:
    static_ip: 192.168.1.150
    gateway: 192.168.1.1
    subnet: 255.255.255.0
    dns1: 192.168.1.1

# Monitor WiFi quality
sensor:
  - platform: wifi_signal
    name: "ESP Signal"
    update_interval: 60s
```

**Prevention:** Use 2.4GHz WiFi, avoid channel 12-13 (not supported by all ESP devices).

---

### WLED

#### Connection Problems

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.wled] Error connecting to WLED device
```

**Cause:** IP changed, device offline, or mDNS not working.

**Fix:**
```bash
# Step 1: Find WLED device on network
# Check router DHCP leases or use:
nmap -p 80 192.168.1.0/24

# Step 2: Access WLED web interface
# http://wled-ip-address

# Step 3: Set static IP in WLED
# WLED web UI → Config → WiFi Setup → Static IP

# Step 4: Update HA integration
# Settings → Devices & Services → WLED
# Reconfigure with new IP

# Step 5: Verify WLED firmware
# Update to latest from: https://install.wled.me/
```

---

#### Effect Issues

**Symptoms:**
- Effects not loading
- Presets missing
- Colors incorrect

**Cause:** WLED configuration or integration version mismatch.

**Fix:**
```yaml
# In WLED web interface:
# - Config → LED Preferences → Color Order (RGB, GRB, etc.)
# - Config → LED Preferences → LED count

# For addressable LEDs (WS2812B):
# - Set correct GPIO pin
# - Verify color order through UI test

# In HA, reload integration
service: homeassistant.reload_config_entry
target:
  entity_id: light.wled_led_strip

# Custom effects via WLED:
# - Config → Security & Updates → Enable OTA
# - Upload custom effects via web UI
```

**Prevention:** Document WLED configs, backup presets regularly (Config → Security).

---

### Tuya Local

#### Local Key Acquisition

**Symptoms:**
- Device requires local key
- "Authentication failed"

**Cause:** Local key not extracted from Tuya cloud.

**Fix:**
```bash
# Method 1: Use Tuya IoT Platform
# 1. Sign up: https://iot.tuya.com/
# 2. Create Cloud Project
# 3. Link Tuya app account
# 4. View device details → Local Key

# Method 2: Use tuya-cli (requires Node.js)
npm install -g @tuya/cli
tuya-cli wizard

# Method 3: Use HA integration setup
# Some Tuya Local integrations auto-discover key

# Add device in HA:
# Settings → Devices & Services → Add Integration → Tuya Local
# Enter device IP, device ID, and local key
```

---

#### Protocol Version Issues

**Symptoms:**
```
ERROR (MainThread) [custom_components.tuya_local] Protocol mismatch: expected 3.3, got 3.1
```

**Cause:** Device using different protocol version.

**Fix:**
```yaml
# Try different protocol versions in integration config:
# - Protocol 3.1 (older devices)
# - Protocol 3.3 (most common)
# - Protocol 3.4 (newer devices)

# Check device details in Tuya app for hints
# Update device firmware via Tuya app if available

# Manual override in configuration:
tuya_local:
  - host: 192.168.1.100
    device_id: "device_id_here"
    local_key: "local_key_here"
    protocol_version: "3.3"
```

---

## Network Debugging

### mDNS Issues

**Symptoms:**
- homeassistant.local not resolving
- ESPHome devices not discovered

**Cause:** mDNS not supported by network or disabled.

**Fix:**
```bash
# Check if mDNS working
ping homeassistant.local

# Install Avahi (if not present)
# On HA OS, built-in

# Check firewall allows mDNS (UDP 5353)
# Router should allow multicast

# Alternative: Use IP address instead
# Find HA IP:
ha network info

# Or check router DHCP leases
```

**Prevention:** Set static IP reservation in router, use IP addresses for critical devices.

---

### DNS Problems

**Symptoms:**
- External services not reachable
- "Name or service not known"

**Cause:** DNS server unreachable or misconfigured.

**Fix:**
```bash
# Check DNS settings
cat /etc/resolv.conf

# Test DNS resolution
nslookup google.com
nslookup home-assistant.io

# Set custom DNS if needed
# HA OS: Settings → System → Network → IPv4 → DNS servers
# Enter: 8.8.8.8, 1.1.1.1

# Or via Network Manager
ha network update eth0 --ipv4-nameserver 8.8.8.8 1.1.1.1
```

---

### Firewall Issues

**Symptoms:**
- Can't access HA from specific networks
- Mobile app can't connect remotely

**Cause:** Firewall blocking ports.

**Fix:**
```bash
# Check if port 8123 accessible
# From another device:
telnet homeassistant.local 8123

# On router, forward ports:
# - 8123 (HA web interface)
# - 443 (if using HTTPS/Nginx)

# For Nabu Casa Cloud, no port forwarding needed

# Check HA firewall (usually off on HA OS)
# If using addon-based firewall, allow:
# - 8123/tcp (HA web)
# - 1883/tcp (MQTT)
# - 5353/udp (mDNS)
```

---

### SSL/TLS Certificate Issues

**Symptoms:**
```
ERROR (MainThread) [homeassistant.components.http] SSL handshake failed
WARNING [aiohttp.server] SSL error in data received
```

**Cause:** Expired certificate, wrong domain, or self-signed cert not trusted.

**Fix:**
```bash
# Check certificate expiry
openssl s_client -connect homeassistant.local:8123 -servername homeassistant.local | openssl x509 -noout -dates

# Using Let's Encrypt via Duck DNS addon:
# - Configure Duck DNS addon
# - Enable "Accept terms of service"
# - Configure certificate path in configuration.yaml:

http:
  ssl_certificate: /ssl/fullchain.pem
  ssl_key: /ssl/privkey.pem

# For self-signed certificates, add CA to client devices
# Or use valid domain with Let's Encrypt

# Renew certificate (Let's Encrypt auto-renews)
# Check Duck DNS addon logs for issues
```

---

## Database Corruption Recovery

### Symptoms of Corruption

```
ERROR (Recorder) [homeassistant.components.recorder.util] Error executing query: database disk image is malformed
ERROR (Recorder) [homeassistant.components.recorder.core] Error during connection setup: database is locked
CRITICAL (Recorder) [homeassistant.components.recorder] Unrecoverable database corruption detected
```

### Recovery Steps

```bash
# Step 1: Stop Home Assistant
ha core stop

# Step 2: Access database directory
cd /root/config

# Step 3: Backup existing database
cp home-assistant_v2.db home-assistant_v2.db.corrupt_$(date +%Y%m%d_%H%M%S)

# Step 4: Attempt repair with SQLite
sqlite3 home-assistant_v2.db "PRAGMA integrity_check"

# If errors found, try to export and reimport
sqlite3 home-assistant_v2.db .dump > dump.sql
mv home-assistant_v2.db home-assistant_v2.db.old
sqlite3 home-assistant_v2.db < dump.sql

# Step 5: If repair fails, create new database
rm home-assistant_v2.db

# Step 6: Start Home Assistant
ha core start

# Home Assistant will create new database (loses history)
```

### Prevention

```yaml
# configuration.yaml
recorder:
  db_url: sqlite:////root/config/home-assistant_v2.db
  auto_purge: true
  purge_keep_days: 7
  commit_interval: 5  # Reduce to minimize data loss
  
  # Exclude high-frequency updates
  exclude:
    domains:
      - automation
      - updater
    entity_globs:
      - sensor.*_history
      - sensor.*_stats_*

# Schedule regular backups
automation:
  - alias: "Backup co tydzień"
    trigger:
      - platform: time
        at: "03:00:00"
    condition:
      - condition: time
        weekday:
          - sun
    action:
      - service: backup.create

# Use external database for large installations
# Example PostgreSQL:
recorder:
  db_url: postgresql://user:password@192.168.1.100:5432/homeassistant
```

---

## Supervisor/OS Troubleshooting

### Supervisor Not Starting

**Symptoms:**
```
ERROR (MainThread) [supervisor.bootstrap] Can't setup Supervisor
ERROR [supervisor.docker] Can't connect to Docker daemon
```

**Cause:** Docker daemon issues or corrupted supervisor container.

**Fix:**
```bash
# SSH into HA OS
ssh root@homeassistant.local

# Check Docker status
docker ps

# Restart Docker (careful - stops all containers)
systemctl restart docker

# Check supervisor status
ha supervisor info

# Restart supervisor
ha supervisor restart

# If supervisor won't start, check logs
journalctl -u hassos-supervisor -f

# Nuclear option - reinstall supervisor
# From HA OS console:
ha supervisor repair
```

---

### Supervisor Updates Failing

**Symptoms:**
```
ERROR [supervisor.updater] Can't fetch versions: HTTP 500
WARNING [supervisor.updater] Update failed, trying rollback
```

**Cause:** Network issue, corrupted update, or insufficient disk space.

**Fix:**
```bash
# Check disk space
df -h
# Ensure at least 2GB free

# Check network connectivity
ping -c 4 version.home-assistant.io

# Clear update cache
ha supervisor reload

# Force check for updates
ha supervisor update

# If specific version needed
ha supervisor update --version 2026.2.0

# Check supervisor logs during update
ha supervisor logs -f
```

---

### Add-on Won't Start

**Symptoms:**
```
ERROR [addons.addon_name] Can't start addon: startup failed
```

**Cause:** Configuration error, port conflict, or missing dependencies.

**Fix:**
```bash
# Check add-on logs
ha addons logs addon_slug

# Common issues:
# 1. Port already in use
netstat -tulpn | grep :[port]

# 2. Configuration error
ha addons info addon_slug
# Fix in: Add-ons → [addon] → Configuration

# 3. Restart add-on
ha addons restart addon_slug

# 4. Reinstall if corrupted
ha addons uninstall addon_slug
ha addons install addon_slug

# 5. Check system resources
ha host info
# Ensure sufficient RAM/storage
```

---

## Add-on Crash Debugging

### Systematic Approach

```bash
# Step 1: Check add-on status
ha addons info addon_slug

# Step 2: View recent logs
ha addons logs addon_slug --tail 200

# Step 3: Follow logs in real-time
ha addons logs addon_slug -f

# Step 4: Check for common patterns
ha addons logs addon_slug | grep -i "error\|fatal\|exception"

# Step 5: Verify configuration
ha addons config addon_slug

# Step 6: Check resource usage
docker stats --no-stream

# Step 7: Restart with clean state
ha addons restart addon_slug
```

### Common Add-on Issues

#### Mosquitto Broker Crashes

**Symptoms:**
```
ERROR [mosquitto] Segmentation fault
ERROR [mosquitto] Address already in use
```

**Fix:**
```bash
# Check configuration
ha addons config core_mosquitto

# Ensure valid config:
{
  "logins": [{"username": "mqtt", "password": "secure"}],
  "require_certificate": false,
  "certfile": "fullchain.pem",
  "keyfile": "privkey.pem"
}

# Clear persistence and restart
ha addons stop core_mosquitto
# Remove /addons/data/core_mosquitto/* via File Editor
ha addons start core_mosquitto
```

---

#### Z-Wave JS Crashes

**Symptoms:**
```
ERROR [zwave-js] Driver failed to start
ERROR [zwave-js] Timeout while waiting for ACK
```

**Fix:**
```bash
# Check USB device
ls -la /dev/serial/by-id/ | grep -i z-wave

# View Z-Wave JS logs
ha addons logs core_zwave_js --tail 500

# Common fixes:
# 1. Use correct device path in addon config
# 2. Disable Z-Wave JS addon, enable ZHA if better suited
# 3. Update stick firmware if available
# 4. Soft reset: ha addons restart core_zwave_js
# 5. Hard reset: re-interview all devices
```

---

#### Node-RED Memory Leaks

**Symptoms:**
- Node-RED becomes unresponsive
- High memory usage over time

**Fix:**
```bash
# Check memory usage
docker stats addon_a0d7b954_nodered

# Restart Node-RED
ha addons restart a0d7b954_nodered

# Optimize flows:
# - Avoid debug nodes in production
# - Use "complete" node output sparingly
# - Limit context storage
# - Review loops and polling

# Increase memory limit if needed
# Addon Configuration:
{
  "system_packages": [],
  "npm_packages": [],
  "init_commands": [],
  "memory_limit": 512  # Increase from default 256MB
}
```

---

## Entity Unavailable Systematic Diagnosis

### Step-by-Step Process

#### Step 1: Identify the Pattern

```bash
# List all unavailable entities
ha core entities | grep unavailable | wc -l

# Check specific domain
ha core entities | grep "binary_sensor.*unavailable"

# In Developer Tools → States, filter by "unavailable"
```

#### Step 2: Check Integration Status

```bash
# List all integrations
ha integration list

# Check specific integration
ha integration info zha

# Reload integration
ha integration reload mqtt
```

#### Step 3: Review Recent Changes

```bash
# Check recent restarts
ha core info | grep -i started

# View change log
cat /root/config/.storage/core.log

# Check recent updates
ha core update --dry-run
```

#### Step 4: Test Device Connectivity

```bash
# For IP devices, ping
ping -c 4 192.168.1.100

# For HTTP devices, curl
curl -I http://device-ip

# For MQTT devices, subscribe to topic
docker exec addon_core_mosquitto mosquitto_sub -h localhost -t 'device/topic' -v -u user -P pass
```

#### Step 5: Check Device-Specific Logs

```bash
# For ZHA devices
ha integration reload zha
# Then: Settings → Devices & Services → ZHA → Device → Reconfigure

# For WiFi devices (check router)
# Verify device has IP and is reachable

# For battery devices
# Check battery level in device attributes
```

#### Step 6: Force Entity Update

```yaml
# Via Developer Tools → Services:
service: homeassistant.update_entity
target:
  entity_id: sensor.temperatura_salon
```

#### Step 7: Remove and Re-add

```bash
# Last resort: delete entity and re-create
# Settings → Devices & Services → [Integration] → Device → Entity
# Delete entity
# Restart HA or reload integration
# Entity should recreate automatically
```

---

## Performance Degradation Diagnosis

### Symptoms
- Slow web UI loading
- Delayed automation triggers
- High CPU usage
- Unresponsive system

### Diagnostic Commands

```bash
# System resource usage
ha host info

# Container stats
docker stats --no-stream

# Database size
du -sh /root/config/home-assistant_v2.db

# Log file size
du -sh /root/config/home-assistant.log

# Count entities
ha core entities | wc -l

# Top CPU consumers (requires SSH to OS)
top -b -n 1 | head -20
```

### Common Causes and Fixes

#### 1. Excessive Database Size

**Symptoms:** Slow queries, high disk I/O

**Fix:**
```yaml
recorder:
  purge_keep_days: 3  # Reduce from default 10
  auto_purge: true
  
  exclude:
    domains:
      - media_player
      - weather
    entity_globs:
      - sensor.*_history*
      - sensor.*_stats_*

# Manual purge
service: recorder.purge
data:
  keep_days: 3
  repack: true
```

---

#### 2. Too Many Integrations/Entities

**Symptoms:** Slow startup, high memory

**Fix:**
- Audit integrations: Settings → Devices & Services
- Disable unused integrations
- Remove unused entities
- Use groups/helpers to reduce entity count

```yaml
# Disable entity without removing
homeassistant:
  customize:
    sensor.unused_sensor:
      hidden: true
      disabled: true
```

---

#### 3. Polling-Heavy Integrations

**Symptoms:** High CPU, network traffic spikes

**Fix:**
```yaml
# Increase scan_interval for sensors
sensor:
  - platform: rest
    resource: http://slow-api.com/data
    scan_interval: 3600  # 1 hour instead of default 30s

# Or use webhook/push instead of polling
```

---

#### 4. Lovelace Dashboard Complexity

**Symptoms:** Slow UI, browser lag

**Fix:**
- Reduce number of cards per view
- Use conditional cards
- Optimize history graphs (reduce time period)
- Split into multiple dashboards
- Disable unused custom cards

```yaml
# Optimize history card
type: history-graph
entities:
  - entity: sensor.temperatura_salon
hours_to_show: 24  # Reduce from 168 (week)
refresh_interval: 60  # Increase from default 0
```

---

## Memory/CPU Issue Identification

### Memory Exhaustion

**Symptoms:**
```
WARNING (MainThread) [supervisor.host] System is running low on memory
ERROR (MainThread) [homeassistant.core] Out of memory
```

**Diagnosis:**
```bash
# Check memory usage
free -h

# Per-container memory
docker stats --no-stream

# Identify memory leaks
ha core logs | grep -i "memory\|oom"
```

**Fix:**
```bash
# Immediate: Restart HA
ha core restart

# Long-term solutions:
# 1. Upgrade to more RAM (min 2GB for HA OS)
# 2. Reduce recorder database
# 3. Disable memory-heavy integrations
# 4. Use external database (PostgreSQL)

# Limit container memory
# For add-ons, set in addon config:
{
  "memory_limit": 512
}
```

---

### High CPU Usage

**Symptoms:**
- System slow/unresponsive
- Fan running constantly
- CPU temperature high

**Diagnosis:**
```bash
# Check CPU usage
ha host info

# Top processes
top -b -n 1

# HA Core CPU usage
docker stats homeassistant --no-stream

# Identify automation loops
ha core logs | grep -i "automation\|script" | grep -i "trigger"
```

**Common Causes:**

#### Automation Loops

**Fix:**
```yaml
# Bad: Triggers itself
automation:
  - alias: "Loop Example"
    trigger:
      - platform: state
        entity_id: input_boolean.test
    action:
      - service: input_boolean.toggle
        target:
          entity_id: input_boolean.test  # This creates a loop!

# Good: Add condition to prevent loop
automation:
  - alias: "No Loop"
    trigger:
      - platform: state
        entity_id: input_boolean.test
    condition:
      - condition: template
        value_template: "{{ trigger.to_state.state != trigger.from_state.state }}"
    action:
      - service: light.turn_on
```

#### High-Frequency Polling

**Fix:**
```yaml
# Reduce update frequency
sensor:
  - platform: command_line
    command: heavy_script.sh
    scan_interval: 600  # 10 minutes instead of 30 seconds
```

#### Template Sensors with Complex Logic

**Fix:**
```yaml
# Optimize templates
template:
  - sensor:
      - name: "Średnia Temperatura"
        # Bad: Recalculates on every state change
        state: >
          {{ (float(states('sensor.temp1')) + float(states('sensor.temp2'))) / 2 }}
        
        # Good: Only updates when specific sensors change
        state: >
          {{ (float(states('sensor.temp1')) + float(states('sensor.temp2'))) / 2 }}
        availability: >
          {{ states('sensor.temp1') != 'unavailable' and states('sensor.temp2') != 'unavailable' }}
```

---

## Quick Reference Commands

```bash
# System Status
ha core info                    # Core version and status
ha supervisor info              # Supervisor status
ha host info                    # System resources
ha network info                 # Network configuration

# Logs
ha core logs -f                 # Follow core logs
ha supervisor logs              # Supervisor logs
ha addons logs <slug>           # Addon logs

# Maintenance
ha core restart                 # Restart HA Core
ha supervisor restart           # Restart Supervisor
ha core check                   # Validate configuration
ha core update                  # Update HA Core

# Backups
ha backups list                 # List backups
ha backups new --name "Manual"  # Create backup
ha backups restore <slug>       # Restore backup

# Integrations
ha integration list             # List integrations
ha integration reload <name>    # Reload integration

# Add-ons
ha addons                       # List installed add-ons
ha addons start <slug>          # Start add-on
ha addons stop <slug>           # Stop add-on
ha addons restart <slug>        # Restart add-on

# Database
sqlite3 /root/config/home-assistant_v2.db "SELECT COUNT(*) FROM states;"  # Count states
sqlite3 /root/config/home-assistant_v2.db "VACUUM;"                       # Compact database

# Network
ping -c 4 <device-ip>           # Test connectivity
nmap -sn 192.168.1.0/24         # Scan network
curl -I http://<device>         # Test HTTP device
```

---

## Preventive Maintenance Checklist

### Weekly
- [ ] Check supervisor for updates
- [ ] Review error logs for recurring issues
- [ ] Verify backups are running
- [ ] Check disk space usage

### Monthly
- [ ] Update all add-ons
- [ ] Review and remove unused integrations
- [ ] Test backup restore procedure
- [ ] Clean up automations and scripts
- [ ] Review database size and purge if needed

### Quarterly
- [ ] Update HA Core (after reading release notes)
- [ ] Review and update SSL certificates
- [ ] Test all critical automations
- [ ] Document system changes
- [ ] Review and update exclusions in recorder

### Annually
- [ ] Major version update (plan for breaking changes)
- [ ] Full system backup to external storage
- [ ] Hardware inspection (SD card health, power supply)
- [ ] Security audit (passwords, exposed ports)
- [ ] Review and refactor complex automations

---

## Getting Help

### Before Asking for Help

1. **Search Existing Issues**
   - Home Assistant Community: https://community.home-assistant.io/
   - GitHub Issues: https://github.com/home-assistant/core/issues

2. **Gather Information**
   ```bash
   # System info
   ha core info
   ha host info
   
   # Relevant logs (last 100 lines)
   ha core logs --tail 100
   
   # Configuration check
   ha core check
   ```

3. **Create Minimal Reproducible Example**
   - Isolate the issue
   - Remove unrelated configuration
   - Document exact steps to reproduce

4. **Include Context**
   - HA version
   - Installation type (HA OS, Container, Core)
   - Relevant integrations and versions
   - Recent changes before issue appeared

### Community Resources
- Forum: https://community.home-assistant.io/
- Discord: https://discord.gg/home-assistant
- Reddit: r/homeassistant
- Documentation: https://www.home-assistant.io/docs/

---

**Last Updated:** 2026-02-18
**Maintainer:** Home Assistant Expert System
**Version:** 1.0