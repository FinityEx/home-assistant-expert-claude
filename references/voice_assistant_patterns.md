# Voice Assistant Patterns for Home Assistant (2026)

Complete guide for implementing voice assistants in Home Assistant using the Assist pipeline, Wyoming protocol, and ESPHome voice satellites. Special focus on Polish language support and M5Stack hardware.

## Table of Contents

1. [Assist Pipeline Overview](#assist-pipeline-overview)
2. [Wyoming Protocol Setup](#wyoming-protocol-setup)
3. [Speech-to-Text (STT) Configuration](#speech-to-text-stt-configuration)
4. [Text-to-Speech (TTS) Configuration](#text-to-speech-tts-configuration)
5. [Conversation Agents](#conversation-agents)
6. [Wake Word Detection](#wake-word-detection)
7. [ESPHome Voice Satellites](#esphome-voice-satellites)
8. [Intent Handling](#intent-handling)
9. [Multi-Room Setup](#multi-room-setup)
10. [Error Handling & Fallbacks](#error-handling--fallbacks)

---

## Assist Pipeline Overview

The Assist pipeline (2026) consists of five main stages:

```
Wake Word → STT → Conversation Agent → TTS → Audio Output
```

### Complete Pipeline Configuration

```yaml
# configuration.yaml
assist_pipeline:
  pipelines:
    - name: "Polish Voice Assistant"
      language: "pl"
      wake_word: "ok_nabu"
      stt_engine: "faster_whisper"
      stt_language: "pl"
      conversation_agent: "conversation.home_assistant"
      tts_engine: "google_translate"
      tts_language: "pl"
      tts_voice: "pl-PL-Wavenet-A"
      
    - name: "Cloud Polish Assistant"
      language: "pl"
      wake_word: "alexa"
      stt_engine: "cloud.openai_whisper"
      stt_language: "pl"
      conversation_agent: "conversation.openai_gpt4"
      tts_engine: "azure_tts"
      tts_language: "pl-PL"
      tts_voice: "pl-PL-ZofiaNeural"
      
    - name: "English Assistant"
      language: "en"
      wake_word: "hey_jarvis"
      stt_engine: "faster_whisper"
      stt_language: "en"
      conversation_agent: "conversation.extended_openai"
      tts_engine: "piper"
      tts_language: "en_US"
      tts_voice: "en_US-lessac-medium"
```

### Pipeline Features (2026)

- **Context Awareness**: Pipelines remember conversation context for 5 minutes
- **Multi-language Support**: Automatic language detection
- **Fallback Chains**: Multiple STT/TTS options with automatic failover
- **Pipeline Switching**: Voice command to switch between pipelines
- **Device-specific Pipelines**: Different pipelines per satellite

---

## Wyoming Protocol Setup

Wyoming is the protocol for connecting STT, TTS, and wake word services to Home Assistant.

### Installing Wyoming Add-ons

```yaml
# supervisor/add-on configurations
# Install these from Home Assistant Add-on Store:
# 1. Whisper (STT)
# 2. Piper (TTS)
# 3. openWakeWord
```

### Whisper Add-on Configuration

```yaml
# Whisper Add-on config
model: "base"  # Options: tiny, base, small, medium, large
language: "pl"  # Polish language support
beam_size: 5
best_of: 5
temperature: 0.0
```

### Piper Add-on Configuration

```yaml
# Piper Add-on config
voice: "pl_PL-mls_6892-low"  # Polish voice
length_scale: 1.0
noise_scale: 0.667
noise_w: 0.8
speaker: 0  # For multi-speaker models
```

### openWakeWord Add-on Configuration

```yaml
# openWakeWord Add-on config
models:
  - "ok_nabu"
  - "hey_jarvis"
  - "alexa"
threshold: 0.5
trigger_level: 1
refractory_period: 2.0
```

### Wyoming Integration Setup

```yaml
# configuration.yaml
wyoming:
  stt:
    - host: "localhost"
      port: 10300
      protocol: "faster_whisper"
      
  tts:
    - host: "localhost"
      port: 10200
      protocol: "piper"
      
  wake:
    - host: "localhost"
      port: 10400
      protocol: "openwakeword"
```

---

## Speech-to-Text (STT) Configuration

### Local STT Options

#### Faster-Whisper (Recommended for Polish)

```yaml
# configuration.yaml
stt:
  - platform: faster_whisper
    model: "medium"  # Better Polish accuracy
    language: "pl"
    device: "cpu"  # or "cuda" for GPU
    compute_type: "int8"
    beam_size: 5
    vad_filter: true
    vad_threshold: 0.5
```

**Wyoming Container Setup:**

```yaml
# docker-compose.yml
services:
  faster-whisper:
    image: rhasspy/wyoming-faster-whisper:latest
    ports:
      - "10300:10300"
    volumes:
      - ./whisper-data:/data
    environment:
      - MODEL=medium
      - LANGUAGE=pl
      - BEAM_SIZE=5
    restart: unless-stopped
```

#### Whisper.cpp (Lower Resource Usage)

```yaml
# configuration.yaml
stt:
  - platform: whisper_cpp
    model: "base"
    language: "pl"
    threads: 4
```

#### Vosk (Offline, Fast)

```yaml
stt:
  - platform: vosk
    model_path: "/config/vosk-model-pl-0.22"
    language: "pl"
```

### Cloud STT Options

#### OpenAI Whisper API (Best Accuracy)

```yaml
# configuration.yaml
openai_whisper:
  api_key: !secret openai_api_key
  model: "whisper-1"
  language: "pl"
  temperature: 0
  
stt:
  - platform: openai_whisper
    language: "pl"
```

#### Google Cloud Speech-to-Text

```yaml
google_cloud_stt:
  api_key: !secret google_cloud_api_key
  
stt:
  - platform: google_cloud
    language: "pl-PL"
    model: "latest_long"
    use_enhanced: true
    encoding: "LINEAR16"
    sample_rate: 16000
```

#### Azure Speech Services

```yaml
azure_stt:
  subscription_key: !secret azure_speech_key
  region: "westeurope"
  
stt:
  - platform: azure
    language: "pl-PL"
    recognition_mode: "interactive"
    profanity: "masked"
```

---

## Text-to-Speech (TTS) Configuration

### Polish TTS Options

#### Piper (Local, High Quality)

```yaml
# configuration.yaml
tts:
  - platform: piper
    voice: "pl_PL-mls_6892-low"  # Low quality, fast
    # voice: "pl_PL-mls_6892-medium"  # Better quality
    # voice: "pl_PL-darkman-medium"  # Alternative voice
```

**Available Polish Piper Voices (2026):**

```yaml
# Low quality (fast)
- pl_PL-mls_6892-low
- pl_PL-darkman-low

# Medium quality (recommended)
- pl_PL-mls_6892-medium
- pl_PL-darkman-medium
- pl_PL-gosia-medium

# High quality (slower)
- pl_PL-mls_6892-high
```

#### Google Translate TTS (Free, Simple)

```yaml
tts:
  - platform: google_translate
    language: "pl"
    base_url: "https://translate.google.com"
```

#### Google Cloud TTS (Best Polish Voices)

```yaml
google_cloud_tts:
  api_key: !secret google_cloud_api_key
  
tts:
  - platform: google_cloud
    language: "pl-PL"
    voice: "pl-PL-Wavenet-A"  # Female
    # voice: "pl-PL-Wavenet-B"  # Male
    # voice: "pl-PL-Wavenet-C"  # Female
    # voice: "pl-PL-Wavenet-D"  # Male
    # voice: "pl-PL-Wavenet-E"  # Female
    # voice: "pl-PL-Standard-A"  # Female (free tier)
    audio_encoding: "MP3"
    speaking_rate: 1.0
    pitch: 0.0
```

#### Azure TTS (Neural Polish Voices)

```yaml
azure_tts:
  subscription_key: !secret azure_speech_key
  region: "westeurope"
  
tts:
  - platform: azure
    language: "pl-PL"
    voice: "pl-PL-ZofiaNeural"  # Female, modern
    # voice: "pl-PL-MarekNeural"  # Male, modern
    # voice: "pl-PL-AgnieszkaNeural"  # Female
    style: "general"
    rate: 1.0
    pitch: 0
```

---

## Conversation Agents

### Home Assistant Built-in Agent

```yaml
# configuration.yaml
conversation:
  intents:
    TurnOnLight:
      - "włącz światło w {area}"
      - "zapal światło w {area}"
    TurnOffLight:
      - "wyłącz światło w {area}"
      - "zgaś światło w {area}"
    SetTemperature:
      - "ustaw temperaturę na {temperature} stopni"
      - "temperatura {temperature} stopni"
```

### OpenAI Conversation Agent

```yaml
# configuration.yaml
openai_conversation:
  api_key: !secret openai_api_key
  model: "gpt-4-turbo"  # or gpt-4, gpt-3.5-turbo
  temperature: 0.7
  max_tokens: 150
  
  system_prompt: >
    You are a helpful voice assistant for a Polish smart home.
    You can control lights, climate, covers, and provide information.
    Always respond in Polish. Be concise and natural.
    
  functions:
    - type: "script"
      script: "script.turn_on_lights"
    - type: "service"
      domain: "light"
```

### Google Generative AI (Gemini)

```yaml
google_generative_ai:
  api_key: !secret google_ai_api_key
  model: "gemini-pro"
  temperature: 0.9
  top_p: 1.0
  top_k: 32
  
  system_instruction: >
    Jesteś asystentem głosowym dla polskiego inteligentnego domu.
    Możesz kontrolować urządzenia i udzielać informacji.
    Odpowiadaj zwięźle po polsku.
```

### Local LLM via Ollama

```yaml
# configuration.yaml
ollama:
  host: "localhost"
  port: 11434
  
conversation:
  platform: ollama
  model: "llama2:13b"  # or mistral, neural-chat
  temperature: 0.7
  
  system_prompt: >
    You are a Polish smart home voice assistant.
    Control devices and provide concise responses in Polish.
```

**Ollama Container Setup:**

```yaml
# docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ./ollama-data:/root/.ollama
    restart: unless-stopped
```

### Extended OpenAI (with Tools)

```yaml
# configuration.yaml
extended_openai:
  api_key: !secret openai_api_key
  model: "gpt-4-turbo"
  
  tools:
    - name: "get_weather"
      function: "weather.get_forecasts"
    - name: "control_lights"
      function: "script.control_room_lights"
    - name: "set_scene"
      function: "scene.turn_on"
      
  context_entities:
    - "sensor.outdoor_temperature"
    - "sun.sun"
    - "person.home_owner"
```

---

## Wake Word Detection

### openWakeWord (Recommended 2026)

```yaml
# configuration.yaml
wake_word:
  - platform: openwakeword
    models:
      - "ok_nabu"  # Built-in
      - "hey_jarvis"  # Built-in
      - "alexa"  # Built-in
    threshold: 0.5
    trigger_level: 1
    refractory_period: 2.0
```

### microWakeWord (ESP32 On-device)

```yaml
# ESPHome configuration
micro_wake_word:
  models:
    - model: "ok_nabu"
      probability_cutoff: 0.5
    - model: "hey_jarvis"
      probability_cutoff: 0.5
  
  on_wake_word_detected:
    - voice_assistant.start:
        wake_word: !lambda 'return wake_word;'
```

### Custom Wake Words

```yaml
# Train custom wake word with openWakeWord
# Use openWakeWord Studio: https://github.com/dscripka/openWakeWord

wake_word:
  - platform: openwakeword
    custom_model_path: "/config/custom_wake_words"
    models:
      - "hej_asystent"  # Custom Polish wake word
    threshold: 0.6
```

---

## ESPHome Voice Satellites

### M5Stack Atom Echo (User's Primary Device)

```yaml
# atom_echo.yaml
substitutions:
  name: "atom-echo-kitchen"
  friendly_name: "Kitchen Voice Assistant"

esphome:
  name: ${name}
  friendly_name: ${friendly_name}
  platformio_options:
    board_build.flash_mode: dio
  on_boot:
    - light.turn_on:
        id: led
        red: 0%
        green: 100%
        blue: 0%
        brightness: 50%

esp32:
  board: m5stack-atom
  framework:
    type: arduino

# WiFi configuration
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  
  ap:
    ssid: "${name} Fallback"
    password: !secret ap_password

# Enable logging
logger:
  level: INFO

# Enable Home Assistant API
api:
  encryption:
    key: !secret api_key

ota:
  password: !secret ota_password

# I2S Audio
i2s_audio:
  - id: i2s_audio_bus
    i2s_lrclk_pin: GPIO33
    i2s_bclk_pin: GPIO19

# Microphone
microphone:
  - platform: i2s_audio
    id: atom_echo_microphone
    adc_type: external
    i2s_din_pin: GPIO23
    pdm: true
    channel: left
    sample_rate: 16000
    bits_per_sample: 16bit

# Speaker
speaker:
  - platform: i2s_audio
    id: atom_echo_speaker
    dac_type: external
    i2s_dout_pin: GPIO22
    mode: mono
    sample_rate: 16000
    bits_per_sample: 16bit

# Voice Assistant
voice_assistant:
  id: va
  microphone: atom_echo_microphone
  speaker: atom_echo_speaker
  
  # Use on-device wake word (2026 feature)
  use_wake_word: true
  
  # Pipeline selection
  pipeline: "Polish Voice Assistant"
  
  # VAD settings
  vad_threshold: 3
  noise_suppression_level: 2
  auto_gain: 31dBFS
  volume_multiplier: 2.0
  
  on_listening:
    - light.turn_on:
        id: led
        red: 0%
        green: 0%
        blue: 100%
        brightness: 100%
        effect: pulse
        
  on_stt_vad_end:
    - light.turn_on:
        id: led
        red: 100%
        green: 100%
        blue: 0%
        brightness: 75%
        
  on_tts_start:
    - light.turn_on:
        id: led
        red: 0%
        green: 100%
        blue: 0%
        brightness: 75%
        
  on_end:
    - light.turn_on:
        id: led
        red: 0%
        green: 100%
        blue: 0%
        brightness: 50%
    - delay: 1s
    - light.turn_off: led
    - voice_assistant.start:
        
  on_error:
    - light.turn_on:
        id: led
        red: 100%
        green: 0%
        blue: 0%
        brightness: 100%
    - delay: 2s
    - light.turn_off: led

# Status LED
light:
  - platform: esp32_rmt_led_strip
    id: led
    rgb_order: GRB
    pin: GPIO27
    num_leds: 1
    rmt_channel: 0
    chipset: SK6812
    default_transition_length: 0s
    effects:
      - pulse:
          name: "Pulse"
          transition_length: 0.5s
          update_interval: 0.5s

# Physical button
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO39
      inverted: true
    name: "${friendly_name} Button"
    on_press:
      - voice_assistant.start:
    on_release:
      - voice_assistant.stop:

# Volume control
number:
  - platform: template
    name: "${friendly_name} Volume"
    id: volume
    min_value: 0
    max_value: 100
    step: 5
    initial_value: 80
    optimistic: true
    on_value:
      - lambda: |-
          id(va).set_volume_multiplier(x / 50.0);

# Device info sensors
sensor:
  - platform: wifi_signal
    name: "${friendly_name} WiFi Signal"
    update_interval: 60s
    
text_sensor:
  - platform: version
    name: "${friendly_name} ESPHome Version"
```

### M5Stack AtomS3 Lite (Enhanced Version)

```yaml
# atom_s3_lite.yaml
substitutions:
  name: "atom-s3-bedroom"
  friendly_name: "Bedroom Voice Assistant"

esphome:
  name: ${name}
  friendly_name: ${friendly_name}
  platformio_options:
    board_build.flash_mode: dio

esp32:
  board: esp32-s3-devkitc-1
  variant: esp32s3
  framework:
    type: esp-idf
    version: recommended
    sdkconfig_options:
      CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"
      CONFIG_ESP32S3_DATA_CACHE_64KB: "y"
      CONFIG_AUDIO_BOARD_CUSTOM: "y"

# WiFi
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

logger:
  level: INFO

api:
  encryption:
    key: !secret api_key

ota:
  password: !secret ota_password

# I2S Audio (AtomS3 Lite)
i2s_audio:
  - id: i2s_audio_bus
    i2s_lrclk_pin: GPIO7
    i2s_bclk_pin: GPIO6

microphone:
  - platform: i2s_audio
    id: s3_microphone
    adc_type: external
    i2s_din_pin: GPIO5
    pdm: true
    channel: left
    sample_rate: 16000
    bits_per_sample: 32bit

speaker:
  - platform: i2s_audio
    id: s3_speaker
    dac_type: external
    i2s_dout_pin: GPIO8
    mode: mono
    sample_rate: 16000
    bits_per_sample: 16bit

# On-device wake word (microWakeWord)
micro_wake_word:
  models:
    - model: ok_nabu
      probability_cutoff: 0.5
  
  on_wake_word_detected:
    - voice_assistant.start:
        wake_word: !lambda 'return wake_word;'
    - light.turn_on:
        id: led_ring
        effect: "Rainbow"

# Voice Assistant with enhanced features
voice_assistant:
  id: va
  microphone: s3_microphone
  speaker: s3_speaker
  use_wake_word: true
  
  # 2026 enhanced features
  pipeline: "Polish Voice Assistant"
  vad_threshold: 3
  noise_suppression_level: 3
  auto_gain: 31dBFS
  volume_multiplier: 2.0
  
  # Conversation context
  conversation_timeout: 300s
  
  on_wake_word_detected:
    - light.turn_on:
        id: led_ring
        red: 0%
        green: 0%
        blue: 100%
        effect: "Scan"
        
  on_listening:
    - light.turn_on:
        id: led_ring
        red: 0%
        green: 100%
        blue: 100%
        effect: "Pulse"
        
  on_stt_end:
    - light.turn_on:
        id: led_ring
        red: 100%
        green: 100%
        blue: 0%
        
  on_tts_start:
    - light.turn_on:
        id: led_ring
        red: 0%
        green: 100%
        blue: 0%
        
  on_end:
    - light.turn_off: led_ring
    - delay: 100ms
    - micro_wake_word.start:
    - voice_assistant.start:
        
  on_error:
    - light.turn_on:
        id: led_ring
        red: 100%
        green: 0%
        blue: 0%
    - delay: 2s
    - light.turn_off: led_ring

# RGB LED Ring (35 LEDs)
light:
  - platform: esp32_rmt_led_strip
    id: led_ring
    rgb_order: GRB
    pin: GPIO2
    num_leds: 35
    rmt_channel: 0
    chipset: WS2812
    default_transition_length: 0s
    effects:
      - pulse:
      - addressable_scan:
          name: "Scan"
          move_interval: 50ms
      - addressable_rainbow:
          name: "Rainbow"
          speed: 10
          width: 50

binary_sensor:
  - platform: gpio
    pin:
      number: GPIO41
      inverted: true
    name: "${friendly_name} Button"
    on_press:
      - voice_assistant.start:
```

---

## Intent Handling

### Custom Sentences (Polish)

```yaml
# config/custom_sentences/pl/lights.yaml
language: "pl"
intents:
  TurnOnLight:
    data:
      - sentences:
          - "włącz światło [w] {area}"
          - "zapal światło [w] {area}"
          - "oświetlenie [w] {area}"
          - "włącz {area}"
  
  TurnOffLight:
    data:
      - sentences:
          - "wyłącz światło [w] {area}"
          - "zgaś światło [w] {area}"
          - "wyłącz {area}"
  
  SetBrightness:
    data:
      - sentences:
          - "ustaw jasność [na] {brightness} procent [w] {area}"
          - "jasność {brightness} [w] {area}"
          - "przyciemnij [w] {area}"
          - "rozjaśnij [w] {area}"

lists:
  area:
    values:
      - "kuchnia"
      - "salon"
      - "sypialnia"
      - "łazienka"
      - "przedpokój"
      - "gabinet"
```

```yaml
# config/custom_sentences/pl/climate.yaml
language: "pl"
intents:
  SetTemperature:
    data:
      - sentences:
          - "ustaw temperaturę [na] {temperature} stopni [w] {area}"
          - "temperatura {temperature} [w] {area}"
          - "ogrzej do {temperature} stopni [w] {area}"
  
  SetClimateMode:
    data:
      - sentences:
          - "włącz {mode} [w] {area}"
          - "ustaw tryb {mode} [w] {area}"

lists:
  mode:
    values:
      - "ogrzewanie"
      - "chłodzenie"
      - "auto"
      - "wentylator"
```

```yaml
# config/custom_sentences/pl/covers.yaml
language: "pl"
intents:
  OpenCover:
    data:
      - sentences:
          - "otwórz {cover}"
          - "podnieś {cover}"
          - "roleta w górę [w] {area}"
  
  CloseCover:
    data:
      - sentences:
          - "zamknij {cover}"
          - "opuść {cover}"
          - "roleta w dół [w] {area}"
  
  SetCoverPosition:
    data:
      - sentences:
          - "ustaw {cover} [na] {position} procent"

lists:
  cover:
    values:
      - "roletę"
      - "żaluzję"
      - "bramę"
```

### Intent Scripts

```yaml
# scripts.yaml
turn_on_lights:
  alias: "Włącz światła"
  sequence:
    - service: light.turn_on
      target:
        area_id: "{{ area }}"
      data:
        brightness_pct: "{{ brightness | default(100) }}"

control_room_lights:
  alias: "Kontrola świateł w pokoju"
  fields:
    area:
      description: "Nazwa obszaru"
      example: "kuchnia"
    action:
      description: "włącz lub wyłącz"
      example: "włącz"
    brightness:
      description: "Jasność 0-100"
      example: 75
  sequence:
    - choose:
        - conditions:
            - condition: template
              value_template: "{{ action == 'włącz' }}"
          sequence:
            - service: light.turn_on
              target:
                area_id: "{{ area }}"
              data:
                brightness_pct: "{{ brightness | default(100) }}"
        - conditions:
            - condition: template
              value_template: "{{ action == 'wyłącz' }}"
          sequence:
            - service: light.turn_off
              target:
                area_id: "{{ area }}"
```

### Response Templates (Polish)

```yaml
# configuration.yaml
conversation:
  intents:
    TurnOnLight:
      - sentences:
          - "włącz światło w {area}"
        response: "Włączam światło w {area}"
        
    TurnOffLight:
      - sentences:
          - "wyłącz światło w {area}"
        response: "Wyłączam światło w {area}"
        
    SetTemperature:
      - sentences:
          - "ustaw temperaturę na {temperature} stopni"
        response: "Ustawiam temperaturę na {temperature} stopni"
        
    GetTime:
      - sentences:
          - "która godzina"
          - "która jest"
        response: "Jest {{ now().strftime('%H:%M') }}"
        
    GetWeather:
      - sentences:
          - "jaka jest pogoda"
          - "jaka temperatura"
        response: >
          Temperatura wynosi {{ states('sensor.outdoor_temperature') }} stopni.
          {{ states('sensor.weather_condition') }}.
```

---

## Multi-Room Voice Setup

### Area-based Pipeline Assignment

```yaml
# configuration.yaml
assist_pipeline:
  # Kitchen pipeline (high traffic, fast response)
  - name: "Kitchen Assistant"
    language: "pl"
    stt_engine: "faster_whisper"
    tts_engine: "piper"
    conversation_agent: "conversation.home_assistant"
    devices:
      - "voice.atom_echo_kitchen"
      
  # Bedroom pipeline (quieter, better voice)
  - name: "Bedroom Assistant"
    language: "pl"
    stt_engine: "cloud.openai_whisper"
    tts_engine: "google_cloud_tts"
    conversation_agent: "conversation.openai_gpt4"
    devices:
      - "voice.atom_s3_bedroom"
      
  # Living room pipeline (family use)
  - name: "Living Room Assistant"
    language: "pl"
    stt_engine: "faster_whisper"
    tts_engine: "azure_tts"
    conversation_agent: "conversation.google_gemini"
    devices:
      - "voice.atom_echo_living_room"
```

### Synchronized Announcements

```yaml
# scripts.yaml
announce_to_all:
  alias: "Ogłoszenie do wszystkich"
  fields:
    message:
      description: "Wiadomość do ogłoszenia"
      example: "Obiad jest gotowy"
  sequence:
    - service: tts.speak
      target:
        entity_id:
          - tts.atom_echo_kitchen
          - tts.atom_s3_bedroom
          - tts.atom_echo_living_room
      data:
        message: "{{ message }}"
        language: "pl"

announce_to_area:
  alias: "Ogłoszenie do obszaru"
  fields:
    area:
      description: "Nazwa obszaru"
      example: "kuchnia"
    message:
      description: "Wiadomość"
      example: "Światło zostało włączone"
  sequence:
    - service: tts.speak
      target:
        area_id: "{{ area }}"
      data:
        message: "{{ message }}"
```

### Context Sharing Between Rooms

```yaml
# automations.yaml
- alias: "Voice Context Sharing"
  trigger:
    - platform: event
      event_type: voice_assistant_conversation
  action:
    - service: conversation.process
      data:
        text: "{{ trigger.event.data.text }}"
        conversation_id: "{{ trigger.event.data.conversation_id }}"
        agent_id: "{{ trigger.event.data.agent_id }}"
    - service: input_text.set_value
      target:
        entity_id: input_text.last_voice_command
      data:
        value: "{{ trigger.event.data.text }}"
```

---

## Error Handling & Fallbacks

### Pipeline Fallback Chain

```yaml
# configuration.yaml
assist_pipeline:
  - name: "Robust Polish Assistant"
    language: "pl"
    
    # Primary chain
    stt_engine: "faster_whisper"
    tts_engine: "piper"
    conversation_agent: "conversation.home_assistant"
    
    # Fallback chains
    stt_fallback:
      - engine: "cloud.openai_whisper"
        condition: "stt_error"
      - engine: "google_cloud_stt"
        condition: "stt_timeout"
        
    tts_fallback:
      - engine: "google_translate"
        condition: "tts_error"
      - engine: "cached_tts"
        condition: "network_error"
        
    conversation_fallback:
      - agent: "conversation.openai_gpt4"
        condition: "intent_not_found"
```

### Error Response Templates

```yaml
# configuration.yaml
assist_pipeline:
  error_responses:
    pl:
      stt_timeout: "Przepraszam, nie usłyszałem nic. Spróbuj ponownie."
      stt_error: "Nie mogłem zrozumieć. Możesz powtórzyć?"
      intent_not_found: "Nie rozumiem tego polecenia. Możesz spytać inaczej?"
      service_error: "Wystąpił problem. Spróbuję jeszcze raz."
      network_error: "Brak połączenia. Pracuję w trybie offline."
      tts_error: "Nie mogę odpowiedzieć głosowo. Sprawdź dzienniki."
```

### Retry Logic

```yaml
# automations.yaml
- alias: "Voice Assistant Retry on Error"
  trigger:
    - platform: event
      event_type: voice_assistant_error
  condition:
    - condition: template
      value_template: "{{ trigger.event.data.retry_count < 3 }}"
  action:
    - delay:
        seconds: "{{ 2 ** trigger.event.data.retry_count }}"
    - service: voice_assistant.retry
      target:
        entity_id: "{{ trigger.event.data.entity_id }}"
```

### Network Loss Handling

```yaml
# automations.yaml
- alias: "Voice Assistant Offline Mode"
  trigger:
    - platform: state
      entity_id: binary_sensor.internet_connection
      to: "off"
  action:
    - service: assist_pipeline.set_pipeline
      target:
        entity_id:
          - voice.atom_echo_kitchen
          - voice.atom_s3_bedroom
      data:
        pipeline: "Offline Polish Assistant"
    - service: tts.speak
      target:
        entity_id: all
      data:
        message: "Przełączam na tryb offline"
        
- alias: "Voice Assistant Online Mode"
  trigger:
    - platform: state
      entity_id: binary_sensor.internet_connection
      to: "on"
      for: "00:01:00"
  action:
    - service: assist_pipeline.set_pipeline
      target:
        entity_id:
          - voice.atom_echo_kitchen
          - voice.atom_s3_bedroom
      data:
        pipeline: "Polish Voice Assistant"
    - service: tts.speak
      target:
        entity_id: all
      data:
        message: "Połączenie przywrócone"
```

### Diagnostic Sensors

```yaml
# configuration.yaml
template:
  - sensor:
      - name: "Voice Pipeline Status"
        state: >
          {% if is_state('binary_sensor.faster_whisper_available', 'on') and 
                is_state('binary_sensor.piper_available', 'on') %}
            online
          {% else %}
            degraded
          {% endif %}
        attributes:
          stt_status: "{{ states('binary_sensor.faster_whisper_available') }}"
          tts_status: "{{ states('binary_sensor.piper_available') }}"
          wake_status: "{{ states('binary_sensor.openwakeword_available') }}"
          
      - name: "Voice Error Rate"
        unit_of_measurement: "%"
        state: >
          {% set total = state_attr('sensor.voice_stats', 'total_requests') | int %}
          {% set errors = state_attr('sensor.voice_stats', 'errors') | int %}
          {{ (errors / total * 100) | round(1) if total > 0 else 0 }}
```

### Logging and Debugging

```yaml
# configuration.yaml
logger:
  default: info
  logs:
    homeassistant.components.assist_pipeline: debug
    homeassistant.components.voice_assistant: debug
    homeassistant.components.wyoming: debug
    homeassistant.components.stt: debug
    homeassistant.components.tts: debug
    homeassistant.components.conversation: debug
```

---

## Advanced Patterns

### Dynamic Pipeline Switching

```yaml
# automations.yaml
- alias: "Switch Pipeline by Time of Day"
  trigger:
    - platform: time
      at: "22:00:00"  # Night mode
    - platform: time
      at: "07:00:00"  # Day mode
  action:
    - service: assist_pipeline.set_pipeline
      target:
        entity_id: all
      data:
        pipeline: >
          {% if now().hour >= 22 or now().hour < 7 %}
            Night Polish Assistant
          {% else %}
            Polish Voice Assistant
          {% endif %}
```

### Voice Command Macros

```yaml
# scripts.yaml
goodnight_routine:
  alias: "Dobranoc rutyna"
  sequence:
    - service: light.turn_off
      target:
        area_id:
          - living_room
          - kitchen
    - service: cover.close_cover
      target:
        area_id: all
    - service: climate.set_temperature
      target:
        area_id: bedroom
      data:
        temperature: 19
    - service: tts.speak
      target:
        entity_id: voice.atom_s3_bedroom
      data:
        message: "Dobranoc. Wszystko jest wyłączone."
```

### Voice-activated Scenes

```yaml
# configuration.yaml
conversation:
  intents:
    ActivateScene:
      - sentences:
          - "scenę {scene}"
          - "tryb {scene}"
          - "{scene}"
        response: "Aktywuję scenę {{ scene }}"

# Custom sentences
language: "pl"
intents:
  ActivateScene:
    data:
      - sentences:
          - "scenę {scene}"
          
lists:
  scene:
    values:
      - in: "film"
        out: "movie_mode"
      - in: "kolację"
        out: "dinner_mode"
      - in: "pracę"
        out: "work_mode"
      - in: "dobranoc"
        out: "goodnight"
```

---

## Performance Optimization

### Resource Management

```yaml
# configuration.yaml
assist_pipeline:
  performance:
    # Limit concurrent pipelines
    max_concurrent_requests: 3
    
    # Cache TTS responses
    tts_cache_enabled: true
    tts_cache_size: 100
    tts_cache_ttl: 3600
    
    # Preload models
    preload_models: true
    
    # Use model quantization
    whisper_quantization: "int8"
```

### Model Selection by Device

```yaml
# Raspberry Pi 4 (4GB RAM)
stt:
  platform: faster_whisper
  model: "base"  # 145MB
  
# Desktop/Server (16GB+ RAM)
stt:
  platform: faster_whisper
  model: "large-v3"  # 3GB, best accuracy
  
# Low-end device
stt:
  platform: vosk
  model: "vosk-model-small-pl-0.22"  # 50MB
```

---

## Testing & Validation

### Test Voice Commands (Polish)

```yaml
# Create input_select for testing
input_select:
  test_voice_command:
    name: "Test polecenia głosowego"
    options:
      - "włącz światło w kuchni"
      - "wyłącz światło w salonie"
      - "ustaw temperaturę na 22 stopnie"
      - "jaka jest pogoda"
      - "która godzina"
      - "dobranoc"
```

### Pipeline Health Check

```yaml
# automations.yaml
- alias: "Voice Pipeline Health Check"
  trigger:
    - platform: time_pattern
      minutes: "/15"
  action:
    - service: assist_pipeline.health_check
      response_variable: health
    - condition: template
      value_template: "{{ health.status != 'healthy' }}"
    - service: notify.admin
      data:
        message: "Voice pipeline unhealthy: {{ health.issues }}"
```

---

## Useful Resources

- **Home Assistant Assist**: https://www.home-assistant.io/voice_control/
- **Wyoming Protocol**: https://github.com/rhasspy/wyoming
- **ESPHome Voice**: https://esphome.io/components/voice_assistant.html
- **Piper TTS**: https://github.com/rhasspy/piper
- **openWakeWord**: https://github.com/dscripka/openWakeWord
- **Polish Language Support**: https://www.home-assistant.io/integrations/pl/

---

*Last updated: 2026-02-18 | Version: 2026.2*
