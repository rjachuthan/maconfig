// Pure Pi theme -> herdr theme derivation. No imports, no I/O.
//
// A Pi theme has `vars` (name -> color), `colors` (Pi UI key -> var name or color) and, for the
// built-ins, `export` (pageBg, cardBg). A color is #rrggbb or `okhsl(H S% L%)` (Pi's own notation).
// A source is looked up by name: `colors[name]` first (a var name or a color), then `vars[name]`;
// `export.<key>` names read the export section. The first candidate that resolves wins;
// otherwise the `base` value is kept.
//
// herdr field                                  <- Pi sources (first match wins)
// background, colors.background                <- bg, export.pageBg
// foreground, colors.foreground, solid         <- text
// selection, colors.selection, selected, hover <- selection, selectedBg
// cursor, colors.accent, ansi5 (magenta)       <- accent
// colors.chrome, canvas, popover               <- bgPanel, export.cardBg, export.pageBg
// colors.surface, colors.input                 <- bgElement, bgSubtle, export.cardBg
// colors.raised                                <- userMessageBg
// colors.border                                <- border, borderMuted
// colors.muted, idle, ansi7                    <- muted
// colors.dim, ansi8, colors.unknown            <- dim
// colors.working                               <- accent
// colors.blocked, ansi1/ansi9 (red)            <- error
// colors.done, ansi2/ansi10 (green)            <- success
// ansi3/ansi11 (yellow)                        <- warning
// ansi4/ansi12 (blue)                          <- info, mdLink
// ansi6/ansi14 (cyan)                          <- cyan, syntaxVariable
// ansi13 (bright magenta)                      <- activePink
// ansi15 (bright white)                        <- text
// Light themes (derived background luminance > 0.5) also get readable always-base fields:
// accent_foreground / solid_foreground = black or white by contrast, ansi0 = dark neutral.
// Everything else keeps `base`.

export const BASE = {
  background: "#140a12",
  foreground: "#f6eff3",
  selection: "#342230",
  cursor: "#f095c8",
  ansi: [
    "#20161e", "#ff718f", "#b4e7c7", "#e0c27a", "#a9c7ee", "#ff76c3", "#d7a0b8", "#a78e9b",
    "#76616b", "#ff718f", "#b4e7c7", "#f2b86d", "#a9c7ee", "#ffb1dd", "#d7a0b8", "#f6eff3",
  ],
  colors: {
    background: "#140a12",
    foreground: "#f6eff3",
    chrome: "#100a0e",
    canvas: "#100a0e",
    surface: "#20161e",
    popover: "#20161e",
    raised: "#241822",
    hover: "#241822",
    selected: "#342230",
    border: "#342230",
    input: "#1a1218",
    muted: "#a78e9b",
    dim: "#76616b",
    accent: "#f095c8",
    accent_foreground: "#140a12",
    solid: "#f6eff3",
    solid_foreground: "#140a12",
    selection: "#342230",
    working: "#f095c8",
    blocked: "#ff718f",
    done: "#b4e7c7",
    idle: "#a78e9b",
    unknown: "#76616b",
  },
};

// OKHSL -> sRGB, mirrored from Pi's own implementation (pi-tui dist/oklab.js), which is a port of
// Bjorn Ottosson's reference (https://bottosson.github.io/posts/colorpicker/, MIT, (c) 2021).
const multiply = (m, [x, y, z]) => m.map((row) => row[0] * x + row[1] * y + row[2] * z);
const LAB_TO_LMS = [
  [1, 0.3963377773761749, 0.2158037573099136],
  [1, -0.1055613458156586, -0.0638541728258133],
  [1, -0.0894841775298119, -1.2914855480194092],
];
const LMS_TO_LINEAR_SRGB = [
  [4.0767416360759583, -3.3077115392580629, 0.2309699031821043],
  [-1.2684379732850315, 2.6097573492876882, -0.341319376002657],
  [-0.0041960761386756, -0.7034186179359362, 1.7076146940746117],
];
const SATURATION_FIT = [
  [[-1.8817031, -0.80936501], [1.19086277, 1.76576728, 0.59662641, 0.75515197, 0.56771245]],
  [[1.8144408, -1.19445267], [0.73956515, -0.45954404, 0.08285427, 0.12541073, -0.14503204]],
  [[0.13110758, 1.81333971], [1.35733652, -0.00915799, -1.1513021, -0.50559606, 0.00692167]],
];
const K1 = 0.206;
const K2 = 0.03;
const K3 = (1 + K1) / (1 + K2);
const okhslToOklabLightness = (x) => (x * x + K1 * x) / (K3 * (x + K2));
const linearToSrgb = (v) => (v > 0.0031308 ? 1.055 * v ** (1 / 2.4) - 0.055 : 12.92 * v);
const oklabToLinearSrgb = (lab) => multiply(LMS_TO_LINEAR_SRGB, multiply(LAB_TO_LMS, lab).map((v) => v ** 3));
const linearSrgbToRgb = (linear) => {
  const [r, g, b] = linear.map((v) => Math.round(Math.min(1, Math.max(0, linearToSrgb(v))) * 255));
  return { r, g, b };
};
const lmsSlopes = (a, b) => LAB_TO_LMS.map((row) => row[1] * a + row[2] * b);

function maxSaturation(a, b) {
  const channel = SATURATION_FIT.findIndex(([[x, y]], index) => index === 2 || x * a + y * b > 1);
  const [k0, k1, k2, k3, k4] = SATURATION_FIT[channel][1];
  const weights = LMS_TO_LINEAR_SRGB[channel];
  const saturation = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b;
  const slopes = lmsSlopes(a, b);
  const base = slopes.map((k) => 1 + saturation * k);
  const dot = (values) => values.reduce((sum, value, index) => sum + weights[index] * value, 0);
  const f = dot(base.map((value) => value ** 3));
  const f1 = dot(base.map((value, index) => 3 * slopes[index] * value ** 2));
  const f2 = dot(base.map((value, index) => 6 * slopes[index] ** 2 * value));
  return saturation - (f * f1) / (f1 * f1 - 0.5 * f * f2);
}

function cusp(a, b) {
  const saturation = maxSaturation(a, b);
  const lightness = Math.cbrt(1 / Math.max(...oklabToLinearSrgb([1, saturation * a, saturation * b])));
  return [lightness, lightness * saturation];
}

function maxChroma(a, b, lightness, [cuspL, cuspC]) {
  if (lightness <= cuspL) return (cuspC * lightness) / cuspL;
  const t = (cuspC * (lightness - 1)) / (cuspL - 1);
  const slopes = lmsSlopes(a, b);
  const lms = slopes.map((k) => lightness + t * k);
  const cubes = lms.map((value) => value ** 3);
  const first = lms.map((value, index) => 3 * slopes[index] * value ** 2);
  const second = lms.map((value, index) => 6 * slopes[index] ** 2 * value);
  const dot = (row, values) => row[0] * values[0] + row[1] * values[1] + row[2] * values[2];
  const steps = LMS_TO_LINEAR_SRGB.map((row) => {
    const f = dot(row, cubes) - 1;
    const f1 = dot(row, first);
    const f2 = dot(row, second);
    const u = f1 / (f1 * f1 - 0.5 * f * f2);
    return u >= 0 ? -f * u : Number.MAX_VALUE;
  });
  return t + Math.min(...steps);
}

function chromaStops(L, a, b) {
  const peak = cusp(a, b);
  const cMax = maxChroma(a, b, L, peak);
  const k = cMax / Math.min(L * (peak[1] / peak[0]), (1 - L) * (peak[1] / (1 - peak[0])));
  const midS = 0.11516993 +
    1 / (7.4477897 + 4.1590124 * b + a * (-2.19557347 + 1.75198401 * b + a * (-2.13704948 - 10.02301043 * b +
      a * (-4.24894561 + 5.38770819 * b + 4.69891013 * a))));
  const midT = 0.11239642 +
    1 / (1.6132032 - 0.68124379 * b + a * (0.40370612 + 0.90148123 * b + a * (-0.27087943 + 0.6122399 * b +
      a * (0.00299215 - 0.45399568 * b - 0.14661872 * a))));
  const cMid = 0.9 * k * Math.sqrt(Math.sqrt(1 / (1 / (L * midS) ** 4 + 1 / ((1 - L) * midT) ** 4)));
  const c0 = Math.sqrt(1 / (1 / (L * 0.4) ** 2 + 1 / ((1 - L) * 0.8) ** 2));
  return [c0, cMid, cMax];
}

// hue in degrees, saturation and lightness 0-1.
function okhslToRgb(hue, saturation, lightness) {
  const L = okhslToOklabLightness(lightness);
  let lab = [L, 0, 0];
  if (L > 0 && L < 1 && saturation > 0) {
    const angle = (2 * Math.PI * (((hue % 360) + 360) % 360)) / 360;
    const a = Math.cos(angle);
    const b = Math.sin(angle);
    const [c0, cMid, cMax] = chromaStops(L, a, b);
    let chroma;
    if (saturation < 0.8) {
      const t = 1.25 * saturation;
      const k1 = 0.8 * c0;
      chroma = (t * k1) / (1 - (1 - k1 / cMid) * t);
    } else {
      const t = 5 * (saturation - 0.8);
      const k1 = (0.2 * cMid ** 2 * 1.25 ** 2) / c0;
      chroma = cMid + (t * k1) / (1 - (1 - k1 / (cMax - cMid)) * t);
    }
    lab = [L, chroma * a, chroma * b];
  }
  return linearSrgbToRgb(oklabToLinearSrgb(lab));
}

const HEX = /^#[0-9a-fA-F]{6}$/;
const NUM = String.raw`[+-]?(?:\d+(?:\.\d*)?|\.\d+)`;
const OKHSL = new RegExp(`^okhsl\\(\\s*(${NUM})(?:deg)?\\s+(${NUM})(%)?\\s+(${NUM})(%)?\\s*\\)$`, "i");
const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);

// "#rrggbb" or "okhsl(H S% L%)" -> lowercase "#rrggbb"; anything else (or out of range) -> null.
export function parseColor(value) {
  if (typeof value !== "string") return null;
  if (HEX.test(value)) return value.toLowerCase();
  const m = OKHSL.exec(value);
  if (!m) return null;
  const s = parseFloat(m[2]) / (m[3] ? 100 : 1);
  const l = parseFloat(m[4]) / (m[5] ? 100 : 1);
  if (!(s >= 0 && s <= 1 && l >= 0 && l <= 1)) return null;
  const { r, g, b } = okhslToRgb(parseFloat(m[1]), s, l);
  return `#${[r, g, b].map((c) => c.toString(16).padStart(2, "0")).join("")}`;
}

const luminance = (hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a, b) => (Math.max(luminance(a), luminance(b)) + 0.05) / (Math.min(luminance(a), luminance(b)) + 0.05);
const readableOn = (bg) => (contrast("#000000", bg) >= contrast("#ffffff", bg) ? "#000000" : "#ffffff");
const LIGHT_BLACK = "#2b2b2b";

// [herdr color name, Pi sources] for `colors`.
const COLORS = [
  ["background", ["bg", "export.pageBg"]],
  ["foreground", ["text"]],
  ["chrome", ["bgPanel", "export.cardBg", "export.pageBg"]],
  ["canvas", ["bgPanel", "export.cardBg", "export.pageBg"]],
  ["popover", ["bgPanel", "export.cardBg", "export.pageBg"]],
  ["surface", ["bgElement", "bgSubtle", "export.cardBg"]],
  ["input", ["bgElement", "bgSubtle", "export.cardBg"]],
  ["raised", ["userMessageBg"]],
  ["hover", ["selection", "selectedBg"]],
  ["selected", ["selection", "selectedBg"]],
  ["selection", ["selection", "selectedBg"]],
  ["border", ["border", "borderMuted"]],
  ["muted", ["muted"]],
  ["idle", ["muted"]],
  ["dim", ["dim"]],
  ["unknown", ["dim"]],
  ["accent", ["accent"]],
  ["working", ["accent"]],
  ["blocked", ["error"]],
  ["done", ["success"]],
  ["solid", ["text"]],
];

// [ansi index, Pi sources].
const ANSI = [
  [1, ["error"]], [9, ["error"]],
  [2, ["success"]], [10, ["success"]],
  [3, ["warning"]], [11, ["warning"]],
  [4, ["info", "mdLink"]], [12, ["info", "mdLink"]],
  [5, ["accent"]], [13, ["activePink"]],
  [6, ["cyan", "syntaxVariable"]], [14, ["cyan", "syntaxVariable"]],
  [7, ["muted"]], [8, ["dim"]], [15, ["text"]],
];

export function derive(piTheme, base = BASE) {
  if (!isObject(piTheme) || (!isObject(piTheme.vars) && !isObject(piTheme.colors))) return base;
  const vars = isObject(piTheme.vars) ? piTheme.vars : {};
  const pi = isObject(piTheme.colors) ? piTheme.colors : {};
  const exp = isObject(piTheme.export) ? piTheme.export : {};

  const color = (v) => parseColor(v) ?? (typeof v === "string" && Object.hasOwn(vars, v) ? parseColor(vars[v]) : null);
  const resolve = (name) => {
    if (name.startsWith("export.")) {
      const key = name.slice(7);
      return Object.hasOwn(exp, key) ? color(exp[key]) : null;
    }
    for (const source of [pi, vars]) {
      if (Object.hasOwn(source, name)) {
        const found = color(source[name]);
        if (found) return found;
      }
    }
    return null;
  };
  const pick = (names, fallback) => {
    for (const n of names) {
      const c = resolve(n);
      if (c) return c;
    }
    return fallback;
  };

  const baseColors = isObject(base.colors) ? base.colors : {};
  const out = {
    background: pick(["bg", "export.pageBg"], base.background),
    foreground: pick(["text"], base.foreground),
    selection: pick(["selection", "selectedBg"], base.selection),
    cursor: pick(["accent"], base.cursor),
    ansi: [...base.ansi],
    colors: { ...baseColors },
  };
  for (const [i, names] of ANSI) out.ansi[i] = pick(names, base.ansi[i]);
  for (const [name, names] of COLORS) out.colors[name] = pick(names, baseColors[name]);
  if (luminance(out.background) > 0.5) {
    out.colors.accent_foreground = readableOn(out.colors.accent);
    out.colors.solid_foreground = readableOn(out.colors.solid);
    out.ansi[0] = LIGHT_BLACK;
  }
  return out;
}

// Which Pi theme to use for `name`. `texts` are the candidate theme files' contents (null = missing)
// in priority order; a file wins over a built-in of the same name.
// -> { pi } | { pi, builtin: true } | { error }
export function resolveTheme(name, texts, builtin) {
  for (const text of texts) {
    if (text === null) continue;
    try { return { pi: JSON.parse(text) }; } catch { return { error: "theme file is invalid JSON" }; }
  }
  if (Object.hasOwn(builtin, name)) return { pi: builtin[name], builtin: true };
  return { error: "theme file not found" };
}
