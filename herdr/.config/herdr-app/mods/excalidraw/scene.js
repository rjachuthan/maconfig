// The Excalidraw scene model: element defaults, geometry as path segments, hit-testing, arrow binding
// and bound labels. Everything here works in scene coordinates and knows nothing about the view.
// Segments: ["M", x, y], ["L", x, y], ["C", c1x, c1y, c2x, c2y, x, y], ["Z"].

export const STROKES = ["#1e1e1e", "#e03131", "#2f9e44", "#1971c2", "#f08c00", "#6741d9"];
export const FILLS = ["transparent", "#ffc9c9", "#b2f2bb", "#a5d8ff", "#ffec99", "#d0bfff"];
export const FONT_SIZES = [["S", 16], ["M", 20], ["L", 28], ["XL", 36]];
export const LINE_HEIGHT = 1.25;
export const SHAPES = new Set(["rectangle", "ellipse", "diamond"]);
export const LINEAR = new Set(["arrow", "line"]);
const BINDABLE = new Set(["rectangle", "ellipse", "diamond", "text", "image"]);
const PAD = 5; // label padding inside a container, as Excalidraw's BOUND_TEXT_PADDING

export const DEFAULT_STYLE = {
  strokeColor: "#1e1e1e", backgroundColor: "transparent", fillStyle: "solid", strokeWidth: 2,
  strokeStyle: "solid", roughness: 1, opacity: 100, fontSize: 20, fontFamily: 5, roundness: true, endArrowhead: "arrow",
};

const ID_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-";
export const newId = () => { let s = ""; for (let i = 0; i < 21; i++) s += ID_CHARS[Math.floor(Math.random() * ID_CHARS.length)]; return s; };
const seed = () => Math.floor(Math.random() * 2 ** 31);

export function newElement(type, x, y, style) {
  const el = {
    id: newId(), type, x, y, width: 0, height: 0, angle: 0,
    strokeColor: style.strokeColor, backgroundColor: style.backgroundColor, fillStyle: style.fillStyle,
    strokeWidth: style.strokeWidth, strokeStyle: style.strokeStyle, roughness: style.roughness, opacity: style.opacity,
    groupIds: [], frameId: null,
    roundness: !style.roundness ? null : type === "rectangle" ? { type: 3 } : LINEAR.has(type) || type === "diamond" ? { type: 2 } : null,
    seed: seed(), version: 1, versionNonce: seed(), isDeleted: false, boundElements: null,
    updated: Date.now(), link: null, locked: false,
  };
  if (type === "text") Object.assign(el, {
    text: "", fontSize: style.fontSize, fontFamily: style.fontFamily, textAlign: "left", verticalAlign: "top",
    containerId: null, originalText: "", autoResize: true, lineHeight: LINE_HEIGHT,
  });
  if (LINEAR.has(type)) Object.assign(el, {
    points: [[0, 0], [0, 0]], lastCommittedPoint: null, startBinding: null, endBinding: null,
    startArrowhead: null, endArrowhead: type === "arrow" ? style.endArrowhead : null,
  });
  if (type === "arrow") el.elbowed = false;
  if (type === "freedraw") Object.assign(el, { points: [[0, 0]], pressures: [], simulatePressure: true, lastCommittedPoint: null });
  return el;
}

// Excalidraw compares version/versionNonce when it merges scenes; bump them on every edit.
export const touch = (el) => { el.version = (el.version ?? 0) + 1; el.versionNonce = seed(); el.updated = Date.now(); };

// ---------- text ----------

const MONO = new Set([3, 8]);
export const charWidth = (fontFamily) => (MONO.has(fontFamily) ? 0.6 : 0.56);
export function measure(text, fontSize, fontFamily) {
  const lines = String(text).split("\n");
  const longest = Math.max(1, ...lines.map((l) => l.length));
  return { width: longest * fontSize * charWidth(fontFamily), height: lines.length * fontSize * LINE_HEIGHT };
}
export function wrap(text, maxWidth, fontSize, fontFamily) {
  const per = Math.max(1, Math.floor(maxWidth / (fontSize * charWidth(fontFamily))));
  const out = [];
  for (const line of String(text).split("\n")) {
    let cur = "";
    for (const word of line.split(" ")) {
      if (!cur) cur = word;
      else if ((cur + " " + word).length <= per) cur += " " + word;
      else { out.push(cur); cur = word; }
      while (cur.length > per) { out.push(cur.slice(0, per)); cur = cur.slice(per); }
    }
    out.push(cur);
  }
  return out.join("\n");
}

// ---------- geometry ----------

export const center = (el) => {
  const b = bounds(el, true);
  return [b.x + b.w / 2, b.y + b.h / 2];
};
const rot = (x, y, cx, cy, a) => {
  if (!a) return [x, y];
  const c = Math.cos(a), s = Math.sin(a), dx = x - cx, dy = y - cy;
  return [cx + dx * c - dy * s, cy + dx * s + dy * c];
};
function rotateSegs(segs, cx, cy, a) {
  if (!a) return segs;
  return segs.map((s) => {
    if (s[0] === "Z") return s;
    const out = [s[0]];
    for (let i = 1; i < s.length; i += 2) out.push(...rot(s[i], s[i + 1], cx, cy, a));
    return out;
  });
}
export function absPoints(el) { return (el.points ?? []).map(([px, py]) => [el.x + px, el.y + py]); }

// Excalidraw's corner radius: a quarter of the short side for proportional, capped at 32 for adaptive.
function radius(el) {
  const m = Math.min(Math.abs(el.width), Math.abs(el.height));
  if (!el.roundness) return 0;
  if (el.roundness.type === 3) return m <= 128 ? m * 0.25 : el.roundness.value ?? 32;
  return m * 0.25;
}

const K = 0.5522847498;
function ellipseSegs(cx, cy, rx, ry) {
  return [["M", cx + rx, cy],
    ["C", cx + rx, cy + ry * K, cx + rx * K, cy + ry, cx, cy + ry],
    ["C", cx - rx * K, cy + ry, cx - rx, cy + ry * K, cx - rx, cy],
    ["C", cx - rx, cy - ry * K, cx - rx * K, cy - ry, cx, cy - ry],
    ["C", cx + rx * K, cy - ry, cx + rx, cy - ry * K, cx + rx, cy], ["Z"]];
}

// A smooth curve through the points (Catmull-Rom as cubic Béziers), as Excalidraw draws round lines.
function curveThrough(pts) {
  const segs = [["M", ...pts[0]]];
  if (pts.length < 3) { for (const p of pts.slice(1)) segs.push(["L", ...p]); return segs; }
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] ?? p2;
    segs.push(["C", p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]]);
  }
  return segs;
}

// The element's outline: { segs, closed }. Text and images are boxes (used for hit-testing only).
export function outline(el) {
  const { x, y, width: w, height: h } = el;
  let segs, closed = true;
  if (el.type === "rectangle" || el.type === "text" || el.type === "image" || el.type === "frame") {
    const r = el.type === "rectangle" ? Math.min(radius(el), w / 2, h / 2) : 0;
    segs = r > 0 ? [["M", x + r, y], ["L", x + w - r, y], ["C", x + w - r + r * K, y, x + w, y + r - r * K, x + w, y + r],
      ["L", x + w, y + h - r], ["C", x + w, y + h - r + r * K, x + w - r + r * K, y + h, x + w - r, y + h],
      ["L", x + r, y + h], ["C", x + r - r * K, y + h, x, y + h - r + r * K, x, y + h - r],
      ["L", x, y + r], ["C", x, y + r - r * K, x + r - r * K, y, x + r, y], ["Z"]]
      : [["M", x, y], ["L", x + w, y], ["L", x + w, y + h], ["L", x, y + h], ["Z"]];
  } else if (el.type === "ellipse") {
    segs = ellipseSegs(x + w / 2, y + h / 2, w / 2, h / 2);
  } else if (el.type === "diamond") {
    segs = [["M", x + w / 2, y], ["L", x + w, y + h / 2], ["L", x + w / 2, y + h], ["L", x, y + h / 2], ["Z"]];
  } else {
    const pts = absPoints(el);
    if (!pts.length) return { segs: [], closed: false };
    closed = false;
    segs = LINEAR.has(el.type) && el.roundness && !el.elbowed ? curveThrough(pts) : [["M", ...pts[0]], ...pts.slice(1).map((p) => ["L", ...p])];
    if (pts.length === 1) segs.push(["L", pts[0][0] + 0.5, pts[0][1] + 0.5]);
    // A line whose ends meet is a closed polygon in Excalidraw and takes a fill.
    if (el.type === "line" && pts.length > 2 && Math.hypot(pts[0][0] - pts.at(-1)[0], pts[0][1] - pts.at(-1)[1]) < 1) closed = true;
  }
  const [cx, cy] = center(el);
  return { segs: rotateSegs(segs, cx, cy, el.angle), closed };
}

// Arrowheads: [{ segs, fill }] in scene coordinates, at the start and/or end of a linear element.
export function arrowheads(el, segs) {
  if (!LINEAR.has(el.type) || segs.length < 2) return [];
  const out = [];
  const end = (atStart) => {
    const kind = atStart ? el.startArrowhead : el.endArrowhead;
    if (!kind) return;
    let tip, from;
    if (atStart) {
      tip = [segs[0][1], segs[0][2]];
      const s = segs[1];
      from = s[0] === "C" ? [s[1], s[2]] : [s[1], s[2]];
    } else {
      const s = segs.at(-1);
      tip = [s.at(-2), s.at(-1)];
      const prev = segs.at(-2);
      from = s[0] === "C" ? [s[3], s[4]] : [prev.at(-2), prev.at(-1)];
    }
    let dx = tip[0] - from[0], dy = tip[1] - from[1];
    const len = Math.hypot(dx, dy) || 1;
    dx /= len; dy /= len;
    const total = polyLength(flatten(segs));
    const size = Math.min(10 + el.strokeWidth * 4, total / 2.5);
    const back = (a, k = size) => [tip[0] - k * (dx * Math.cos(a) - dy * Math.sin(a)), tip[1] - k * (dy * Math.cos(a) + dx * Math.sin(a))];
    if (kind === "triangle" || kind === "triangle_outline") {
      const a = back(0.45), b = back(-0.45);
      out.push({ segs: [["M", ...tip], ["L", ...a], ["L", ...b], ["Z"]], fill: kind === "triangle" });
    } else if (kind === "bar") {
      const a = back(Math.PI / 2, size / 2), b = back(-Math.PI / 2, size / 2);
      out.push({ segs: [["M", ...a], ["L", ...b]], fill: false });
    } else if (kind === "dot" || kind === "circle" || kind === "circle_outline") {
      const r = Math.max(3, size / 4), c = [tip[0] - dx * r, tip[1] - dy * r];
      out.push({ segs: ellipseSegs(c[0], c[1], r, r), fill: kind !== "circle_outline" });
    } else if (kind === "diamond" || kind === "diamond_outline") {
      const m = [tip[0] - dx * size / 2, tip[1] - dy * size / 2], e = [tip[0] - dx * size, tip[1] - dy * size];
      const nx = -dy * size / 4, ny = dx * size / 4;
      out.push({ segs: [["M", ...tip], ["L", m[0] + nx, m[1] + ny], ["L", ...e], ["L", m[0] - nx, m[1] - ny], ["Z"]], fill: kind === "diamond" });
    } else {
      const a = back(0.4), b = back(-0.4);
      out.push({ segs: [["M", ...a], ["L", ...tip], ["L", ...b]], fill: false });
    }
  };
  end(true); end(false);
  return out;
}

// Segments as a polyline (Béziers sampled), for distances and lengths.
export function flatten(segs) {
  const pts = [];
  let cur = null, start = null;
  for (const s of segs) {
    if (s[0] === "M") { cur = [s[1], s[2]]; start = cur; pts.push(cur); }
    else if (s[0] === "L") { cur = [s[1], s[2]]; pts.push(cur); }
    else if (s[0] === "C") {
      const [x0, y0] = cur;
      for (let i = 1; i <= 10; i++) {
        const t = i / 10, u = 1 - t;
        pts.push([u * u * u * x0 + 3 * u * u * t * s[1] + 3 * u * t * t * s[3] + t * t * t * s[5],
          u * u * u * y0 + 3 * u * u * t * s[2] + 3 * u * t * t * s[4] + t * t * t * s[6]]);
      }
      cur = [s[5], s[6]];
    } else if (s[0] === "Z" && start) pts.push(start);
  }
  return pts;
}
const polyLength = (pts) => pts.reduce((n, p, i) => (i ? n + Math.hypot(p[0] - pts[i - 1][0], p[1] - pts[i - 1][1]) : 0), 0);
function distToSeg(px, py, [ax, ay], [bx, by]) {
  const dx = bx - ax, dy = by - ay, l = dx * dx + dy * dy;
  const t = l ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / l)) : 0;
  return Math.hypot(px - ax - t * dx, py - ay - t * dy);
}
export const distToPoly = (px, py, pts) => {
  let d = Infinity;
  for (let i = 1; i < pts.length; i++) d = Math.min(d, distToSeg(px, py, pts[i - 1], pts[i]));
  return pts.length === 1 ? Math.hypot(px - pts[0][0], py - pts[0][1]) : d;
};

// The axis-aligned box around an element. `raw` skips rotation (the element's own frame).
export function bounds(el, raw = false) {
  let x0, y0, x1, y1;
  if (el.points && (LINEAR.has(el.type) || el.type === "freedraw")) {
    const pts = absPoints(el);
    x0 = Math.min(...pts.map((p) => p[0])); x1 = Math.max(...pts.map((p) => p[0]));
    y0 = Math.min(...pts.map((p) => p[1])); y1 = Math.max(...pts.map((p) => p[1]));
  } else { x0 = el.x; y0 = el.y; x1 = el.x + el.width; y1 = el.y + el.height; }
  if (!raw && el.angle) {
    const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
    const c = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]].map(([x, y]) => rot(x, y, cx, cy, el.angle));
    x0 = Math.min(...c.map((p) => p[0])); x1 = Math.max(...c.map((p) => p[0]));
    y0 = Math.min(...c.map((p) => p[1])); y1 = Math.max(...c.map((p) => p[1]));
  }
  return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
}
export function unionBounds(els) {
  if (!els.length) return null;
  const bs = els.map((e) => bounds(e));
  const x = Math.min(...bs.map((b) => b.x)), y = Math.min(...bs.map((b) => b.y));
  return { x, y, w: Math.max(...bs.map((b) => b.x + b.w)) - x, h: Math.max(...bs.map((b) => b.y + b.h)) - y };
}

// Whether the point is inside the element's own shape (in its unrotated frame).
function inside(el, px, py) {
  const [cx, cy] = center(el);
  [px, py] = rot(px, py, cx, cy, -(el.angle || 0));
  const { x, y, width: w, height: h } = el;
  if (el.type === "ellipse") { const nx = (px - cx) / (w / 2 || 1), ny = (py - cy) / (h / 2 || 1); return nx * nx + ny * ny <= 1; }
  if (el.type === "diamond") return Math.abs(px - cx) / (w / 2 || 1) + Math.abs(py - cy) / (h / 2 || 1) <= 1;
  return px >= x && px <= x + w && py >= y && py <= y + h;
}

// "hit": on the stroke, or inside something solid. "body": inside a hollow shape (a weaker hit).
export function hitTest(el, px, py, tol) {
  if (el.type === "text" || el.type === "image" || el.type === "frame") {
    const b = bounds(el);
    return px >= b.x - tol && px <= b.x + b.w + tol && py >= b.y - tol && py <= b.y + b.h + tol ? "hit" : null;
  }
  const { segs } = outline(el);
  const near = distToPoly(px, py, flatten(segs)) <= tol + (el.strokeWidth ?? 1) / 2 + (el.type === "freedraw" ? el.strokeWidth : 0);
  if (near) return "hit";
  if (SHAPES.has(el.type) && inside(el, px, py)) return el.backgroundColor && el.backgroundColor !== "transparent" ? "hit" : "body";
  return null;
}

// ---------- binding ----------

export const bindable = (el) => BINDABLE.has(el.type) && !el.containerId;

// Where a ray from the shape's center toward `to` leaves the shape, pushed out by `gap`.
export function edgePoint(shape, to, gap = 4) {
  const b = bounds(shape, true), cx = b.x + b.w / 2, cy = b.y + b.h / 2;
  let dx = to[0] - cx, dy = to[1] - cy;
  if (!dx && !dy) return [cx, cy];
  const hw = b.w / 2 || 1, hh = b.h / 2 || 1;
  let t;
  if (shape.type === "ellipse") t = 1 / Math.sqrt((dx / hw) ** 2 + (dy / hh) ** 2);
  else if (shape.type === "diamond") t = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
  else t = Math.min(dx ? hw / Math.abs(dx) : Infinity, dy ? hh / Math.abs(dy) : Infinity);
  const len = Math.hypot(dx, dy);
  return [cx + dx * t + (dx / len) * gap, cy + dy * t + (dy / len) * gap];
}

export function setPointsAbs(el, abs) {
  el.x = abs[0][0]; el.y = abs[0][1];
  el.points = abs.map(([x, y]) => [x - el.x, y - el.y]);
  const b = bounds({ ...el, angle: 0 });
  el.width = b.w; el.height = b.h;
}

// Re-aim the bound ends of `arrow` at the shapes they're bound to.
export function reroute(arrow, byId) {
  const s = arrow.startBinding && byId.get(arrow.startBinding.elementId);
  const e = arrow.endBinding && byId.get(arrow.endBinding.elementId);
  if (!s && !e) return;
  const abs = absPoints(arrow);
  if (abs.length < 2) return;
  const two = abs.length === 2;
  if (s) abs[0] = edgePoint(s, two && e ? center(e) : abs[1], arrow.startBinding.gap ?? 4);
  if (e) abs[abs.length - 1] = edgePoint(e, two && s ? center(s) : abs[abs.length - 2], arrow.endBinding.gap ?? 4);
  setPointsAbs(arrow, abs);
  touch(arrow);
}

export function addBound(el, id, type) {
  el.boundElements = [...(el.boundElements ?? []).filter((b) => b.id !== id), { id, type }];
}
export function removeBound(el, id) {
  if (!el?.boundElements) return;
  el.boundElements = el.boundElements.filter((b) => b.id !== id);
  if (!el.boundElements.length) el.boundElements = null;
}
export const boundText = (el, byId) => (el.boundElements ?? []).filter((b) => b.type === "text").map((b) => byId.get(b.id)).find(Boolean);

// Wrap and center a label inside its container (a shape, or the middle of an arrow).
export function layoutLabel(text, container) {
  const raw = text.originalText ?? text.text;
  if (LINEAR.has(container.type)) {
    text.text = raw;
    const m = measure(raw, text.fontSize, text.fontFamily);
    const pts = flatten(outline(container).segs), mid = midpoint(pts);
    Object.assign(text, { width: m.width, height: m.height, x: mid[0] - m.width / 2, y: mid[1] - m.height / 2, textAlign: "center", verticalAlign: "middle" });
    return;
  }
  const b = bounds(container, true);
  const room = container.type === "ellipse" ? b.w * 0.7 : container.type === "diamond" ? b.w * 0.5 : b.w - PAD * 2;
  text.text = wrap(raw, Math.max(20, room), text.fontSize, text.fontFamily);
  const m = measure(text.text, text.fontSize, text.fontFamily);
  Object.assign(text, {
    width: Math.min(m.width, Math.max(room, 1)), height: m.height, angle: container.angle || 0,
    x: b.x + b.w / 2 - Math.min(m.width, Math.max(room, 1)) / 2, y: b.y + b.h / 2 - m.height / 2,
    textAlign: "center", verticalAlign: "middle",
  });
}
function midpoint(pts) {
  const total = polyLength(pts);
  let run = 0;
  for (let i = 1; i < pts.length; i++) {
    const d = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    if (run + d >= total / 2) { const t = (total / 2 - run) / (d || 1); return [pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * t, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * t]; }
    run += d;
  }
  return pts[0] ?? [0, 0];
}

// ---------- color ----------

// Excalidraw's dark mode: the canvas is drawn through `invert(93%) hue-rotate(180deg)`.
export function darkColor(c) {
  const m = /^#([0-9a-f]{3,8})$/i.exec(c ?? "");
  if (!m) return c;
  let h = m[1];
  if (h.length <= 4) h = [...h].map((ch) => ch + ch).join("");
  let [r, g, b] = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
  const alpha = h.length === 8 ? h.slice(6) : "";
  [r, g, b] = [r, g, b].map((v) => 0.93 + v * (1 - 1.86));
  const R = -0.574 * r + 1.43 * g + 0.144 * b, G = 0.426 * r + 0.43 * g + 0.144 * b, B = 0.426 * r + 1.43 * g - 0.856 * b;
  const hex = (v) => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
  return `#${hex(R)}${hex(G)}${hex(B)}${alpha}`;
}

export const fontStack = (family) => (MONO.has(family) ? "code" : family === 2 || family === 6 ? "sans" : family === 7 ? "display" : "hand");
