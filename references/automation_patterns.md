# Automation Patterns Reference (2025/2026)

**When to use this**: Every automation you write should follow these patterns for reliability, maintainability, and performance.

## Core Philosophy
**Resilient, State-Independent, and Debuggable.** Assume Home Assistant will restart at any moment. Design automations that recover gracefully and log their operations.

---

## Table of Contents
1. [Trigger Types & Patterns](#trigger-types--patterns)
2. [Automation Modes](#automation-modes)
3. [Conditions & Logic](#conditions--logic)
4. [Advanced Action Patterns](#advanced-action-patterns)
5. [Variables & Templates](#variables--templates)
6. [Error Handling & Resilience](#error-handling--resilience)
7. [Notification Patterns](#notification-patterns)
8. [State Machine Patterns](#state-machine-patterns)
9. [Blueprint Authoring](#blueprint-authoring)
10. [Performance & Optimization](#performance--optimization)

---

## Trigger Types & Patterns

### 1. State Trigger
**When to use**: Entity state changes (most common trigger type)

```yaml
trigger:
  - platform: state
    entity_id: binary_sensor.motion_kitchen
    from: "off"
    to: "on"
    for:
      minutes: 2  # Optional: State must persist for duration
    id: "motion_detected"  # Optional: Use for multi-trigger logic
```

**Advanced pattern with attributes**:
```yaml
trigger:
  - platform: state
    entity_id: sensor.thermostat
    attribute: hvac_action  # Trigger on attribute change, not state
    to: "heating"
```

### 2. Numeric State Trigger
**When to use**: Threshold-based triggers (temperature, humidity, battery)

```yaml
trigger:
  - platform: numeric_state
    entity_id: sensor.temperature_outside
    below: 5
    for:
      minutes: 10
  - platform: numeric_state
    entity_id: sensor.battery_phone
    below: 20
    id: "low_battery"
```

**With templates**:
```yaml
trigger:
  - platform: numeric_state
    entity_id: sensor.living_room_temp
    below: 18
    value_template: "{{ state.attributes.temperature }}"  # Use specific attribute
```

### 3. Time Trigger
**When to use**: Scheduled actions at specific times

```yaml
trigger:
  - platform: time
    at: "07:00:00"  # Exact time
  - platform: time
    at: input_datetime.wake_up_time  # User-configurable time
  - platform: time
    at: sensor.next_alarm  # Dynamic from another entity
```

### 4. Time Pattern Trigger
**When to use**: Recurring intervals, periodic checks

```yaml
trigger:
  - platform: time_pattern
    hours: "/1"  # Every hour
  - platform: time_pattern
    minutes: "/15"  # Every 15 minutes
  - platform: time_pattern
    minutes: "0"
    seconds: "0"  # Top of every hour
```

### 5. Template Trigger
**When to use**: Complex logic that can't be expressed with other triggers

```yaml
trigger:
  - platform: template
    value_template: >
      {{ states('sensor.temperature') | float > 25 
         and is_state('binary_sensor.window', 'open') }}
    for:
      minutes: 5  # Optional: Template must be true for duration
```

**Multi-entity template**:
```yaml
trigger:
  - platform: template
    value_template: >
      {% set lights = ['light.room1', 'light.room2', 'light.room3'] %}
      {{ lights | select('is_state', 'on') | list | length == 3 }}
```

### 6. Event Trigger
**When to use**: System events, button presses, custom events

```yaml
trigger:
  # System events
  - platform: event
    event_type: homeassistant_start
  - platform: event
    event_type: homeassistant_stop
  
  # Custom events
  - platform: event
    event_type: custom_event_name
    event_data:
      action: "button_press"
      device: "remote_1"
  
  # Automation triggered event
  - platform: event
    event_type: automation_triggered
    event_data:
      entity_id: automation.other_automation
```

### 7. Webhook Trigger
**When to use**: External systems calling into HA (IFTTT, Shortcuts, custom apps)

```yaml
trigger:
  - platform: webhook
    webhook_id: "my_unique_webhook_id"  # Creates URL: /api/webhook/my_unique_webhook_id
    allowed_methods:
      - POST
      - GET
    local_only: false  # Set true to only allow local network
```

**Access webhook data in actions**:
```yaml
action:
  - action: notify.mobile_app
    data:
      message: "Webhook received: {{ trigger.json.message }}"
```

### 8. MQTT Trigger
**When to use**: MQTT message-based triggers (Zigbee, custom IoT)

```yaml
trigger:
  - platform: mqtt
    topic: "zigbee2mqtt/button_living_room/action"
    payload: "single"  # Optional: specific payload
  - platform: mqtt
    topic: "home/sensors/+"  # Wildcard: matches home/sensors/temp, home/sensors/humidity
    value_template: "{{ value_json.state }}"  # Parse JSON
```

### 9. Zone Trigger
**When to use**: Geolocation-based automations

```yaml
trigger:
  - platform: zone
    entity_id: person.john
    zone: zone.home
    event: enter  # or leave
  - platform: zone
    entity_id: device_tracker.phone
    zone: zone.work
    event: leave
```

### 10. Device Trigger
**When to use**: Device-specific events (buttons, motion sensors via integrations)

```yaml
trigger:
  - platform: device
    device_id: 1234567890abcdef  # Found in UI
    domain: mqtt
    type: action
    subtype: "single"
    discovery_id: "0x00158d0001234567_action"
```

### 11. Calendar Trigger
**When to use**: Trigger from calendar events

```yaml
trigger:
  - platform: calendar
    entity_id: calendar.holidays
    event: start  # or end
    offset: "-00:15:00"  # 15 minutes before event starts
```

### 12. Sun Trigger
**When to use**: Sunrise/sunset based automations

```yaml
trigger:
  - platform: sun
    event: sunset
    offset: "-00:30:00"  # 30 minutes before sunset
  - platform: sun
    event: sunrise
    offset: "+01:00:00"  # 1 hour after sunrise
```

### 13. Tag Trigger
**When to use**: NFC tag scans

```yaml
trigger:
  - platform: tag
    tag_id: "nfc-tag-bedroom-001"
```

### The "Catch-Up" Pattern (Startup Triggers)
**When to use**: Ensure automation runs even if HA restarted while condition was true

```yaml
automation:
  - alias: "Motion Light with Catch-Up"
    mode: restart
    trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
        id: "motion"
      - platform: homeassistant
        event: start
        id: "startup"
    condition:
      - condition: state
        entity_id: binary_sensor.motion
        state: "on"
    action:
      - action: light.turn_on
        target:
          entity_id: light.room
```

---

## Automation Modes

**Always specify mode** - it controls how the automation handles multiple triggers while already running.

### Mode: Single (Default)
**When to use**: Most common - prevent overlapping runs

```yaml
automation:
  - alias: "Example Single Mode"
    mode: single
    max_exceeded: silent  # Options: silent, warning, error
```

**Behavior**: If triggered while running, new trigger is ignored.
**Use case**: Toggle lights, one-shot actions

### Mode: Restart
**When to use**: Cancel existing run and start fresh

```yaml
automation:
  - alias: "Motion Light Timeout"
    mode: restart
```

**Behavior**: If triggered while running, stops current run and starts new one.
**Use case**: Motion-activated lights (reset timer on new motion)

### Mode: Queued
**When to use**: Execute all triggers in order

```yaml
automation:
  - alias: "Sequential Actions"
    mode: queued
    max: 5  # Queue up to 5 runs
```

**Behavior**: Queues new triggers, executes after current completes.
**Use case**: TTS announcements, sequential operations

### Mode: Parallel
**When to use**: Run multiple instances simultaneously

```yaml
automation:
  - alias: "Multi-Room Notifications"
    mode: parallel
    max: 10  # Allow up to 10 parallel runs
```

**Behavior**: Each trigger runs independently.
**Use case**: Button presses, per-room actions

---

## Conditions & Logic

### Basic Conditions

**State condition**:
```yaml
condition:
  - condition: state
    entity_id: input_boolean.guest_mode
    state: "off"
  - condition: state
    entity_id: light.bedroom
    state: "on"
    for:
      minutes: 5  # State must be true for duration
```

**Numeric state condition**:
```yaml
condition:
  - condition: numeric_state
    entity_id: sensor.temperature
    above: 20
    below: 25
```

**Time condition**:
```yaml
condition:
  - condition: time
    after: "22:00:00"
    before: "06:00:00"
  - condition: time
    weekday:
      - mon
      - tue
      - wed
      - thu
      - fri
```

**Sun condition**:
```yaml
condition:
  - condition: sun
    after: sunset
    after_offset: "-00:30:00"  # 30 min before sunset
```

**Zone condition**:
```yaml
condition:
  - condition: zone
    entity_id: person.john
    zone: zone.home
```

**Template condition**:
```yaml
condition:
  - condition: template
    value_template: >
      {{ states('sensor.temperature') | float > 25 
         and is_state('person.john', 'home') }}
```

### Logical Operators

**AND (all must be true)**:
```yaml
condition:
  - condition: and
    conditions:
      - condition: state
        entity_id: light.room
        state: "off"
      - condition: sun
        after: sunset
```

**OR (at least one must be true)**:
```yaml
condition:
  - condition: or
    conditions:
      - condition: state
        entity_id: person.john
        state: "home"
      - condition: state
        entity_id: person.jane
        state: "home"
```

**NOT (invert condition)**:
```yaml
condition:
  - condition: not
    conditions:
      - condition: state
        entity_id: input_boolean.guest_mode
        state: "on"
```

**Complex nesting**:
```yaml
condition:
  - condition: and
    conditions:
      - condition: or
        conditions:
          - condition: state
            entity_id: person.john
            state: "home"
          - condition: state
            entity_id: person.jane
            state: "home"
      - condition: time
        after: "06:00:00"
        before: "22:00:00"
```

---

## Advanced Action Patterns

### Choose (If-Then-Else)
**When to use**: Multiple branches based on conditions

```yaml
action:
  - choose:
      # Branch 1
      - conditions:
          - condition: state
            entity_id: sun.sun
            state: "below_horizon"
        sequence:
          - action: light.turn_on
            target:
              entity_id: light.room
            data:
              brightness: 100
      
      # Branch 2
      - conditions:
          - condition: numeric_state
            entity_id: sensor.lux
            below: 50
        sequence:
          - action: light.turn_on
            target:
              entity_id: light.room
            data:
              brightness: 50
    
    # Default (else)
    default:
      - action: light.turn_off
        target:
          entity_id: light.room
```

### If-Then-Else (Simplified)
**When to use**: Simple two-branch logic (HA 2022.12+)

```yaml
action:
  - if:
      - condition: state
        entity_id: binary_sensor.motion
        state: "on"
    then:
      - action: light.turn_on
        target:
          entity_id: light.room
    else:
      - action: light.turn_off
        target:
          entity_id: light.room
```

### Repeat Actions

**Repeat until**:
```yaml
action:
  - repeat:
      until:
        - condition: state
          entity_id: binary_sensor.door
          state: "closed"
      sequence:
        - action: notify.mobile_app
          data:
            message: "Door is still open!"
        - delay: "00:01:00"
```

**Repeat count**:
```yaml
action:
  - repeat:
      count: 3
      sequence:
        - action: light.turn_on
          target:
            entity_id: light.room
        - delay: "00:00:01"
        - action: light.turn_off
          target:
            entity_id: light.room
        - delay: "00:00:01"
```

**Repeat while**:
```yaml
action:
  - repeat:
      while:
        - condition: state
          entity_id: input_boolean.alarm_active
          state: "on"
      sequence:
        - action: siren.turn_on
          target:
            entity_id: siren.alarm
        - delay: "00:00:05"
```

**Repeat for each**:
```yaml
action:
  - repeat:
      for_each: "{{ ['room1', 'room2', 'room3'] }}"
      sequence:
        - action: light.turn_on
          target:
            entity_id: "light.{{ repeat.item }}"
```

### Parallel Actions
**When to use**: Run multiple action sequences simultaneously

```yaml
action:
  - parallel:
      - sequence:
          - action: light.turn_on
            target:
              area_id: living_room
          - delay: "00:00:05"
          - action: media_player.play_media
            target:
              entity_id: media_player.living_room
            data:
              media_content_id: "music_playlist"
              media_content_type: "playlist"
      
      - sequence:
          - action: climate.set_temperature
            target:
              entity_id: climate.living_room
            data:
              temperature: 22
          - delay: "00:00:10"
          - action: notify.mobile_app
            data:
              message: "Climate adjusted"
```

### Wait Actions

**Wait for trigger**:
```yaml
action:
  - action: light.turn_on
    target:
      entity_id: light.room
  - wait_for_trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "off"
        for:
          minutes: 5
    timeout: "00:10:00"  # Max 10 minutes
    continue_on_timeout: false  # Stop if timeout
  - action: light.turn_off
    target:
      entity_id: light.room
```

**Wait template**:
```yaml
action:
  - wait_template: "{{ is_state('binary_sensor.door', 'closed') }}"
    timeout: "00:05:00"
  - action: notify.mobile_app
    data:
      message: "Door closed (or timed out)"
```

---

## Variables & Templates

### Trigger Variables
**When to use**: Capture trigger data for use in actions

```yaml
automation:
  - alias: "Webhook Handler with Variables"
    trigger:
      - platform: webhook
        webhook_id: "my_webhook"
    variables:
      message: "{{ trigger.json.message }}"
      priority: "{{ trigger.json.priority | default('normal') }}"
    action:
      - action: notify.mobile_app
        data:
          message: "{{ message }}"
          data:
            priority: "{{ priority }}"
```

### Automation Variables
**When to use**: Define reusable values for entire automation

```yaml
automation:
  - alias: "Multi-Room Light Control"
    variables:
      rooms:
        - living_room
        - bedroom
        - kitchen
      brightness: 80
    trigger:
      - platform: state
        entity_id: input_boolean.all_lights_on
        to: "on"
    action:
      - repeat:
          for_each: "{{ rooms }}"
          sequence:
            - action: light.turn_on
              target:
                entity_id: "light.{{ repeat.item }}"
              data:
                brightness_pct: "{{ brightness }}"
```

### Complex Template Variables

```yaml
automation:
  - alias: "Dynamic Light Brightness"
    trigger:
      - platform: time_pattern
        minutes: "/5"
    variables:
      # Calculate brightness based on sun elevation
      brightness: >
        {% set elevation = state_attr('sun.sun', 'elevation') | float %}
        {% if elevation < -10 %}
          255
        {% elif elevation < 0 %}
          {{ 255 - (elevation * 10) | int }}
        {% else %}
          0
        {% endif %}
      
      # Get list of lights that are currently on
      active_lights: >
        {{ states.light
           | selectattr('state', 'eq', 'on')
           | map(attribute='entity_id')
           | list }}
    condition:
      - condition: template
        value_template: "{{ active_lights | length > 0 }}"
    action:
      - repeat:
          for_each: "{{ active_lights }}"
          sequence:
            - action: light.turn_on
              target:
                entity_id: "{{ repeat.item }}"
              data:
                brightness: "{{ brightness }}"
```

---

## Error Handling & Resilience

### Continue on Error
**When to use**: Non-critical actions that shouldn't stop the automation

```yaml
action:
  - action: notify.mobile_app
    data:
      message: "Alert"
    continue_on_error: true
  - action: light.turn_on  # This will run even if notify fails
    target:
      entity_id: light.critical
```

### Error Handling with Choose

```yaml
action:
  - choose:
      - conditions:
          - condition: template
            value_template: "{{ states('sensor.temperature') != 'unavailable' }}"
        sequence:
          - action: climate.set_temperature
            target:
              entity_id: climate.thermostat
            data:
              temperature: "{{ states('sensor.temperature') | float + 2 }}"
    default:
      - action: notify.mobile_app
        data:
          message: "Temperature sensor unavailable, using default"
      - action: climate.set_temperature
        target:
          entity_id: climate.thermostat
        data:
          temperature: 22
```

### Availability Checks

```yaml
automation:
  - alias: "Safe Device Control"
    trigger:
      - platform: state
        entity_id: binary_sensor.trigger
        to: "on"
    condition:
      # Check device is available before acting on it
      - condition: template
        value_template: "{{ states('light.target') not in ['unavailable', 'unknown'] }}"
    action:
      - action: light.turn_on
        target:
          entity_id: light.target
```

---

## Notification Patterns

### Basic Mobile Notification

```yaml
action:
  - action: notify.mobile_app_phone
    data:
      message: "Motion detected in {{ area_name }}"
      title: "Security Alert"
```

### Actionable Notifications

```yaml
action:
  - action: notify.mobile_app_phone
    data:
      message: "Front door left open"
      title: "Door Alert"
      data:
        actions:
          - action: "CLOSE_DOOR"
            title: "Close Door"
          - action: "IGNORE"
            title: "Ignore"
        tag: "door_open"  # Replace previous notification with same tag
        group: "door_alerts"
        
# Separate automation to handle action response
automation:
  - alias: "Handle Door Action"
    trigger:
      - platform: event
        event_type: mobile_app_notification_action
        event_data:
          action: "CLOSE_DOOR"
    action:
      - action: cover.close_cover
        target:
          entity_id: cover.garage_door
```

### Critical Notifications

```yaml
action:
  - action: notify.mobile_app_phone
    data:
      message: "Smoke detected!"
      title: "⚠️ CRITICAL ALERT"
      data:
        priority: high
        ttl: 0
        channel: alarm_stream
        importance: high
        vibrationPattern: "100, 1000, 100, 1000"
```

### TTS Announcements

```yaml
action:
  - action: tts.speak
    target:
      entity_id: media_player.living_room_speaker
    data:
      message: "Czas na kawę! Temperatura w kuchni to {{ states('sensor.kitchen_temp') }} stopni."
      language: "pl"  # Polish TTS
      cache: false
```

### Multi-Target Notifications

```yaml
action:
  - action: notify.notify  # Sends to all configured notifiers
    data:
      message: "System notification"
  - action: notify.mobile_app_phone
    data:
      message: "Mobile specific"
  - action: tts.speak
    target:
      entity_id:
        - media_player.kitchen
        - media_player.bedroom
    data:
      message: "Voice announcement"
```

---

## State Machine Patterns

### Using Input Select as State Machine

**When to use**: Complex multi-state logic (alarm systems, presence, modes)

```yaml
# Configuration
input_select:
  house_mode:
    name: Tryb Domu
    options:
      - "Normal"
      - "Gość"
      - "Urlop"
      - "Noc"
    initial: "Normal"

# State transition automation
automation:
  - alias: "House Mode: Evening to Night"
    trigger:
      - platform: time
        at: "22:00:00"
    condition:
      - condition: state
        entity_id: input_select.house_mode
        state: "Normal"
    action:
      - action: input_select.select_option
        target:
          entity_id: input_select.house_mode
        data:
          option: "Noc"

# Mode-dependent automation
automation:
  - alias: "Motion Light (Mode Dependent)"
    trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: input_select.house_mode
                state: "Noc"
            sequence:
              - action: light.turn_on
                target:
                  entity_id: light.hallway
                data:
                  brightness_pct: 10
          
          - conditions:
              - condition: state
                entity_id: input_select.house_mode
                state: "Normal"
            sequence:
              - action: light.turn_on
                target:
                  entity_id: light.hallway
                data:
                  brightness_pct: 100
        
        default:
          - action: light.turn_off
            target:
              entity_id: light.hallway
```

---

## Blueprint Authoring

### Basic Blueprint Structure

```yaml
blueprint:
  name: Motion-Activated Light
  description: Włącza światło gdy wykryje ruch, wyłącza po czasie bezczynności
  domain: automation
  input:
    motion_entity:
      name: Czujnik ruchu
      selector:
        entity:
          domain: binary_sensor
          device_class: motion
    light_target:
      name: Światło do kontroli
      selector:
        target:
          entity:
            domain: light
    no_motion_wait:
      name: Czas oczekiwania (sekundy)
      default: 120
      selector:
        number:
          min: 0
          max: 3600
          unit_of_measurement: seconds
    brightness:
      name: Jasność (%)
      default: 100
      selector:
        number:
          min: 1
          max: 100
          unit_of_measurement: "%"

automation:
  - alias: "Motion Light Blueprint"
    mode: restart
    trigger:
      - platform: state
        entity_id: !input motion_entity
        to: "on"
    action:
      - action: light.turn_on
        target: !input light_target
        data:
          brightness_pct: !input brightness
      - wait_for_trigger:
          - platform: state
            entity_id: !input motion_entity
            to: "off"
            for:
              seconds: !input no_motion_wait
      - action: light.turn_off
        target: !input light_target
```

### Advanced Blueprint with Conditions

```yaml
blueprint:
  name: Advanced Motion Light
  description: Motion light with sun elevation and custom conditions
  domain: automation
  input:
    motion_entity:
      name: Motion Sensor
      selector:
        entity:
          domain: binary_sensor
          device_class: motion
    light_target:
      name: Light
      selector:
        target:
          entity:
            domain: light
    elevation:
      name: Sun Elevation Threshold
      default: 5
      selector:
        number:
          min: -90
          max: 90
    only_when_home:
      name: Only When Home
      default: false
      selector:
        boolean:
    person_entity:
      name: Person (if only when home)
      default: {}
      selector:
        entity:
          domain: person

automation:
  - alias: "Advanced Motion Light Blueprint"
    mode: restart
    trigger:
      - platform: state
        entity_id: !input motion_entity
        to: "on"
    condition:
      - condition: numeric_state
        entity_id: sun.sun
        attribute: elevation
        below: !input elevation
      - condition: template
        value_template: >
          {% set only_home = only_when_home %}
          {% if only_home %}
            {{ is_state(person_entity, 'home') }}
          {% else %}
            true
          {% endif %}
    action:
      - action: light.turn_on
        target: !input light_target
      - wait_for_trigger:
          - platform: state
            entity_id: !input motion_entity
            to: "off"
            for:
              minutes: 2
      - action: light.turn_off
        target: !input light_target
```

---

## Performance & Optimization

### Debouncing (Rate Limiting)

```yaml
automation:
  - alias: "Debounced Sensor Update"
    mode: single  # Ignore rapid triggers
    trigger:
      - platform: state
        entity_id: sensor.rapid_sensor
        for:
          seconds: 5  # Must be stable for 5 seconds
    action:
      - action: input_number.set_value
        target:
          entity_id: input_number.stable_value
        data:
          value: "{{ states('sensor.rapid_sensor') }}"
```

### Reducing Automation Runs

**Bad** (runs every state change):
```yaml
trigger:
  - platform: state
    entity_id: sensor.temperature
```

**Good** (runs only on meaningful changes):
```yaml
trigger:
  - platform: numeric_state
    entity_id: sensor.temperature
    above: 25
  - platform: numeric_state
    entity_id: sensor.temperature
    below: 20
```

### Area-Based Actions

```yaml
action:
  - action: light.turn_on
    target:
      area_id: living_room  # Controls all lights in area
  - action: light.turn_off
    target:
      area_id:
        - bedroom
        - bathroom
```

### Label-Based Actions

```yaml
action:
  - action: light.turn_off
    target:
      label_id: "auto_off"  # All entities with this label
```

---

## Naming Conventions

### Entity Names
`domain.location_device_function`

Examples:
- `light.salon_sufit_glowna` (Polish: living room ceiling main)
- `sensor.kuchnia_temperatura` (Polish: kitchen temperature)
- `binary_sensor.sypialnia_ruch` (Polish: bedroom motion)
- `switch.garaz_brama` (Polish: garage gate)

### Automation Names
`automation.location_trigger_action` or descriptive Polish names

Examples:
- `automation.kuchnia_ruch_swiatlo` (kitchen motion light)
- `automation.poranek_rolety` (morning blinds)
- `automation.noc_wszystkie_swiatla_wylacz` (night all lights off)

---

## Common Patterns Quick Reference

### Motion-Activated Light (Best Practice)
```yaml
automation:
  - alias: "Światło w korytarzu - ruch"
    mode: restart
    trigger:
      - platform: state
        entity_id: binary_sensor.korytarz_ruch
        to: "on"
    condition:
      - condition: numeric_state
        entity_id: sun.sun
        attribute: elevation
        below: 5
    action:
      - action: light.turn_on
        target:
          entity_id: light.korytarz
        data:
          brightness_pct: >
            {% if now().hour >= 22 or now().hour < 6 %}
              20
            {% else %}
              100
            {% endif %}
      - wait_for_trigger:
          - platform: state
            entity_id: binary_sensor.korytarz_ruch
            to: "off"
            for:
              minutes: 3
        timeout: "00:30:00"
        continue_on_timeout: true
      - action: light.turn_off
        target:
          entity_id: light.korytarz
```

### Low Battery Notification
```yaml
automation:
  - alias: "Powiadomienie - słaba bateria"
    mode: parallel
    max: 10
    trigger:
      - platform: numeric_state
        entity_id:
          - sensor.czujnik1_battery
          - sensor.czujnik2_battery
          - sensor.pilot_battery
        below: 20
    action:
      - action: notify.mobile_app
        data:
          message: "{{ state_attr(trigger.entity_id, 'friendly_name') }}: {{ states(trigger.entity_id) }}% baterii"
          title: "⚠️ Niska bateria"
```

### Leaving Home
```yaml
automation:
  - alias: "Wychodzenie z domu"
    trigger:
      - platform: state
        entity_id: group.family
        from: "home"
        to: "not_home"
        for:
          minutes: 5
    action:
      - action: climate.set_preset_mode
        target:
          entity_id: climate.all_thermostats
        data:
          preset_mode: "away"
      - action: light.turn_off
        target:
          entity_id: all
      - action: media_player.turn_off
        target:
          entity_id: all
      - action: notify.mobile_app
        data:
          message: "Tryb 'Wyjście' aktywowany"
```

---

**Cross-references**:
- [Template Patterns](template_patterns.md) for advanced Jinja2 templates
- [Dashboard Design](dashboard_design.md) for UI automation triggers
- [Troubleshooting Guide](troubleshooting_guide.md) for debugging automations
