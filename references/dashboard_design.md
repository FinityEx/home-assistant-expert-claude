# Dashboard Design Best Practices (2025/2026)

## Core Philosophy
**"Beautiful yet super simple and focused on usability."**
Avoid clutter. Prioritize mobile-first design. Use consistent styling.

## 1. Modern Layouts
*   **Sections Layout (Grid)**: The new standard. Responsive by design. Replaces nested `vertical-stack` and `horizontal-stack`.
*   **Single Page Dashboard**: Use a single main view with "popups" for details to avoid navigating between tabs.

## 2. Recommended Card Components
*   **Mushroom Cards (HACS)**: The gold standard for minimalist UI.
    *   `custom:mushroom-template-card`: For almost everything.
    *   `custom:mushroom-chips-card`: For the top header status.
*   **Bubble Card (HACS)**: For mobile-optimized "sub-button" interactions.
*   **Mini Media Player**: For compact media controls.

## 3. Design Patterns

### The "Glance" Header
Use `mushroom-chips-card` at the top of the view to show critical status.
```yaml
type: custom:mushroom-chips-card
chips:
  - type: entity
    entity: sensor.home_temperature
    icon: mdi:thermometer
  - type: conditional
    conditions:
      - entity: lock.front_door
        state: "unlocked"
    chip:
      type: template
      icon: mdi:lock-open-variant
      icon_color: red
      content: Unlocked!
```

### The "Room Card" (Hybrid)
Instead of 10 individual cards for a room, use one card that controls the main light, with a popup for details.
```yaml
type: custom:mushroom-template-card
primary: Living Room
secondary: "{{ states('sensor.living_room_temp') }}°C | {{ states('light.living_room_main') }}"
icon: mdi:sofa
icon_color: "{{ 'orange' if is_state('light.living_room_main', 'on') else 'grey' }}"
entity: light.living_room_main
tap_action:
  action: toggle
hold_action:
  action: fire-dom-event
  browser_mod:
    service: browser_mod.popup
    data:
      title: Living Room Controls
      content:
        type: vertical-stack
        cards:
          - type: custom:mushroom-light-card
            entity: light.living_room_main
            show_brightness_control: true
          - type: custom:mushroom-climate-card
            entity: climate.living_room
```

### Conditional Visibility
Hide controls when they aren't needed.
```yaml
type: conditional
conditions:
  - entity: media_player.tv
    state: "playing"
card:
  type: custom:mini-media-player
  entity: media_player.tv
```

## 4. Themes
*   **Graphite**: Clean, flat, modern.
*   **iOS Dark/Light**: Classic, familiar.
