# Home Assistant Template Patterns Guide

Complete reference for Jinja2 templates in Home Assistant with Polish entity examples.

**Last Updated:** 2026-02-18

## Table of Contents

1. [Jinja2 Template Syntax](#jinja2-template-syntax)
2. [Template Sensor Patterns](#template-sensor-patterns)
3. [Common Template Functions](#common-template-functions)
4. [Date/Time Manipulation](#datetime-manipulation)
5. [Math and Statistics](#math-and-statistics)
6. [List/Group Operations](#listgroup-operations)
7. [Conditional Formatting](#conditional-formatting)
8. [Template Debugging](#template-debugging)
9. [Polish Language Considerations](#polish-language-considerations)
10. [Performance Optimization](#performance-optimization)

---

## Jinja2 Template Syntax

### Basic Syntax

**When to use:** Understanding core template syntax for all HA automations and sensors.

```yaml
# Variable output
{{ variable }}

# Statement (no output)
{% statement %}

# Comments
{# This is a comment #}

# Expressions
{{ 1 + 1 }}  # 2
{{ "tekst".upper() }}  # TEKST
```

**Common Pitfalls:**
- Missing spaces inside `{{ }}` can cause parsing errors
- Forgetting to close tags properly
- Mixing Python and Jinja2 syntax

**Performance Notes:**
- Templates are compiled and cached
- Simple expressions are faster than complex logic

### Variable Assignment

```yaml
{% set temp = states('sensor.temperatura_salon') | float %}
{% set is_warm = temp > 21 %}

{{ "Ciepło" if is_warm else "Zimno" }}
```

### Whitespace Control

```yaml
# Remove whitespace before
{{- variable }}

# Remove whitespace after
{{ variable -}}

# Both sides
{{- variable -}}
```

---

## Template Sensor Patterns

### Basic Template Sensor

**When to use:** Creating virtual sensors from other entities or calculations.

```yaml
template:
  - sensor:
      - name: "Temperatura Średnia"
        unique_id: temperatura_srednia_dom
        unit_of_measurement: "°C"
        device_class: temperature
        state_class: measurement
        state: >
          {% set salon = states('sensor.temperatura_salon') | float(0) %}
          {% set sypialnia = states('sensor.temperatura_sypialnia') | float(0) %}
          {% set kuchnia = states('sensor.temperatura_kuchnia') | float(0) %}
          {{ ((salon + sypialnia + kuchnia) / 3) | round(1) }}
```

**Common Pitfalls:**
- Not handling unavailable states (use default values)
- Missing unit_of_measurement for numeric sensors
- Forgetting device_class for proper dashboard display

**Performance Notes:**
- Template sensors update when referenced entities change
- Avoid excessive calculations in frequently updating sensors

### Template Sensor with Availability

**When to use:** Ensuring sensor only shows valid data when sources are available.

```yaml
template:
  - sensor:
      - name: "Wilgotność Średnia"
        unique_id: wilgotnosc_srednia
        unit_of_measurement: "%"
        device_class: humidity
        state: >
          {% set salon = states('sensor.wilgotnosc_salon') | float(0) %}
          {% set sypialnia = states('sensor.wilgotnosc_sypialnia') | float(0) %}
          {{ ((salon + sypialnia) / 2) | round(1) }}
        availability: >
          {{ states('sensor.wilgotnosc_salon') not in ['unavailable', 'unknown', 'none'] and
             states('sensor.wilgotnosc_sypialnia') not in ['unavailable', 'unknown', 'none'] }}
```

**Common Pitfalls:**
- Checking only for 'unavailable', missing 'unknown' and 'none'
- Not making sensor unavailable when calculation is invalid
- String comparison case sensitivity

**Performance Notes:**
- Availability template evaluates before state template
- Keep availability checks simple

### Binary Template Sensor

**When to use:** Creating virtual on/off sensors based on conditions.

```yaml
template:
  - binary_sensor:
      - name: "Dom Zajęty"
        unique_id: dom_zajety
        device_class: occupancy
        state: >
          {{ is_state('binary_sensor.czujnik_ruchu_salon', 'on') or
             is_state('binary_sensor.czujnik_ruchu_kuchnia', 'on') or
             is_state('light.salon_glowna', 'on') }}
        delay_off: "00:05:00"
```

**Common Pitfalls:**
- Forgetting delay_off for motion sensors (causes flickering)
- Not using device_class (affects icon and behavior)
- Complex logic causing frequent updates

**Performance Notes:**
- delay_off prevents rapid state changes
- Use is_state() instead of states() == for binary checks

### Template with Attributes

**When to use:** Adding custom attributes to template sensors.

```yaml
template:
  - sensor:
      - name: "Status Ogrzewania"
        unique_id: status_ogrzewania
        state: >
          {{ state_attr('climate.ogrzewanie', 'hvac_action') }}
        attributes:
          temperatura_aktualna: >
            {{ state_attr('climate.ogrzewanie', 'current_temperature') }}
          temperatura_zadana: >
            {{ state_attr('climate.ogrzewanie', 'temperature') }}
          tryb: >
            {{ states('climate.ogrzewanie') }}
          czas_pracy_dzisiaj: >
            {{ states('sensor.ogrzewanie_czas_dzisiaj') }}
```

**Common Pitfalls:**
- Attribute templates not updating independently
- Missing state_attr() default values
- Too many attributes causing performance issues

**Performance Notes:**
- Each attribute is a separate template evaluation
- Limit to essential attributes only

---

## Common Template Functions

### states() - Get Entity State

**When to use:** Retrieving current state of any entity.

```yaml
# Basic usage
{{ states('sensor.temperatura_salon') }}  # Returns: "21.5"

# With default value
{{ states('sensor.temperatura_salon') | float(0) }}  # Returns: 21.5 or 0

# All states of a domain
{{ states.sensor | map(attribute='entity_id') | list }}

# Count entities in state
{{ states.light | selectattr('state', 'eq', 'on') | list | count }}
```

**Common Pitfalls:**
- states() returns string, needs conversion for math
- Missing default values causes template errors
- Assuming entity exists without checking

**Performance Notes:**
- Very fast, cached operation
- Prefer states() over state_attr() when only state is needed

### state_attr() - Get Entity Attribute

**When to use:** Accessing entity attributes like brightness, temperature, etc.

```yaml
# Get attribute
{{ state_attr('light.salon_glowna', 'brightness') }}  # 0-255

# With default
{{ state_attr('light.salon_glowna', 'brightness') | int(0) }}

# Multiple attributes
{% set light = states.light.salon_glowna %}
{{ light.attributes.brightness }}  # Alternative syntax
{{ light.attributes.rgb_color }}  # [255, 128, 0]

# Check if attribute exists
{% if state_attr('light.salon_glowna', 'brightness') is not none %}
  Jasność: {{ state_attr('light.salon_glowna', 'brightness') }}
{% endif %}
```

**Common Pitfalls:**
- Attribute returns None if doesn't exist
- Different entities have different attributes
- Brightness range varies by integration

**Performance Notes:**
- Slightly slower than states()
- Cache attribute access if used multiple times

### is_state() - Check Entity State

**When to use:** Testing if entity is in specific state (cleaner than ==).

```yaml
# Basic check
{{ is_state('light.salon_glowna', 'on') }}  # true/false

# Multiple checks
{{ is_state('light.salon_glowna', 'on') and is_state('light.kuchnia', 'on') }}

# In conditions
{% if is_state('binary_sensor.czujnik_ruchu', 'on') %}
  Wykryto ruch
{% endif %}

# NOT recommended - using states()
{{ states('light.salon_glowna') == 'on' }}  # Works but less readable
```

**Common Pitfalls:**
- Case sensitive: 'On' != 'on'
- Returns false for unavailable entities
- Don't use for numeric comparisons

**Performance Notes:**
- Fastest way to check state
- Optimized internally

### is_state_attr() - Check Attribute Value

**When to use:** Testing if attribute matches specific value.

```yaml
# Check attribute value
{{ is_state_attr('climate.ogrzewanie', 'hvac_action', 'heating') }}

# Multiple conditions
{% if is_state_attr('climate.ogrzewanie', 'hvac_action', 'heating') and
      state_attr('climate.ogrzewanie', 'current_temperature') | float < 20 %}
  Ogrzewanie aktywne, ale zimno
{% endif %}
```

**Common Pitfalls:**
- Returns false if attribute doesn't exist
- Case sensitive comparisons
- Won't work for None values

**Performance Notes:**
- Efficient for single attribute checks
- Use state_attr() if you need the value for calculations

### has_value() - Check if Entity Has Valid Value

**When to use:** Checking if entity is available and has a valid state.

```yaml
# Check if sensor is available
{{ has_value('sensor.temperatura_salon') }}  # true/false

# Use in availability template
availability: >
  {{ has_value('sensor.temperatura_salon') and 
     has_value('sensor.temperatura_sypialnia') }}

# Filter available sensors
{{ states.sensor 
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | select('has_value')
   | list }}
```

**Common Pitfalls:**
- Doesn't validate if value is sensible, only that it exists
- Returns false for "unknown" and "unavailable"
- New in HA 2023.7, won't work in older versions

**Performance Notes:**
- Faster than checking multiple state strings
- Recommended for availability checks

---

## Date/Time Manipulation

### now() - Current Date/Time

**When to use:** Working with current date and time in templates.

```yaml
# Current timestamp
{{ now() }}  # 2026-02-18 14:30:00.123456+01:00

# Formatted time
{{ now().strftime('%H:%M') }}  # 14:30
{{ now().strftime('%d.%m.%Y') }}  # 18.02.2026

# Date components
{{ now().hour }}  # 14
{{ now().day }}  # 18
{{ now().month }}  # 2
{{ now().year }}  # 2026
{{ now().weekday() }}  # 0=Monday, 6=Sunday

# Check time ranges
{% if now().hour >= 6 and now().hour < 22 %}
  Dzień
{% else %}
  Noc
{% endif %}
```

**Common Pitfalls:**
- now() updates every minute, causing frequent template updates
- Timezone issues - now() uses HA timezone
- Using now() in availability checks (never use!)

**Performance Notes:**
- now() causes template to update every minute
- Use only when time-based updates are needed
- Consider trigger-based automations instead

### today_at() - Specific Time Today

**When to use:** Creating timestamps for specific times today.

```yaml
# Time today
{{ today_at('07:00') }}  # Today at 7:00 AM

# Check if time has passed
{{ now() > today_at('18:00') }}  # After 6 PM?

# Time until specific hour
{% set target = today_at('22:00') %}
{% set diff = target - now() %}
{{ diff.total_seconds() / 3600 }} godzin do 22:00
```

**Common Pitfalls:**
- Requires string in HH:MM format
- Returns datetime object, not string
- Timezone handling can be tricky

**Performance Notes:**
- More efficient than constructing datetime manually
- Updates every minute (uses now() internally)

### timedelta - Time Differences

**When to use:** Calculating time differences and offsets.

```yaml
# Add/subtract time
{{ now() + timedelta(hours=1) }}  # One hour from now
{{ now() - timedelta(days=1) }}  # Yesterday

# Last update time
{% set last = states.sensor.temperatura_salon.last_changed %}
{% set diff = now() - last %}
Zaktualizowano {{ diff.total_seconds() / 60 | round(0) }} minut temu

# Check if entity updated recently
{% set last = states.sensor.temperatura_salon.last_changed %}
{{ (now() - last) < timedelta(minutes=5) }}

# Complex time math
{% set start = today_at('06:00') %}
{% set end = today_at('22:00') %}
{% set duration = end - start %}
Dzień trwa {{ duration.total_seconds() / 3600 }} godzin
```

**Common Pitfalls:**
- Can't add/subtract timedeltas with strings
- Must convert to seconds for arithmetic
- Negative timedeltas can be confusing

**Performance Notes:**
- Efficient for time calculations
- Precompute static time differences

### strftime() - Format Date/Time

**When to use:** Converting datetime to readable strings.

```yaml
# Common formats
{{ now().strftime('%H:%M') }}  # 14:30
{{ now().strftime('%H:%M:%S') }}  # 14:30:45
{{ now().strftime('%d.%m.%Y') }}  # 18.02.2026
{{ now().strftime('%A, %d %B %Y') }}  # Tuesday, 18 February 2026

# Polish locale-friendly
{{ now().strftime('%d %B %Y, %H:%M') }}  # 18 February 2026, 14:30

# Last changed timestamp
{{ states.sensor.temperatura_salon.last_changed.strftime('%H:%M') }}

# Relative timestamps
{% set last = states.sensor.temperatura_salon.last_changed %}
Ostatnia aktualizacja: {{ last.strftime('%d.%m.%Y o %H:%M') }}
```

**Common Format Codes:**
- `%H` - Hour (00-23)
- `%M` - Minute (00-59)
- `%S` - Second (00-59)
- `%d` - Day (01-31)
- `%m` - Month (01-12)
- `%Y` - Year (2026)
- `%A` - Weekday name (Monday)
- `%B` - Month name (February)

**Common Pitfalls:**
- Locale might not support Polish month names
- 24-hour vs 12-hour format confusion
- Timezone not included in output

**Performance Notes:**
- Formatting is fast
- Cache formatted strings if used multiple times

### as_timestamp() - Convert to Unix Timestamp

**When to use:** Converting datetime to numeric timestamp for calculations.

```yaml
# Convert to timestamp
{{ as_timestamp(now()) }}  # 1708264200.123456

# Calculate duration in hours
{% set start = as_timestamp(states.sensor.ogrzewanie.last_changed) %}
{% set current = as_timestamp(now()) %}
{{ ((current - start) / 3600) | round(2) }} godzin

# Compare timestamps
{% set last = as_timestamp(states.sensor.temperatura_salon.last_changed) %}
{% set threshold = as_timestamp(now()) - 3600 %}  # 1 hour ago
{% if last > threshold %}
  Dane świeże
{% else %}
  Dane nieaktualne
{% endif %}
```

**Common Pitfalls:**
- Returns float (seconds with decimals)
- None for invalid dates
- Timezone affects the value

**Performance Notes:**
- Fast conversion
- Useful for performance-critical time math

---

## Math and Statistics

### Basic Math Operations

**When to use:** Performing calculations in templates.

```yaml
# Basic operations
{{ 10 + 5 }}  # 15
{{ 10 - 5 }}  # 5
{{ 10 * 5 }}  # 50
{{ 10 / 5 }}  # 2.0
{{ 10 // 3 }}  # 3 (integer division)
{{ 10 % 3 }}  # 1 (modulo)
{{ 2 ** 3 }}  # 8 (power)

# With sensors
{% set temp1 = states('sensor.temperatura_salon') | float(0) %}
{% set temp2 = states('sensor.temperatura_sypialnia') | float(0) %}
{{ temp1 + temp2 }}
```

**Common Pitfalls:**
- Division by zero causes errors
- Mixing int and float types
- Operator precedence (use parentheses)

**Performance Notes:**
- Native Python operations are very fast
- Float operations slightly slower than int

### round() - Rounding Numbers

**When to use:** Formatting numeric values to specific precision.

```yaml
# Round to integer
{{ 21.7 | round(0) }}  # 22

# Round to decimal places
{{ 21.6543 | round(2) }}  # 21.65

# Round with method
{{ 21.5 | round(0, 'floor') }}  # 21 (always down)
{{ 21.5 | round(0, 'ceil') }}  # 22 (always up)

# Temperature display
{% set temp = states('sensor.temperatura_salon') | float %}
{{ temp | round(1) }}°C
```

**Common Pitfalls:**
- Default rounding is "banker's rounding" (to even)
- round(0) returns float like 22.0, not int
- Negative precision rounds to tens, hundreds, etc.

**Performance Notes:**
- Very fast operation
- No performance difference between precision levels

### min() / max() - Find Extremes

**When to use:** Finding minimum or maximum values from multiple sensors.

```yaml
# Minimum temperature
{% set temps = [
  states('sensor.temperatura_salon') | float(0),
  states('sensor.temperatura_sypialnia') | float(0),
  states('sensor.temperatura_kuchnia') | float(0)
] %}
{{ temps | min }}  # Lowest temperature

# Maximum
{{ temps | max }}  # Highest temperature

# With entity filter
{% set all_temps = states.sensor 
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | map(attribute='state')
   | map('float')
   | list %}
Min: {{ all_temps | min }}°C
Max: {{ all_temps | max }}°C
```

**Common Pitfalls:**
- Empty lists cause errors
- String comparison vs numeric
- Unavailable sensors return strings

**Performance Notes:**
- O(n) operation, fast for small lists
- Filter unavailable entities first

### average (mean) - Calculate Average

**When to use:** Computing average values from multiple sensors.

```yaml
# Manual average
{% set temps = [
  states('sensor.temperatura_salon') | float(0),
  states('sensor.temperatura_sypialnia') | float(0),
  states('sensor.temperatura_kuchnia') | float(0)
] %}
{{ (temps | sum / temps | length) | round(1) }}

# Using expand() for groups
{% set temps = expand('group.temperatura_wszystkie')
   | map(attribute='state')
   | map('float', default=0)
   | list %}
{{ (temps | sum / temps | length) | round(1) }}°C

# Weighted average
{% set salon_weight = 2 %}
{% set sypialnia_weight = 1 %}
{% set weighted = 
  (states('sensor.temperatura_salon') | float(0) * salon_weight +
   states('sensor.temperatura_sypialnia') | float(0) * sypialnia_weight) /
  (salon_weight + sypialnia_weight) %}
{{ weighted | round(1) }}°C
```

**Common Pitfalls:**
- Division by zero with empty lists
- Including unavailable sensors (use filter)
- Not handling default values

**Performance Notes:**
- Two operations (sum + division) but still fast
- Consider using statistics sensor for historical averages

### sum() - Sum Values

**When to use:** Adding multiple sensor values together.

```yaml
# Sum of values
{% set values = [1, 2, 3, 4, 5] %}
{{ values | sum }}  # 15

# Total power consumption
{% set devices = [
  states('sensor.lodowka_moc') | float(0),
  states('sensor.pralka_moc') | float(0),
  states('sensor.komputer_moc') | float(0)
] %}
{{ values | sum | round(0) }} W

# Sum with filter
{% set total = states.sensor
   | selectattr('entity_id', 'match', '.*_moc$')
   | map(attribute='state')
   | map('float', default=0)
   | sum %}
Całkowite zużycie: {{ total | round(0) }} W
```

**Common Pitfalls:**
- Empty lists return 0 (usually safe)
- String concatenation vs numeric sum
- Missing float conversion

**Performance Notes:**
- O(n) operation, very fast
- Optimized in Jinja2

---

## List/Group Operations

### expand() - Expand Groups to Entities

**When to use:** Working with all entities in a group or area.

```yaml
# Expand group
{{ expand('group.wszystkie_swiatla') | map(attribute='entity_id') | list }}

# Count on lights
{{ expand('group.wszystkie_swiatla') | selectattr('state', 'eq', 'on') | list | count }}

# Get all temperatures
{% set temps = expand('group.czujniki_temperatury')
   | map(attribute='state')
   | map('float', default=0)
   | list %}
Średnia: {{ (temps | sum / temps | length) | round(1) }}°C

# Expand multiple groups
{{ expand('group.salon', 'group.sypialnia') | list }}

# Expand area
{{ expand(area_entities('salon')) | selectattr('state', 'eq', 'on') | list }}
```

**Common Pitfalls:**
- expand() returns generator, needs | list for multiple operations
- Empty groups return empty list (safe)
- Device entities not included, only entities

**Performance Notes:**
- Fast operation, internally optimized
- Prefer expand() over manual entity lists

### selectattr() - Filter by Attribute

**When to use:** Filtering entities based on attribute values.

```yaml
# Select lights that are on
{{ states.light | selectattr('state', 'eq', 'on') | list }}

# Select sensors with value > 20
{{ states.sensor 
   | selectattr('state', 'is_number')
   | selectattr('state', '>', '20')
   | list }}

# Select by attribute existence
{{ states.light 
   | selectattr('attributes.brightness', 'defined')
   | list }}

# Complex filter - bright lights
{% set bright_lights = states.light
   | selectattr('state', 'eq', 'on')
   | selectattr('attributes.brightness', 'defined')
   | selectattr('attributes.brightness', '>', 200)
   | map(attribute='name')
   | list %}
Jasne światła: {{ bright_lights | join(', ') }}
```

**Common Pitfalls:**
- Attribute paths use dot notation: 'attributes.brightness'
- String comparison for numbers
- Missing attributes cause filter to exclude entity

**Performance Notes:**
- Efficient filtering, early exit
- Chain multiple selectattr() for AND conditions

### map() - Transform Values

**When to use:** Extracting or transforming values from entity lists.

```yaml
# Extract entity IDs
{{ states.light | map(attribute='entity_id') | list }}

# Extract states
{{ states.sensor | map(attribute='state') | list }}

# Convert to float
{{ states.sensor 
   | map(attribute='state')
   | map('float', default=0)
   | list }}

# Extract names
{{ expand('group.wszystkie_swiatla') | map(attribute='name') | list }}

# Custom transformation
{{ [1, 2, 3, 4, 5] | map('*', 2) | list }}  # [2, 4, 6, 8, 10]
```

**Common Pitfalls:**
- map() returns generator, needs | list
- Wrong attribute names return None
- Type conversion errors with invalid values

**Performance Notes:**
- Lazy evaluation until | list
- Very efficient for large lists

### reject() / rejectattr() - Exclude Items

**When to use:** Filtering out unwanted entities or values.

```yaml
# Reject lights that are off
{{ states.light | rejectattr('state', 'eq', 'off') | list }}

# Reject unavailable sensors
{{ states.sensor 
   | rejectattr('state', 'in', ['unavailable', 'unknown'])
   | list }}

# Reject specific values
{{ [1, 2, 3, 4, 5] | reject('eq', 3) | list }}  # [1, 2, 4, 5]

# Get available temperature sensors
{% set temps = states.sensor
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | rejectattr('state', 'in', ['unavailable', 'unknown', 'none'])
   | map(attribute='state')
   | map('float')
   | list %}
```

**Common Pitfalls:**
- Opposite of select, can be confusing
- Same performance characteristics as select
- Chain carefully to avoid excluding too much

**Performance Notes:**
- Same as selectattr()
- Use whichever is more readable

### join() - Concatenate Strings

**When to use:** Creating comma-separated or formatted lists.

```yaml
# Simple join
{{ ['Salon', 'Sypialnia', 'Kuchnia'] | join(', ') }}
# Output: Salon, Sypialnia, Kuchnia

# Join entity names
{{ expand('group.wszystkie_swiatla') 
   | selectattr('state', 'eq', 'on')
   | map(attribute='name')
   | list
   | join(', ') }}

# Join with newlines
{{ states.light 
   | map(attribute='entity_id')
   | join('\n') }}

# Custom separator
{{ ['item1', 'item2', 'item3'] | join(' | ') }}
```

**Common Pitfalls:**
- Only works with strings (convert first)
- Empty lists return empty string
- Newlines need proper YAML quoting

**Performance Notes:**
- Fast string operation
- Large lists can create long strings

### sort() - Sort Lists

**When to use:** Ordering entities or values.

```yaml
# Sort alphabetically
{{ ['Kuchnia', 'Salon', 'Sypialnia'] | sort }}

# Sort numbers
{{ [3, 1, 4, 1, 5, 9, 2, 6] | sort }}

# Sort entities by state
{{ states.sensor 
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | sort(attribute='state')
   | map(attribute='entity_id')
   | list }}

# Sort descending
{{ [1, 2, 3, 4, 5] | sort(reverse=true) }}
```

**Common Pitfalls:**
- Sorting strings vs numbers differs
- Case-sensitive sorting
- Unavailable entities sort differently

**Performance Notes:**
- O(n log n) but fast in practice
- Sort once, reuse result

---

## Conditional Formatting

### if-then-else Expressions

**When to use:** Simple conditional value selection.

```yaml
# Basic ternary
{{ "Ciepło" if temp > 21 else "Zimno" }}

# With sensor state
{{ "Włączone" if is_state('light.salon_glowna', 'on') else "Wyłączone" }}

# Nested conditions
{{ "Gorąco" if temp > 25 else ("Ciepło" if temp > 20 else "Zimno") }}

# Boolean result
{{ temp > 21 }}  # true/false
```

**Common Pitfalls:**
- Parentheses needed for nested conditions
- Both branches evaluate (no short-circuit)
- Can get unreadable when deeply nested

**Performance Notes:**
- Very fast evaluation
- Prefer for simple conditions

### if-elif-else Statements

**When to use:** Complex multi-branch logic.

```yaml
{% set temp = states('sensor.temperatura_salon') | float(0) %}
{% if temp > 25 %}
  Bardzo ciepło
{% elif temp > 20 %}
  Ciepło
{% elif temp > 15 %}
  Umiarkowanie
{% else %}
  Zimno
{% endif %}

# With multiple conditions
{% set temp = states('sensor.temperatura_salon') | float(0) %}
{% set humidity = states('sensor.wilgotnosc_salon') | float(0) %}
{% if temp > 25 and humidity > 60 %}
  Gorąco i wilgotno
{% elif temp > 25 %}
  Gorąco
{% elif humidity > 60 %}
  Wilgotno
{% else %}
  Komfortowo
{% endif %}
```

**Common Pitfalls:**
- Forgetting {% endif %}
- Wrong indentation (doesn't matter but aids reading)
- Complex conditions becoming unreadable

**Performance Notes:**
- Short-circuits (stops at first match)
- Efficient for multiple conditions

### Logical Operators

**When to use:** Combining multiple conditions.

```yaml
# AND
{% if temp > 20 and humidity < 60 %}
  Komfortowo
{% endif %}

# OR
{% if is_state('binary_sensor.czujnik_ruchu_salon', 'on') or
      is_state('binary_sensor.czujnik_ruchu_kuchnia', 'on') %}
  Ruch wykryty
{% endif %}

# NOT
{% if not is_state('light.salon_glowna', 'on') %}
  Światło wyłączone
{% endif %}

# Complex combinations
{% if (temp > 20 and temp < 25) and 
      (humidity > 40 and humidity < 60) and
      not is_state('climate.ogrzewanie', 'heating') %}
  Optymalne warunki
{% endif %}
```

**Common Pitfalls:**
- and/or must be lowercase
- Use parentheses for clarity
- Short-circuit evaluation matters for performance

**Performance Notes:**
- and/or short-circuit (stop at first decisive result)
- Order conditions by likelihood

### is Tests

**When to use:** Testing value types and properties.

```yaml
# Number check
{% if states('sensor.temperatura_salon') is number %}
  {{ states('sensor.temperatura_salon') | float }}°C
{% else %}
  Niedostępne
{% endif %}

# None check
{% if state_attr('light.salon_glowna', 'brightness') is not none %}
  Jasność: {{ state_attr('light.salon_glowna', 'brightness') }}
{% endif %}

# Defined check
{% if my_variable is defined %}
  {{ my_variable }}
{% endif %}

# String check
{% if states('sensor.status') is string %}
  Status: {{ states('sensor.status') }}
{% endif %}

# In check
{% if states('sensor.pogoda') in ['sunny', 'cloudy'] %}
  Bez deszczu
{% endif %}
```

**Common Pitfalls:**
- `is number` returns true for numeric strings
- `is defined` checks variable existence, not entity
- `is none` vs `== none`

**Performance Notes:**
- Type checks are very fast
- Prefer over try-catch patterns

### Default Values

**When to use:** Handling missing or invalid values gracefully.

```yaml
# Filter with default
{{ states('sensor.temperatura_salon') | float(20) }}

# Multiple filters
{{ states('sensor.wilgotnosc_salon') | float(0) | round(1) }}

# Default for attributes
{{ state_attr('light.salon_glowna', 'brightness') | int(0) }}

# Default for None
{{ my_variable | default('Brak danych') }}

# Default for empty strings
{{ states('sensor.status') | default('Nieznany', true) }}
```

**Common Pitfalls:**
- Default only applies to undefined/None
- Empty string is not None
- Order matters: default should be first

**Performance Notes:**
- No performance impact
- Always prefer defaults to if-else

---

## Template Debugging

### Developer Tools Template Editor

**When to use:** Testing and debugging templates interactively.

**Steps:**
1. Open Developer Tools > Template
2. Write template in left pane
3. See live results in right pane
4. Check for errors in red

```yaml
# Test template
{{ states('sensor.temperatura_salon') | float(0) }}

# Debug with set
{% set temp = states('sensor.temperatura_salon') | float(0) %}
{% set status = "Ciepło" if temp > 21 else "Zimno" %}
Temperatura: {{ temp }}°C
Status: {{ status }}

# List all entities
{{ states | map(attribute='entity_id') | list }}
```

**Common Pitfalls:**
- Template editor doesn't show availability status
- Updates may be delayed
- Doesn't support multi-line YAML

**Performance Notes:**
- Real-time evaluation
- Safe to test expensive templates

### Logging Template Values

**When to use:** Debugging templates in automations and scripts.

```yaml
# In automation
action:
  - service: system_log.write
    data:
      message: >
        Temperatura: {{ states('sensor.temperatura_salon') }}
        Wilgotność: {{ states('sensor.wilgotnosc_salon') }}
      level: warning

# In template sensor with custom attribute
template:
  - sensor:
      - name: "Debug Sensor"
        state: "OK"
        attributes:
          debug_temp: >
            {{ states('sensor.temperatura_salon') }}
          debug_calc: >
            {% set t = states('sensor.temperatura_salon') | float(0) %}
            {{ t * 1.8 + 32 }}
```

**Common Pitfalls:**
- Logs fill up quickly with frequent updates
- Use warning/error level sparingly
- Remove debug logging in production

**Performance Notes:**
- Logging has minimal impact
- Avoid in high-frequency templates

### Common Error Messages

**When to use:** Understanding what went wrong.

```yaml
# UndefinedError: 'None' has no attribute 'state'
# Cause: Entity doesn't exist
# Fix: Check entity_id spelling

# ValueError: could not convert string to float: 'unavailable'
# Cause: Missing default value in float()
# Fix: {{ states('sensor.temp') | float(0) }}

# TemplateError: Must provide a default value
# Cause: Entity unavailable, no default
# Fix: Add default to all conversions

# TemplateError: No test named 'is_number'
# Cause: Using Python function in Jinja2
# Fix: Use Jinja2 'is number' instead
```

**Common Pitfalls:**
- Error messages can be cryptic
- Line numbers not always accurate
- Errors break entire template

**Performance Notes:**
- Template errors disable entire sensor
- Test thoroughly before deploying

### Testing Availability

**When to use:** Ensuring templates handle unavailable entities.

```yaml
# Test by making entity unavailable
# Then check template behavior

# Good - handles unavailable
{% set temp = states('sensor.temperatura_salon') | float(0) %}
{{ temp | round(1) }}

# Bad - breaks on unavailable
{% set temp = states('sensor.temperatura_salon') | float %}
{{ temp | round(1) }}  # Error if unavailable

# Test availability check
{% if has_value('sensor.temperatura_salon') %}
  {{ states('sensor.temperatura_salon') }}
{% else %}
  Niedostępny
{% endif %}
```

**Common Pitfalls:**
- Forgetting to test unavailable state
- Assumptions about entity existence
- Not testing after restarts

**Performance Notes:**
- Availability checks prevent errors
- Minimal performance cost

---

## Polish Language Considerations

### Entity Naming Conventions

**When to use:** Creating Polish-friendly entity names.

```yaml
# Good Polish names
sensor:
  - platform: template
    sensors:
      temperatura_salon:
        friendly_name: "Temperatura - Salon"
      
      wilgotnosc_sypialnia:
        friendly_name: "Wilgotność - Sypialnia"
      
      moc_lodowka:
        friendly_name: "Lodówka - Moc"

# Avoid special characters in entity_id
# Bad: sensor.température_salon (accented)
# Good: sensor.temperatura_salon

# Use friendly_name for display
binary_sensor:
  - platform: template
    sensors:
      czujnik_ruchu_lazienka:
        friendly_name: "Czujnik ruchu - Łazienka"  # Polish characters OK here
```

**Common Pitfalls:**
- Entity IDs can't have Polish characters (ą, ć, ę, etc.)
- Use underscores, not spaces in entity_id
- Friendly names can have any characters

**Performance Notes:**
- No performance difference
- Consistency aids maintenance

### Polish Date/Time Formatting

**When to use:** Displaying dates and times in Polish format.

```yaml
# Polish date format: DD.MM.YYYY
{{ now().strftime('%d.%m.%Y') }}  # 18.02.2026

# Polish time format: HH:MM
{{ now().strftime('%H:%M') }}  # 14:30

# Full Polish datetime
{{ now().strftime('%d.%m.%Y o godzinie %H:%M') }}
# 18.02.2026 o godzinie 14:30

# Polish weekday names (manual)
{% set days = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'] %}
{{ days[now().weekday()] }}, {{ now().strftime('%d.%m.%Y') }}
# Wtorek, 18.02.2026

# Polish month names (manual)
{% set months = ['stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
                 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'] %}
{{ now().day }} {{ months[now().month - 1] }} {{ now().year }}
# 18 lutego 2026
```

**Common Pitfalls:**
- strftime() uses English month names
- Weekday numbering: 0=Monday
- Array indexing: month - 1

**Performance Notes:**
- String operations are fast
- Consider storing translations in input_select

### Polish Number Formatting

**When to use:** Formatting numbers according to Polish conventions.

```yaml
# Polish decimal separator (comma, not period)
# Note: HA always uses period internally
{% set temp = states('sensor.temperatura_salon') | float(0) %}
{{ temp | round(1) | string | replace('.', ',') }}°C
# 21,5°C instead of 21.5°C

# Thousands separator (space)
{% set power = 1234567 %}
{{ "{:,}".format(power) | replace(',', ' ') }} W
# 1 234 567 W

# Currency formatting (PLN)
{% set price = states('sensor.cena_pradu') | float(0) %}
{{ price | round(2) | string | replace('.', ',') }} zł
# 0,65 zł
```

**Common Pitfalls:**
- Dashboard may not support comma separator
- Replace only at display time
- Keep internal calculations with period

**Performance Notes:**
- String replacement is fast
- Do formatting at final display only

### Polish State Translations

**When to use:** Translating entity states to Polish.

```yaml
# Manual translations
{% set state_pl = {
  'on': 'włączony',
  'off': 'wyłączony',
  'open': 'otwarty',
  'closed': 'zamknięty',
  'home': 'w domu',
  'away': 'poza domem',
  'heating': 'ogrzewanie',
  'cooling': 'chłodzenie',
  'idle': 'bezczynny'
} %}

{% set state = states('light.salon_glowna') %}
{{ state_pl.get(state, state) }}

# Climate action translation
{% set action = state_attr('climate.ogrzewanie', 'hvac_action') %}
{% set action_pl = {
  'heating': 'grzeje',
  'cooling': 'chłodzi',
  'idle': 'bezczynny',
  'off': 'wyłączony'
} %}
Status: {{ action_pl.get(action, action) }}
```

**Common Pitfalls:**
- HA has built-in translations (check settings)
- Maintain consistency across templates
- Update dictionary when adding states

**Performance Notes:**
- Dictionary lookup is O(1)
- Define once, reuse across templates

---

## Performance Optimization

### Avoid Expensive Operations

**When to use:** Optimizing frequently updating templates.

```yaml
# Bad - calls now() multiple times
{% if now().hour >= 6 %}
  Dzień ({{ now().hour }}:{{ now().minute }})
{% endif %}

# Good - call once, reuse
{% set time = now() %}
{% if time.hour >= 6 %}
  Dzień ({{ time.strftime('%H:%M') }})
{% endif %}

# Bad - repeated state lookups
{% if states('sensor.temp') | float > 20 %}
  {{ states('sensor.temp') }}°C to ciepło
{% endif %}

# Good - lookup once
{% set temp = states('sensor.temp') | float(0) %}
{% if temp > 20 %}
  {{ temp }}°C to ciepło
{% endif %}
```

**Common Pitfalls:**
- Premature optimization
- Optimizing templates that rarely run
- Sacrificing readability for minor gains

**Performance Notes:**
- Single lookups: ~0.1ms
- Multiple lookups add up
- Optimize hot paths only

### Limit Template Updates

**When to use:** Reducing unnecessary template evaluations.

```yaml
# Bad - updates every minute (uses now())
sensor:
  - platform: template
    sensors:
      time_dependent:
        value_template: >
          {% if now().hour >= 6 %}
            Dzień
          {% else %}
            Noc
          {% endif %}

# Good - updates only when needed (trigger-based)
trigger:
  - platform: time
    at: "06:00:00"
  - platform: time
    at: "22:00:00"
sensor:
  - platform: template
    sensors:
      time_dependent:
        value_template: >
          {% if now().hour >= 6 %}
            Dzień
          {% else %}
            Noc
          {% endif %}

# Alternative - automation that sets input_select
```

**Common Pitfalls:**
- Using now() causes updates every minute
- Excessive logging
- Large group expansions

**Performance Notes:**
- Template sensors: ~1ms evaluation
- Multiply by update frequency
- 60 updates/hour = minimal impact

### Cache Complex Calculations

**When to use:** Storing results of expensive operations.

```yaml
# Bad - recalculates every time
{% set all_temps = states.sensor 
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | rejectattr('state', 'in', ['unavailable', 'unknown'])
   | map(attribute='state')
   | map('float')
   | list %}
Min: {{ all_temps | min }}
Max: {{ all_temps | max }}
Avg: {{ (all_temps | sum / all_temps | length) | round(1) }}

# Good - calculate once
{% set all_temps = states.sensor 
   | selectattr('entity_id', 'match', 'temperatura_.*')
   | rejectattr('state', 'in', ['unavailable', 'unknown'])
   | map(attribute='state')
   | map('float')
   | list %}
{% set temp_min = all_temps | min %}
{% set temp_max = all_temps | max %}
{% set temp_avg = (all_temps | sum / all_temps | length) | round(1) %}
Min: {{ temp_min }}, Max: {{ temp_max }}, Avg: {{ temp_avg }}
```

**Common Pitfalls:**
- Over-caching (premature optimization)
- Stale cache in long-running templates
- Memory usage with large cached values

**Performance Notes:**
- Set operations: ~0.1ms
- List operations: ~0.5ms per 100 items
- Cache when used 3+ times

### Use Efficient Filters

**When to use:** Choosing the right filter for the job.

```yaml
# Bad - checking all lights
{% for light in states.light %}
  {% if light.state == 'on' %}
    {{ light.name }}
  {% endif %}
{% endfor %}

# Good - filter first
{{ states.light 
   | selectattr('state', 'eq', 'on')
   | map(attribute='name')
   | list }}

# Bad - manual counting
{% set count = 0 %}
{% for light in states.light %}
  {% if light.state == 'on' %}
    {% set count = count + 1 %}
  {% endif %}
{% endfor %}

# Good - use count
{{ states.light | selectattr('state', 'eq', 'on') | list | count }}
```

**Common Pitfalls:**
- Using loops instead of filters
- Not using | list when needed
- Filtering after mapping

**Performance Notes:**
- Filters: O(n), optimized in C
- Loops: O(n), interpreted
- Filters are 5-10x faster

### Monitor Template Performance

**When to use:** Identifying slow templates.

```yaml
# Check template execution time in logs
# Enable: logger:
#   logs:
#     homeassistant.helpers.template: debug

# Look for warnings:
# "Template variable warning: 'dict object' has no attribute 'state'"
# "Template rendering exceeded 10 milliseconds"

# Profile templates
{% set start = now() %}
{# Your template here #}
{% set end = now() %}
{{ (end - start).total_seconds() * 1000 }} ms
```

**Common Pitfalls:**
- Ignoring performance warnings
- Complex templates in high-frequency sensors
- Not profiling before optimization

**Performance Notes:**
- Target: <10ms per template
- Warning threshold: 10ms
- Critical threshold: 100ms

### Best Practices Summary

1. **Always provide defaults** - prevents template errors
2. **Use has_value()** - check entity availability
3. **Cache repeated lookups** - store in variables
4. **Avoid now() when possible** - causes frequent updates
5. **Use filters over loops** - 5-10x faster
6. **Test with unavailable entities** - ensure graceful degradation
7. **Profile slow templates** - enable debug logging
8. **Use trigger-based templates** - reduce unnecessary updates
9. **Keep templates simple** - readability > optimization
10. **Use expand() for groups** - cleaner than manual lists

---

## Quick Reference

### Essential Functions
- `states('entity_id')` - Get entity state (string)
- `state_attr('entity_id', 'attribute')` - Get attribute
- `is_state('entity_id', 'state')` - Check state (boolean)
- `has_value('entity_id')` - Check if available (boolean)
- `now()` - Current datetime
- `expand('group.name')` - Expand group to entities

### Essential Filters
- `| float(default)` - Convert to float
- `| int(default)` - Convert to integer
- `| round(precision)` - Round number
- `| default(value)` - Default if None/undefined
- `| list` - Convert generator to list
- `| join(separator)` - Join list to string

### Essential Tests
- `is number` - Is numeric
- `is defined` - Variable exists
- `is none` - Is None
- `in [list]` - Is in list

---

**Version:** 1.0  
**Author:** Home Assistant Expert  
**Last Updated:** 2026-02-18
