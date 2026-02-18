#!/usr/bin/env bash
# Test script to verify all scripts are properly formatted and executable

echo "Testing Home Assistant Expert Skill Scripts..."
echo ""

# Test 1: Check executability
echo "[1/3] Checking script permissions..."
for script in scripts/*.sh; do
    if [[ -x "$script" ]]; then
        echo "  ✓ $script is executable"
    else
        echo "  ✗ $script is NOT executable"
        exit 1
    fi
done
echo ""

# Test 2: Check syntax
echo "[2/3] Checking bash syntax..."
for script in scripts/validate_yaml.sh scripts/ha_diagnostics.sh scripts/backup_config.sh; do
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ $script syntax OK"
    else
        echo "  ✗ $script has syntax errors"
        exit 1
    fi
done
echo ""

# Test 3: Check for required commands
echo "[3/3] Verifying script structure..."
if grep -q "ha core check" scripts/validate_yaml.sh; then
    echo "  ✓ validate_yaml.sh uses 'ha core check'"
else
    echo "  ✗ validate_yaml.sh missing 'ha core check'"
    exit 1
fi

if grep -q "ha core info" scripts/ha_diagnostics.sh; then
    echo "  ✓ ha_diagnostics.sh uses 'ha core info'"
else
    echo "  ✗ ha_diagnostics.sh missing 'ha core info'"
    exit 1
fi

if grep -q "tar czf" scripts/backup_config.sh; then
    echo "  ✓ backup_config.sh creates tar archives"
else
    echo "  ✗ backup_config.sh missing tar creation"
    exit 1
fi

echo ""
echo "✓ All tests passed!"
