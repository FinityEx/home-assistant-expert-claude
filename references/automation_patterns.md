# Automation Best Practices (2025/2026)

## Core Philosophy
**Resilient and State-Independent.** Assume Home Assistant will restart at any moment.

## 1. Input-Logic-Output Architecture
Separate the *trigger* from the *condition* and the *action*.

*   **Helpers (Input)**: Use Input Booleans/Selects for state (e.g., `input_boolean.guest_mode`).
*   **Conditions (Logic)**: Check these helpers in your automations.
*   **Scripts (Output)**: Put complex actions in scripts, call the script from the automation.

## 2. Robust Trigger Patterns

### The "Catch-Up" Pattern (Trigger IDs)
Handle both the "Event" (motion detected) and the "State Check" (HA just started and motion is already ON).

```yaml
automation:
  - alias: "Turn on lights with motion"
    trigger:
      # 1. Normal trigger
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
        id: "motion_detected"
      # 2. Catch-up trigger (if HA restarted)
      - platform: homeassistant
        event: start
        id: "startup"
    condition:
      # Check if motion is actually on (needed for startup trigger)
      - condition: state
        entity_id: binary_sensor.motion
        state: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: light.room
```

## 3. Error Handling
Use `continue_on_error` for non-critical steps (like notifications) so the main logic doesn't fail.

```yaml
action:
  - service: notify.mobile_app_phone
    data:
      message: "Something happened"
    continue_on_error: true
  - service: light.turn_on
    target:
      entity_id: light.important_light
```

## 4. Blueprint Usage
Prefer Blueprints for:
- Motion-activated lights (with dimming/sun elevation logic).
- Zigbee button remotes (handling clicks, double clicks, holds).
- Low battery notifications.

**Why?** They handle edge cases (debouncing, restarts, etc.) better than custom YAML.

## 5. Naming Convention
`domain.area_device_function`
- `light.kitchen_ceiling_main`
- `sensor.living_room_temp_humidity`
- `automation.bedroom_morning_routine`
