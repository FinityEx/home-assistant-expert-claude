# Dashboard Design Reference (2025/2026)

**When to use this**: Designing responsive, modern Lovelace dashboards with current best practices.

## Core Philosophy
**"Beautiful, Simple, Mobile-First, Fast."** Avoid clutter. Prioritize usability over showing everything. Use consistent styling and animations.

---

## Table of Contents
1. [Modern Layout Systems](#modern-layout-systems)
2. [Card Libraries](#card-libraries)
3. [Design Patterns](#design-patterns)
4. [Responsive Design](#responsive-design)
5. [Theme Customization](#theme-customization)
6. [Advanced Techniques](#advanced-techniques)

---

## Modern Layout Systems

### Sections Layout (2024.1+)
**When to use**: New dashboards (default for modern HA)

**Benefits**:
- Responsive by design
- Grid-based with automatic flow
- Better mobile experience
- Replaces nested vertical/horizontal stacks

```yaml
views:
  - title: Home
    type: sections
    sections:
      - type: grid
        cards:
          - type: tile
            entity: light.living_room
          - type: tile
            entity: climate.thermostat
      
      - type: grid
        title: Climate
        cards:
          - type: custom:mushroom-climate-card
            entity: climate.bedroom
```

**Grid configuration**:
```yaml
- type: grid
  max_columns: 4  # Max columns on large screens
  column_span: 1  # Default span for cards
  cards:
    - type: tile
      entity: light.room1
    - type: tile
      entity: light.room2
      column_span: 2  # This card spans 2 columns
```

### Legacy Layouts

**Vertical Stack** (still useful for grouping):
```yaml
type: vertical-stack
cards:
  - type: custom:mushroom-title-card
    title: Living Room
  - type: custom:mushroom-light-card
    entity: light.living_room
```

**Horizontal Stack** (side-by-side cards):
```yaml
type: horizontal-stack
cards:
  - type: button
    entity: light.room1
  - type: button
    entity: light.room2
  - type: button
    entity: light.room3
```

**Grid Card** (manual grid):
```yaml
type: grid
square: false
columns: 3
cards:
  - type: button
    entity: light.room1
  - type: button
    entity: light.room2
  - type: button
    entity: light.room3
```

---

## Card Libraries

### 1. Mushroom Cards (HACS - Essential)
**Installation**: HACS → Frontend → Search "Mushroom"

**Why use**: Clean, minimalist, customizable, template support

#### Mushroom Title Card
```yaml
type: custom:mushroom-title-card
title: Salon
subtitle: "{{ states('sensor.salon_temperatura') }}°C • {{ states('sensor.salon_wilgotnosc') }}%"
```

#### Mushroom Template Card (Most Versatile)
```yaml
type: custom:mushroom-template-card
primary: "{{ area_name }}"
secondary: >
  {% set temp = states('sensor.temp') | float %}
  {% set hum = states('sensor.humidity') | float %}
  {{ temp }}°C • {{ hum }}%
icon: mdi:home
icon_color: >
  {% if is_state('light.main', 'on') %}
    orange
  {% else %}
    grey
  {% endif %}
entity: light.main
tap_action:
  action: toggle
hold_action:
  action: more-info
double_tap_action:
  action: navigate
  navigation_path: /lovelace/room-detail
badge_icon: >
  {% if is_state('binary_sensor.window', 'on') %}
    mdi:window-open
  {% endif %}
badge_color: red
```

#### Mushroom Light Card
```yaml
type: custom:mushroom-light-card
entity: light.living_room
name: Salon - Główne
icon: mdi:ceiling-light
use_light_color: true
show_brightness_control: true
show_color_control: true
show_color_temp_control: true
collapsible_controls: true
```

#### Mushroom Climate Card
```yaml
type: custom:mushroom-climate-card
entity: climate.bedroom
name: Sypialnia
icon: mdi:thermostat
show_temperature_control: true
collapsible_controls: true
hvac_modes:
  - heat
  - "off"
```

#### Mushroom Cover Card
```yaml
type: custom:mushroom-cover-card
entity: cover.bedroom_blinds
name: Rolety - Sypialnia
show_position_control: true
show_tilt_position_control: false
```

#### Mushroom Media Player Card
```yaml
type: custom:mushroom-media-player-card
entity: media_player.spotify
name: Spotify
icon: mdi:spotify
use_media_info: true
show_volume_level: true
collapsible_controls: true
volume_controls:
  - volume_mute
  - volume_set
media_controls:
  - play_pause_stop
  - previous
  - next
```

#### Mushroom Person Card
```yaml
type: custom:mushroom-person-card
entity: person.jan
name: Jan
icon: mdi:account
use_entity_picture: true
```

#### Mushroom Chips Card (Status Bar)
```yaml
type: custom:mushroom-chips-card
alignment: center
chips:
  # Entity chip
  - type: entity
    entity: sensor.temperature
    icon: mdi:thermometer
    icon_color: red
    content_info: state
  
  # Template chip
  - type: template
    icon: mdi:weather-{{ states('weather.home') }}
    icon_color: >
      {% if is_state('weather.home', 'sunny') %}
        yellow
      {% else %}
        grey
      {% endif %}
    content: "{{ state_attr('weather.home', 'temperature') }}°C"
  
  # Conditional chip
  - type: conditional
    conditions:
      - entity: lock.front_door
        state: unlocked
    chip:
      type: template
      icon: mdi:lock-open
      icon_color: red
      content: Otwarte!
      tap_action:
        action: call-service
        service: lock.lock
        target:
          entity_id: lock.front_door
  
  # Action chip
  - type: action
    icon: mdi:light-switch
    icon_color: orange
    tap_action:
      action: call-service
      service: light.toggle
      target:
        area_id: living_room
  
  # Menu chip
  - type: menu
    icon: mdi:menu
```

### 2. Bubble Card (HACS - Mobile Optimized)
**Installation**: HACS → Frontend → Search "Bubble Card"

**Why use**: Mobile-first, pop-ups, sub-buttons, horizontal controls

#### Bubble Card
```yaml
type: custom:bubble-card
card_type: button
entity: light.living_room
name: Salon
icon: mdi:sofa
show_state: true
show_last_changed: false
show_attribute: false
scrolling_effect: true
sub_button:
  - entity: light.living_room_lamp
    show_background: true
  - entity: light.living_room_led
    show_background: true
```

#### Bubble Pop-Up Card
```yaml
type: custom:bubble-card
card_type: pop-up
hash: "#living-room"
name: Salon
icon: mdi:sofa
margin: 30px
width_desktop: 540px
bg_color: "rgba(0,0,0,0.7)"
bg_blur: true
card:
  type: vertical-stack
  cards:
    - type: custom:mushroom-light-card
      entity: light.living_room
      show_brightness_control: true
    - type: custom:mushroom-climate-card
      entity: climate.living_room
```

#### Bubble Horizontal Buttons Stack
```yaml
type: custom:bubble-card
card_type: horizontal-buttons-stack
auto_order: true
1_icon: mdi:sofa
1_name: Salon
1_link: "#living-room"
2_icon: mdi:bed
2_name: Sypialnia
2_link: "#bedroom"
3_icon: mdi:pot-steam
3_name: Kuchnia
3_link: "#kitchen"
```

### 3. Mini Media Player (HACS)
**Installation**: HACS → Frontend → Search "Mini Media Player"

```yaml
type: custom:mini-media-player
entity: media_player.spotify
name: Spotify
icon: mdi:spotify
artwork: cover
hide:
  volume: false
  power: false
  source: false
  info: false
shortcuts:
  columns: 4
  buttons:
    - name: Ulubione
      type: playlist
      id: spotify:playlist:xxxxx
    - name: Relaks
      type: playlist
      id: spotify:playlist:yyyyy
```

### 4. ApexCharts Card (HACS)
**Installation**: HACS → Frontend → Search "ApexCharts"

```yaml
type: custom:apexcharts-card
graph_span: 24h
header:
  show: true
  title: Temperatura - 24h
  show_states: true
series:
  - entity: sensor.living_room_temperature
    name: Salon
    stroke_width: 2
    color: red
  - entity: sensor.bedroom_temperature
    name: Sypialnia
    stroke_width: 2
    color: blue
  - entity: sensor.outside_temperature
    name: Na zewnątrz
    stroke_width: 2
    color: green
apex_config:
  chart:
    height: 250px
  xaxis:
    labels:
      format: HH:mm
  yaxis:
    decimalsInFloat: 1
    min: 15
    max: 30
```

### 5. Card-Mod (HACS - CSS Styling)
**Installation**: HACS → Frontend → Search "card-mod"

```yaml
type: entities
entities:
  - entity: light.living_room
card_mod:
  style: |
    ha-card {
      background: rgba(0, 0, 0, 0.3);
      border-radius: 20px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
    }
```

### 6. Auto-Entities (HACS - Dynamic Cards)
**Installation**: HACS → Frontend → Search "Auto-entities"

```yaml
type: custom:auto-entities
card:
  type: entities
  title: Światła włączone
filter:
  include:
    - domain: light
      state: "on"
  exclude:
    - entity_id: "light.ignored_*"
sort:
  method: friendly_name
```

### 7. Button Card (HACS - Advanced Customization)
**Installation**: HACS → Frontend → Search "button-card"

```yaml
type: custom:button-card
entity: light.living_room
name: Salon
icon: mdi:sofa
show_state: true
show_label: true
label: >
  [[[
    if (entity.state === 'on') {
      return 'Brightness: ' + entity.attributes.brightness;
    }
    return 'Off';
  ]]]
styles:
  card:
    - background: >
        [[[ return entity.state === 'on' ? 'rgba(255, 165, 0, 0.3)' : 'rgba(0, 0, 0, 0.3)'; ]]]
    - border-radius: 15px
  icon:
    - color: >
        [[[ return entity.state === 'on' ? 'orange' : 'grey'; ]]]
tap_action:
  action: toggle
hold_action:
  action: more-info
```

---

## Design Patterns

### 1. The "Glance" Header (Status Bar)
**When to use**: Top of every view to show critical status

```yaml
type: custom:mushroom-chips-card
alignment: center
chips:
  - type: entity
    entity: sensor.temperature_average
    icon: mdi:thermometer
    content_info: state
  - type: entity
    entity: sensor.humidity_average
    icon: mdi:water-percent
    content_info: state
  - type: template
    icon: mdi:home-account
    content: "{{ states('sensor.person_count_home') }}"
  - type: conditional
    conditions:
      - entity: binary_sensor.front_door
        state: "on"
    chip:
      type: template
      icon: mdi:door-open
      icon_color: red
      content: Drzwi!
  - type: conditional
    conditions:
      - entity: binary_sensor.window_any_open
        state: "on"
    chip:
      type: template
      icon: mdi:window-open
      icon_color: orange
      content: Okno
```

### 2. The "Room Card" (All-in-One Control)
**When to use**: One card per room that shows status and controls main devices

```yaml
type: custom:mushroom-template-card
primary: Salon
secondary: >
  {% set temp = states('sensor.salon_temp') %}
  {% set light = states('light.salon') %}
  {% if light == 'on' %}
    💡 Włączone • {{ temp }}°C
  {% else %}
    • {{ temp }}°C
  {% endif %}
icon: mdi:sofa
icon_color: >
  {% if is_state('light.salon', 'on') %}
    orange
  {% else %}
    grey
  {% endif %}
entity: light.salon
tap_action:
  action: toggle
hold_action:
  action: fire-dom-event
  browser_mod:
    service: browser_mod.popup
    data:
      title: Salon - Kontrola
      size: wide
      content:
        type: vertical-stack
        cards:
          - type: custom:mushroom-light-card
            entity: light.salon
            show_brightness_control: true
            show_color_control: true
          - type: custom:mushroom-climate-card
            entity: climate.salon
            show_temperature_control: true
          - type: custom:mushroom-cover-card
            entity: cover.salon_blinds
            show_position_control: true
badge_icon: >
  {% if is_state('binary_sensor.salon_window', 'on') %}
    mdi:window-open
  {% endif %}
badge_color: orange
```

### 3. Conditional Visibility
**When to use**: Show controls only when needed

```yaml
type: conditional
conditions:
  - condition: state
    entity: media_player.tv
    state: "playing"
card:
  type: custom:mini-media-player
  entity: media_player.tv
  artwork: cover
  hide:
    power: true
```

**Multiple conditions**:
```yaml
type: conditional
conditions:
  - condition: state
    entity: sun.sun
    state: below_horizon
  - condition: numeric_state
    entity: sensor.lux
    below: 50
card:
  type: entities
  title: Nocna kontrola
  entities:
    - light.bedroom
    - light.hallway
```

### 4. Multi-State Template Cards
**When to use**: Visual representation of complex states

```yaml
type: custom:mushroom-template-card
primary: Tryb Domu
secondary: "{{ states('input_select.house_mode') }}"
icon: >
  {% set mode = states('input_select.house_mode') %}
  {% if mode == 'Normal' %} mdi:home
  {% elif mode == 'Gość' %} mdi:account-multiple
  {% elif mode == 'Urlop' %} mdi:beach
  {% elif mode == 'Noc' %} mdi:sleep
  {% endif %}
icon_color: >
  {% set mode = states('input_select.house_mode') %}
  {% if mode == 'Normal' %} green
  {% elif mode == 'Gość' %} blue
  {% elif mode == 'Urlop' %} orange
  {% elif mode == 'Noc' %} purple
  {% endif %}
tap_action:
  action: call-service
  service: input_select.select_next
  target:
    entity_id: input_select.house_mode
```

### 5. Scene/Script Buttons
**When to use**: Quick access to scenes and scripts

```yaml
type: horizontal-stack
cards:
  - type: custom:mushroom-template-card
    primary: Relaks
    icon: mdi:sofa
    icon_color: orange
    tap_action:
      action: call-service
      service: scene.turn_on
      target:
        entity_id: scene.salon_relaks
  
  - type: custom:mushroom-template-card
    primary: Film
    icon: mdi:movie
    icon_color: purple
    tap_action:
      action: call-service
      service: scene.turn_on
      target:
        entity_id: scene.salon_film
  
  - type: custom:mushroom-template-card
    primary: Jasno
    icon: mdi:brightness-7
    icon_color: yellow
    tap_action:
      action: call-service
      service: scene.turn_on
      target:
        entity_id: scene.salon_jasno
```

### 6. Energy Dashboard Integration
**When to use**: Show energy consumption in custom dashboards

```yaml
type: energy-date-selection

type: energy-sources-table

type: energy-usage-graph
```

### 7. Alarm Panel
**When to use**: Security system control

```yaml
type: alarm-panel
entity: alarm_control_panel.home
states:
  - arm_away
  - arm_home
  - arm_night
```

---

## Responsive Design

### Mobile vs Tablet vs Desktop

**Approach 1: View visibility**
```yaml
views:
  - title: Mobile
    visible:
      - user: admin
        tab: false  # Hide from sidebar
    type: sections
    # Mobile-optimized layout
  
  - title: Desktop
    visible: true
    type: sections
    # Desktop layout
```

**Approach 2: Card-mod responsive CSS**
```yaml
card_mod:
  style: |
    @media (max-width: 768px) {
      ha-card {
        font-size: 0.9em;
        padding: 8px;
      }
    }
```

### Column Span for Different Screens
```yaml
sections:
  - type: grid
    max_columns: 4  # Desktop: 4 columns
    cards:
      - type: tile
        entity: light.room1
        column_span: 1  # Takes 1 column (desktop: 25%, mobile: 100%)
      
      - type: custom:apexcharts-card
        column_span: 2  # Takes 2 columns (desktop: 50%, mobile: 100%)
        # ... chart config
```

### Touch-Friendly Sizing
- Minimum tap target: 48x48 pixels
- Use larger icons on mobile
- Increase spacing between interactive elements

```yaml
type: custom:mushroom-template-card
primary: Button
tap_action:
  action: toggle
card_mod:
  style: |
    ha-card {
      min-height: 60px;
      padding: 12px;
    }
```

---

## Theme Customization

### Popular Themes (HACS)

1. **Mushroom Themes**: Match Mushroom cards
2. **Minimalist**: Clean, simple
3. **iOS Themes**: iOS Dark/Light mode
4. **Nord Theme**: Scandinavian color palette
5. **Slate**: Dark, modern
6. **Noctis**: Dark with purple accents

### Custom Theme Basics
```yaml
# themes.yaml or in configuration.yaml under frontend:
custom_theme:
  # Main colors
  primary-color: "#FF6F00"
  accent-color: "#00BCD4"
  
  # Background colors
  primary-background-color: "#1a1a1a"
  secondary-background-color: "#2a2a2a"
  
  # Card
  card-background-color: "#2a2a2a"
  
  # Text
  primary-text-color: "#e1e1e1"
  secondary-text-color: "#9b9b9b"
  disabled-text-color: "#6f6f6f"
  
  # Sidebar
  sidebar-background-color: "#1a1a1a"
  sidebar-icon-color: "#9b9b9b"
  sidebar-selected-text-color: "#FF6F00"
  sidebar-selected-icon-color: "#FF6F00"
  
  # States
  state-icon-color: "#9b9b9b"
  state-icon-active-color: "#FF6F00"
  
  # Switches
  switch-checked-color: "#00BCD4"
  switch-unchecked-button-color: "#6f6f6f"
  
  # Sliders
  slider-color: "#FF6F00"
  slider-secondary-color: "#2a2a2a"
  
  # Labels
  label-badge-background-color: "#2a2a2a"
  label-badge-text-color: "#e1e1e1"
  
  # Cards
  ha-card-border-radius: "12px"
  ha-card-box-shadow: "0 2px 8px rgba(0,0,0,0.3)"
```

### Theme per Device (Browser Mod)
```yaml
# Automation to set theme based on device
automation:
  - alias: "Set theme based on device"
    trigger:
      - platform: state
        entity_id: sensor.browser_mod_device_id
    action:
      - choose:
          - conditions:
              - condition: template
                value_template: "{{ 'mobile' in trigger.to_state.attributes.user_agent }}"
            sequence:
              - service: frontend.set_theme
                data:
                  name: mobile_theme
        default:
          - service: frontend.set_theme
            data:
              name: desktop_theme
```

### Per-User Theme
```yaml
# configuration.yaml
frontend:
  themes: !include themes.yaml
  
# Automation
automation:
  - alias: "User theme preference"
    trigger:
      - platform: homeassistant
        event: start
    action:
      - service: frontend.set_theme
        data:
          name: "{{ state_attr('person.jan', 'preferred_theme') }}"
```

---

## Advanced Techniques

### 1. Custom Header (HACS)
**Installation**: HACS → Frontend → Search "Custom Header"

```yaml
# configuration.yaml
custom_header:
  compact_mode: true
  hide_help: true
  hide_config: false
  hide_unused: true
  hide_refresh: true
  voice_hide: true
  
  # Per-user configuration
  exceptions:
    - conditions:
        user: admin
      config:
        hide_config: false
    - conditions:
        user: guest
      config:
        hide_config: true
        hide_unused: true
```

### 2. Swipe Card (Mobile Navigation)
**Installation**: HACS → Frontend → Search "Swipe Card"

```yaml
type: custom:swipe-card
parameters:
  effect: coverflow
  speed: 500
  spaceBetween: 20
  threshold: 5
cards:
  - type: vertical-stack
    cards:
      # View 1
  - type: vertical-stack
    cards:
      # View 2
```

### 3. Layout Card (Advanced Layouts)
**Installation**: HACS → Frontend → Search "layout-card"

```yaml
type: custom:layout-card
layout_type: grid
layout:
  grid-template-columns: 1fr 1fr 1fr
  grid-template-rows: auto
  grid-template-areas: |
    "header header header"
    "main main sidebar"
    "footer footer footer"
cards:
  - type: markdown
    content: Header
    view_layout:
      grid-area: header
  
  - type: entities
    entities:
      - light.main
    view_layout:
      grid-area: main
```

### 4. State Switch Card (Conditional Content)
**Installation**: HACS → Frontend → Search "state-switch"

```yaml
type: custom:state-switch
entity: input_select.dashboard_view
default: default
states:
  home:
    type: vertical-stack
    cards:
      # Home view cards
  away:
    type: vertical-stack
    cards:
      # Away view cards
  night:
    type: vertical-stack
    cards:
      # Night view cards
```

### 5. Plotly Graph Card (Advanced Graphs)
**Installation**: HACS → Frontend → Search "Plotly"

```yaml
type: custom:plotly-graph
entities:
  - entity: sensor.temperature
    name: Temperatura
    line:
      color: red
      width: 2
  - entity: sensor.humidity
    name: Wilgotność
    yaxis: y2
    line:
      color: blue
      width: 2
layout:
  height: 400
  yaxis:
    title: Temperatura (°C)
  yaxis2:
    title: Wilgotność (%)
    overlaying: y
    side: right
```

### 6. Animated Icons (Template + CSS)
```yaml
type: custom:mushroom-template-card
icon: >
  {% if is_state('binary_sensor.motion', 'on') %}
    mdi:motion-sensor
  {% else %}
    mdi:motion-sensor-off
  {% endif %}
card_mod:
  style: |
    ha-card {
      {% if is_state('binary_sensor.motion', 'on') %}
        animation: pulse 2s infinite;
      {% endif %}
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
```

### 7. Floorplan Integration
**Installation**: HACS → Frontend → Search "ha-floorplan"

```yaml
type: custom:floorplan-card
config:
  image: /local/floorplan.svg
  stylesheet: /local/floorplan.css
  rules:
    - entity: light.living_room
      element: light.living_room
      state_action:
        "on":
          class: light-on
        "off":
          class: light-off
```

### 8. Picture Elements (Interactive Images)
```yaml
type: picture-elements
image: /local/images/room.jpg
elements:
  - type: state-icon
    entity: light.living_room
    style:
      top: 30%
      left: 20%
    tap_action:
      action: toggle
  
  - type: state-label
    entity: sensor.temperature
    prefix: "Temp: "
    suffix: "°C"
    style:
      top: 10%
      left: 50%
      color: white
      font-size: 20px
```

---

## Dashboard Organization Strategies

### Strategy 1: Single View with Pop-ups
**Best for**: Mobile users, simple setups

```yaml
views:
  - title: Home
    type: sections
    sections:
      # Status bar at top
      - type: grid
        cards:
          - type: custom:mushroom-chips-card
            # ... status chips
      
      # Room cards that open pop-ups
      - type: grid
        title: Pokoje
        cards:
          - type: custom:mushroom-template-card
            # Living room card with hold_action popup
          - type: custom:mushroom-template-card
            # Bedroom card with hold_action popup
```

### Strategy 2: Multiple Views
**Best for**: Desktop users, complex setups

```yaml
views:
  - title: Overview
    path: overview
    icon: mdi:home
    # Summary of all rooms
  
  - title: Salon
    path: living-room
    icon: mdi:sofa
    # Living room detailed controls
  
  - title: Sypialnia
    path: bedroom
    icon: mdi:bed
    # Bedroom detailed controls
  
  - title: System
    path: system
    icon: mdi:cog
    # System monitoring and settings
```

### Strategy 3: Hybrid (Overview + Details)
**Best for**: All users

```yaml
views:
  - title: Home
    type: sections
    # Quick access and status
  
  - title: Rooms
    type: sections
    # All room controls
  
  - title: Climate
    type: sections
    # All climate controls
  
  - title: Media
    type: sections
    # All media players
  
  - title: Energy
    type: sections
    # Energy monitoring
```

---

## Performance Optimization

### Lazy Loading
- Use conditional cards to avoid loading hidden content
- Split large dashboards into multiple views
- Use `visible: false` for views that aren't frequently accessed

### Reduce Template Complexity
**Bad** (recalculates on every state change):
```yaml
secondary: >
  {{ states.light | selectattr('state', 'eq', 'on') | list | length }} lights on
```

**Good** (use helper sensor):
```yaml
# Template sensor in configuration
template:
  - sensor:
      - name: "Lights On Count"
        state: "{{ states.light | selectattr('state', 'eq', 'on') | list | length }}"

# Dashboard card
secondary: "{{ states('sensor.lights_on_count') }} lights on"
```

### Image Optimization
- Compress images before uploading to `/local/`
- Use appropriate image sizes (don't use 4K images for thumbnails)
- Consider using WebP format for better compression

### Minimize Custom Cards
- Each custom card adds JavaScript overhead
- Use built-in cards when possible
- Prefer Mushroom cards over Button Card for simple use cases (lighter)

---

## Accessibility Considerations

### High Contrast Mode Support
```yaml
card_mod:
  style: |
    @media (prefers-contrast: high) {
      ha-card {
        border: 2px solid var(--primary-text-color);
      }
    }
```

### Screen Reader Support
- Use descriptive names for entities
- Avoid icon-only buttons without labels
- Ensure color isn't the only indicator of state

### Keyboard Navigation
- All interactive elements should be keyboard accessible
- Test tab order makes sense
- Use semantic HTML when possible

---

## Polish Language Best Practices

### Entity Names
- Frontend names can be Polish: "Salon - Główne światło"
- Entity IDs stay English: `light.salon_main`

### Dashboard Text
```yaml
type: custom:mushroom-title-card
title: Panel Domowy
subtitle: "Witaj, {{ user }}!"
```

### Template Translations
```yaml
secondary: >
  {% set state = states('light.salon') %}
  {% if state == 'on' %}
    Włączone
  {% elif state == 'off' %}
    Wyłączone
  {% else %}
    Niedostępne
  {% endif %}
```

---

## Complete Example Dashboard

```yaml
views:
  - title: Dom
    type: sections
    sections:
      # Status bar
      - type: grid
        cards:
          - type: custom:mushroom-chips-card
            alignment: center
            chips:
              - type: entity
                entity: sensor.srednia_temperatura
                icon: mdi:thermometer
              - type: entity
                entity: sensor.srednia_wilgotnosc
                icon: mdi:water-percent
              - type: template
                icon: mdi:lightbulb-group
                content: "{{ states.light | selectattr('state', 'eq', 'on') | list | length }}"
              - type: conditional
                conditions:
                  - entity: binary_sensor.any_window_open
                    state: "on"
                chip:
                  type: template
                  icon: mdi:window-open
                  icon_color: orange
      
      # Rooms
      - type: grid
        title: Pokoje
        max_columns: 3
        cards:
          - type: custom:mushroom-template-card
            primary: Salon
            secondary: "{{ states('sensor.salon_temp') }}°C"
            icon: mdi:sofa
            icon_color: "{{ 'orange' if is_state('light.salon', 'on') else 'grey' }}"
            entity: light.salon
            tap_action:
              action: toggle
            hold_action:
              action: navigate
              navigation_path: /lovelace/salon
          
          - type: custom:mushroom-template-card
            primary: Sypialnia
            secondary: "{{ states('sensor.sypialnia_temp') }}°C"
            icon: mdi:bed
            icon_color: "{{ 'orange' if is_state('light.sypialnia', 'on') else 'grey' }}"
            entity: light.sypialnia
            tap_action:
              action: toggle
            hold_action:
              action: navigate
              navigation_path: /lovelace/sypialnia
          
          - type: custom:mushroom-template-card
            primary: Kuchnia
            secondary: "{{ states('sensor.kuchnia_temp') }}°C"
            icon: mdi:pot-steam
            icon_color: "{{ 'orange' if is_state('light.kuchnia', 'on') else 'grey' }}"
            entity: light.kuchnia
            tap_action:
              action: toggle
            hold_action:
              action: navigate
              navigation_path: /lovelace/kuchnia
      
      # Climate
      - type: grid
        title: Klimat
        cards:
          - type: custom:mushroom-climate-card
            entity: climate.salon
            show_temperature_control: true
            collapsible_controls: true
      
      # Media
      - type: grid
        title: Media
        cards:
          - type: conditional
            conditions:
              - condition: not
                conditions:
                  - condition: state
                    entity: media_player.spotify
                    state: "off"
            card:
              type: custom:mini-media-player
              entity: media_player.spotify
              artwork: cover
      
      # Scenes
      - type: grid
        title: Sceny
        cards:
          - type: horizontal-stack
            cards:
              - type: custom:mushroom-template-card
                primary: Relaks
                icon: mdi:sofa
                icon_color: orange
                tap_action:
                  action: call-service
                  service: scene.turn_on
                  target:
                    entity_id: scene.relaks
              - type: custom:mushroom-template-card
                primary: Film
                icon: mdi:movie
                icon_color: purple
                tap_action:
                  action: call-service
                  service: scene.turn_on
                  target:
                    entity_id: scene.film
              - type: custom:mushroom-template-card
                primary: Dobranoc
                icon: mdi:sleep
                icon_color: blue
                tap_action:
                  action: call-service
                  service: scene.turn_on
                  target:
                    entity_id: scene.dobranoc
```

---

**Cross-references**:
- [Automation Patterns](automation_patterns.md) for dashboard-triggered automations
- [Template Patterns](template_patterns.md) for advanced template cards
- [HACS Curated](hacs_curated.md) for installing card libraries
