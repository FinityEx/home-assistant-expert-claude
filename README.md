# Home Assistant Expert Claude Skill

**Version 2.0.0** | Current as of 2026-02-18

A comprehensive, production-grade expert system for Home Assistant administration, debugging, configuration, and development. This Claude Code skill provides deep expertise across all aspects of Home Assistant, from basic YAML configuration to advanced infrastructure and networking.

## 🎯 What This Skill Provides

### Comprehensive Knowledge Base (11,000+ lines)
- **Automation Patterns** (600+ lines): Every trigger type, advanced actions, blueprints, state machines
- **Dashboard Design** (1,330+ lines): Mushroom cards, Bubble Card, responsive layouts, themes
- **ESPHome Templates** (1,574+ lines): ESP32/ESP8266 configs, voice assistants, M5Stack devices
- **HACS Curated List** (1,659+ lines): 30+ integrations, 20+ cards, troubleshooting
- **Troubleshooting Guide** (2,552+ lines): 55+ error patterns, systematic diagnosis
- **Networking Patterns** (598+ lines): Reverse proxy, SSL/TLS, VPN, MQTT security
- **Voice Assistant Patterns** (700+ lines): Assist pipeline, Polish TTS, wake words
- **Template Patterns** (612+ lines): Jinja2 reference, Polish examples

### Production-Ready Scripts
- **`validate_yaml.sh`**: SSH-based config validation with colored output
- **`ha_diagnostics.sh`**: Comprehensive system diagnostics collector  
- **`backup_config.sh`**: Automated backup with retention management

### Key Features
✅ **2026 Current Standards**: All examples use latest syntax (`action:` not `service:`)  
✅ **Polish Language Support**: Entity names, TTS voices, intent examples throughout  
✅ **Validation-First Approach**: Mandatory `ha core check` protocols everywhere  
✅ **MCP Tool Integration**: Protocols for using Home Assistant MCP tools  
✅ **M5Stack Configs**: Complete Atom Echo and AtomS3 Lite voice satellite setups  
✅ **Production Quality**: Every pattern is complete, copy-pasteable, and tested

## ⚠️ Critical Philosophy

**Home Assistant is fragile.** This skill emphasizes:
- **Mandatory validation** before every restart (`ha core check`)
- **Current syntax** (2026 standards)
- **Security best practices** (`!secret`, encryption, proper authentication)
- **Systematic troubleshooting** (Symptoms → Cause → Fix)
- **Version awareness** (check current version, note breaking changes)

## 🚀 Quick Start

### For Claude Code Users

1. This skill is designed to work with the Claude Code CLI
2. It automatically activates when you discuss Home Assistant topics
3. The skill has access to your environment through MCP tools

### Environment Assumptions

The skill is configured for:
- **Home Assistant OS** at `192.168.0.143:8123`
- **SSH access**: `root@homeassistant.local` (password: root)
- **Hardware**: ESP32 devices, Zigbee, WLED, Tuya Local
- **User language**: Polish (with English configuration)
- **Platform**: Windows 10 + MSYS2/Git Bash

### Using the Scripts

```bash
# Validate configuration before restart
./scripts/validate_yaml.sh

# Validate and restart if valid
./scripts/validate_yaml.sh --restart

# Collect comprehensive diagnostics
./scripts/ha_diagnostics.sh --output diagnostics.txt

# Backup configuration files
./scripts/backup_config.sh --local-dir ./backups
```

## 📚 Documentation Structure

### SKILL.md (The Brain)
The main skill prompt containing:
- **Expertise tiers**: Core → Hardware → Infrastructure → Advanced → Operations
- **Diagnostic framework**: 6-step systematic troubleshooting
- **MCP tool protocols**: When and how to use each tool
- **YAML standards**: Strict rules for 2026 syntax
- **Version awareness**: Breaking changes, deprecated features
- **Communication style**: Technical, precise, validation-focused

### Reference Files

| File | Lines | Content |
|------|-------|---------|
| `automation_patterns.md` | 600+ | All trigger types, actions, conditions, blueprints, state machines |
| `dashboard_design.md` | 1,330+ | Mushroom/Bubble cards, sections layout, themes, responsive design |
| `esphome_templates.md` | 1,574+ | ESP32/ESP8266, voice assistants, M5Stack, sensors, displays |
| `hacs_curated.md` | 1,659+ | 30+ integrations, 20+ cards, installation, troubleshooting |
| `troubleshooting_guide.md` | 2,552+ | 55+ error patterns, log analysis, systematic diagnosis |
| `networking_patterns.md` | 598+ | Reverse proxy, SSL, VPN, MQTT, firewall, VLAN |
| `voice_assistant_patterns.md` | 700+ | Assist pipeline, Polish TTS, wake words, M5Stack configs |
| `template_patterns.md` | 612+ | Jinja2 reference, functions, Polish examples |

## 🎨 Design Principles

### 1. Validation-First
Every configuration change must be validated:
```bash
ssh root@homeassistant.local "ha core check"
```
The skill includes validation checklists with every YAML example.

### 2. Current Standards (2026-02-18)
- Use `action:` not `service:` (mandatory since 2025.6)
- ESP-IDF framework for ESP32 (default since 2025.x)
- Sections layout for dashboards (standard since 2024.1)
- New OTA platform syntax for ESPHome
- Mature Voice Assist pipeline

### 3. Complete, Copy-Pasteable Examples
No truncated code with `...`. Every example is:
- ✅ Syntactically correct
- ✅ Follows 2026 standards
- ✅ Includes validation checklist
- ✅ Has inline comments
- ✅ Uses `!secret` for credentials

### 4. Polish Language Integration
- Entity naming: `sensor.temperatura_salon`, `light.salon_glowna`
- TTS voices: Piper Polish, Google Cloud Polish, Azure Polish
- Intent examples: Polish sentences for voice control
- UI strings: Polish-friendly formatting

### 5. Systematic Troubleshooting
Every issue follows:
1. **Symptoms**: What the user sees
2. **Cause**: Root cause analysis
3. **Fix**: Step-by-step resolution
4. **Prevention**: How to avoid recurrence

## 🔧 Common Use Cases

### Creating an Automation
The skill will:
1. Consult `automation_patterns.md` for current patterns
2. Generate complete YAML with 2026 syntax
3. Include validation checklist
4. Provide troubleshooting tips
5. Suggest related patterns

### Setting Up Voice Assistant
The skill provides:
1. M5Stack Atom Echo complete config
2. Polish TTS voice options
3. Wake word configuration
4. Custom Polish intents
5. Multi-room setup guidance

### Debugging "Entity Unavailable"
The skill follows:
1. Check entity state via MCP tools
2. Verify integration loaded
3. Review logs via SSH
4. Check network connectivity
5. Validate configuration
6. Suggest fixes and monitoring

### Dashboard Design
The skill offers:
1. Modern sections layout patterns
2. Mushroom/Bubble card examples
3. Polish entity integration
4. Responsive design guidance
5. Performance optimization

## 🛡️ Security Best Practices

Every configuration includes:
- **`!secret` usage**: Never hardcode credentials
- **API encryption**: Always enable for ESPHome
- **OTA passwords**: Unique per device
- **SSH keys**: Preferred over passwords
- **Network segmentation**: VLAN recommendations
- **Firewall rules**: Minimal exposure principles

## 📊 Statistics

- **Total Lines**: 11,000+
- **YAML Examples**: 200+
- **Error Patterns**: 55+
- **Integration Guides**: 30+
- **Card Examples**: 20+
- **Scripts**: 3 production-ready
- **Cross-references**: Throughout all files

## 🤝 Contributing

This skill is tailored for a specific environment but can be adapted:
1. Update environment details in `SKILL.md`
2. Modify scripts for your SSH configuration
3. Adjust Polish language examples as needed
4. Add integration-specific patterns to reference files

## 📝 License

MIT License - See repository for details

## 🔄 Version History

### 2.0.0 (2026-02-18)
- Complete rebuild from skeleton to production-grade expert system
- 11,000+ lines of comprehensive documentation
- 3 production-ready bash scripts
- 2026 current syntax throughout
- Polish language integration
- Mandatory validation protocols
- MCP tool usage guidance
- 8 comprehensive reference files

### 1.0.0 (Previous)
- Basic skeleton structure
- Minimal reference files
- Single JavaScript validation script

## 🆘 Support

For issues or questions:
1. Review relevant reference file
2. Check troubleshooting guide
3. Run diagnostics script
4. Consult SKILL.md for systematic approach

---

**Remember**: Home Assistant is fragile. Always validate (`ha core check`) before restarting. This skill is your safety net.
