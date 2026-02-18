# Home Assistant Expert - Copilot Instructions

## Project Overview

This is a Claude AI skill/plugin that provides expert guidance for Home Assistant, ESPHome, HACS integrations, and dashboard design. The skill helps users manage, debug, and enhance their Home Assistant instances following 2025/2026 best practices.

**Core Purpose**: Guide users through Home Assistant configuration, automation design, ESPHome device setup, and modern dashboard creation using proven patterns.

## Project Structure

```
/
├── SKILL.md                      # Main skill definition and workflow
├── references/                   # Best practices and patterns
│   ├── dashboard_design.md      # Lovelace/YAML dashboard patterns
│   ├── esphome_templates.md     # ESPHome configuration patterns
│   ├── automation_patterns.md   # Home Assistant automation patterns
│   └── hacs_curated.md          # Recommended HACS integrations
├── scripts/                      # Validation utilities
│   └── validate_yaml.js         # YAML validation script
└── .claude-plugin/              # Claude plugin metadata
    └── marketplace.json         # Plugin marketplace information
```

## Technology Stack

- **Language**: Markdown (documentation)
- **Config Format**: YAML (examples and patterns)
- **Target Platform**: Home Assistant (Python-based home automation)
- **Dependencies**: None (this is a knowledge repository)

## Coding Guidelines

### Documentation Standards

- Use **clear, concise headings** with hierarchy
- Include **practical code examples** for every pattern
- Use **bullet points** for lists and options
- Keep examples **copy-paste ready** with proper YAML formatting

### YAML Guidelines (for examples)

- **NEVER use tabs** - always use 2 spaces for indentation
- **Validate syntax** before including examples
- **Include comments** to explain non-obvious configurations
- Use **modern syntax** (2025/2026 standards):
  - Prefer `custom:mushroom-*` cards over legacy card types
  - Use `sections` layout instead of nested stacks
  - Use `trigger: []` with `id:` for robust automations

### Example Format

When providing configuration examples:

```yaml
# Good: Clear, commented, modern
automation:
  - alias: "Motion Light"
    trigger:
      - platform: state
        entity_id: binary_sensor.motion
        to: "on"
        id: "motion_detected"
    action:
      - service: light.turn_on
        target:
          entity_id: light.room

# Bad: No comments, unclear purpose
automation:
  - trigger:
      - platform: state
        entity_id: binary_sensor.motion
```

## Content Philosophy

### 1. Reference Files First

When answering questions, **always consult the appropriate reference file**:
- Dashboard questions → `references/dashboard_design.md`
- ESPHome questions → `references/esphome_templates.md`
- Automation questions → `references/automation_patterns.md`
- Integration questions → `references/hacs_curated.md`

### 2. Modern Patterns Only

- **Mushroom Cards** over legacy cards
- **Sections layout** over vertical/horizontal stacks
- **Package-based ESPHome** over monolithic configs
- **Trigger IDs** for resilient automations

### 3. Mobile-First Design

- Dashboards should work beautifully on phones
- Use responsive layouts (sections)
- Minimize navigation depth

### 4. Security & Resilience

- Always use `secrets.yaml` for credentials in examples
- Design automations to handle restarts (`homeassistant.start` trigger)
- Include fallback configurations (e.g., ESPHome fallback AP)

## File Modification Guidelines

### When Adding New Patterns

1. **Location**: Add to appropriate reference file in `references/`
2. **Format**: Follow existing structure (Philosophy → Patterns → Examples)
3. **Examples**: Include complete, working code snippets
4. **Updates**: Update `SKILL.md` if adding new workflow steps

### When Updating Existing Patterns

1. **Preserve structure**: Keep headings and organization consistent
2. **Add don't replace**: Add new examples, don't remove working ones unless deprecated
3. **Document changes**: Add date/version markers for significant pattern updates

## Common Pitfalls to Avoid

1. **Tabs in YAML**: Always use spaces (this breaks Home Assistant)
2. **Outdated card types**: Don't suggest `entity-card` when `mushroom-template-card` exists
3. **Monolithic configs**: Prefer modular, reusable patterns
4. **State-dependent automations**: Always handle HA restart scenarios
5. **Excessive nesting**: Keep dashboard layouts simple and flat

## Testing & Validation

- YAML examples should be validated with `scripts/validate_yaml.js` (if available)
- Test patterns against Home Assistant 2025/2026 versions
- Verify mobile responsiveness of dashboard examples

## Response Style

When the skill is invoked to answer questions:

1. **Analyze**: Determine category (Dashboard/ESPHome/Automation/HACS/Debug)
2. **Reference**: Cite the specific pattern from reference files
3. **Generate**: Provide copy-paste ready configuration
4. **Explain**: Briefly explain *why* this pattern is recommended
5. **Validate**: Ensure YAML is syntactically correct

## External Resources

- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [ESPHome Documentation](https://esphome.io/)
- [Mushroom Cards](https://github.com/piitaya/lovelace-mushroom)
- [HACS](https://hacs.xyz/)

## Examples

### Good Response Pattern
```markdown
I'll create a motion-activated light automation using the "Catch-Up" pattern from our automation best practices.

This pattern handles both normal motion events and HA restarts:

[YAML example with comments]

**Why this works**: The `homeassistant.start` trigger ensures the light turns on if motion was detected before a restart.
```

### Bad Response Pattern
```markdown
Here's some code:

[YAML without context or explanation]
```

---

**Note**: This repository focuses on knowledge curation, not code execution. Changes should enhance documentation quality and pattern accuracy.
