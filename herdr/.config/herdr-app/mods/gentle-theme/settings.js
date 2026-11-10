// Pure helper: finds the Pi settings that hold the active theme name. Gentle Shell (web installer)
// keeps them in ~/.gentle-shell/agent; the Pi extension keeps them in ~/.pi/agent. The first file
// that exists wins; a file that exists but is not valid JSON is an error, never a reason to fall
// through to the next one. Returns the parsed settings, or undefined when missing or invalid.
const PATHS = (h) => [`${h}/.gentle-shell/agent/settings.json`, `${h}/.pi/agent/settings.json`];

export async function readSettings(h, read) {
  for (const file of PATHS(h)) {
    const text = await read(file);
    if (text === null) continue;
    try { return JSON.parse(text); } catch { return undefined; }
  }
  return undefined;
}
