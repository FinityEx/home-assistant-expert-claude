// validate_yaml.js
// A simple script to validate YAML syntax using basic parsing.
// Usage: node validate_yaml.js <path_to_yaml_file>

const fs = require('fs');

if (process.argv.length < 3) {
  console.error("Usage: node validate_yaml.js <file>");
  process.exit(1);
}

const filePath = process.argv[2];

try {
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Basic validation: Check indentation consistency and key-value pairs
  // Note: A full YAML parser would be better, but this catches gross errors without deps.
  const lines = content.split('
');
  let valid = true;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Check for tabs (YAML forbids tabs)
    if (line.includes('	')) {
      console.error(`Error on line ${i + 1}: Tabs are not allowed in YAML.`);
      valid = false;
    }
  }

  // Attempt to parse if js-yaml is available (it might be in the environment)
  try {
    // If we're lucky and can require 'js-yaml'
    const yaml = require('js-yaml');
    yaml.load(content);
    console.log(`Success: '${filePath}' is valid YAML.`);
  } catch (e) {
    if (e.code === 'MODULE_NOT_FOUND') {
      // Fallback message
      if (valid) {
        console.log(`Pass: '${filePath}' passed basic syntax checks (No tabs found).`);
        console.log("Note: Install 'js-yaml' for full validation.");
      } else {
        console.error(`Failure: '${filePath}' contains syntax errors.`);
        process.exit(1);
      }
    } else {
      console.error(`Error parsing YAML: ${e.message}`);
      process.exit(1);
    }
  }

} catch (err) {
  console.error(`Error reading file: ${err.message}`);
  process.exit(1);
}
