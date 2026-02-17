---
name: home-assistant-expert
description: Expert agent for Home Assistant, ESPHome, HACS, Dashboards, and Debugging.
version: 1.0.0
author: kwojtek
license: MIT
---

# Home Assistant Expert Skill

This skill provides expert guidance for managing, debugging, and enhancing your Home Assistant instance.

## Core Capabilities & Resources

### 1. Dashboard Design (Lovelace YAML)
**Reference**: `references/dashboard_design.md`
- Use **Mushroom Cards** and **Sections Layout** for modern, responsive designs.
- Consult the reference for YAML patterns like "Glance Header" and "Room Cards".
- **Action**: When asked for a dashboard, read the reference first to ensure you use 2025/2026 standards.

### 2. ESPHome Configuration
**Reference**: `references/esphome_templates.md`
- Use a **Package-based** architecture (`common/base.yaml`) for scalability.
- Always implement **Secrets** for credentials.
- **Action**: When asked for ESPHome config, check the reference for the `base.yaml` pattern and standard sensors.

### 3. Automations & Logic
**Reference**: `references/automation_patterns.md`
- Design for **Resilience**: Assume restarts happen. Use Trigger IDs for "catch-up" logic.
- **Action**: When writing automations, ensure you handle the `homeassistant.start` event if state persistence matters.

### 4. HACS Recommendations
**Reference**: `references/hacs_curated.md`
- Recommend proven integrations like **Adaptive Lighting**, **Spook**, and **Alarmo**.
- **Action**: Check the curated list before searching the web for random repositories.

### 5. Validation & Safety
**Script**: `scripts/validate_yaml.js`
- **Action**: Before presenting any YAML code to the user, mentally validate it against the "Safety" principles (no tabs, correct indentation).
- If operating on local files, use the script to verify syntax.

## Workflow for Requests

1.  **Analyze**: Determine if the request is for Dashboard, Hardware (ESPHome), Logic (Automation), or System (HACS/Debug).
2.  **Consult Reference**: Read the appropriate `references/*.md` file to load best practices.
3.  **Generate**: Create the solution using the patterns found in the reference.
4.  **Validate**: Double-check for fragile YAML syntax.
5.  **Explain**: Briefly explain *why* this pattern was chosen (e.g., "I used the Sections layout because it's responsive...").

## Suggested Triggers

Use this skill when the user asks about:
- "Home Assistant" or "HA"
- "ESPHome" or "HACS"
- "Lovelace dashboard" or "YAML config"
- "Debugging HA logs"
