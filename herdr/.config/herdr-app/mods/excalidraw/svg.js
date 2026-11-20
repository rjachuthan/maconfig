// SVG export: the scene in its own (light) colors, cropped to its content with a margin.
import { outline, arrowheads, unionBounds, LINE_HEIGHT, LINEAR } from "./scene.js";

const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const num = (n) => +n.toFixed(2);
export const pathData = (segs) => segs.map((s) => s[0] + s.slice(1).map(num).join(" ")).join(" ");
const FONTS = { hand: "Excalifont, Virgil, Comic Sans MS, Segoe UI Emoji, sans-serif", sans: "Nunito, Helvetica, Arial, sans-serif", code: "Comic Shanns, Cascadia Code, monospace", display: "Lilita One, sans-serif" };
const fontOf = (f) => (f === 3 || f === 8 ? FONTS.code : f === 2 || f === 6 ? FONTS.sans : f === 7 ? FONTS.display : FONTS.hand);
const dashOf = (el) => (el.strokeStyle === "dashed" ? `${8} ${8 + el.strokeWidth}` : el.strokeStyle === "dotted" ? `${1.5} ${6 + el.strokeWidth}` : null);

export function toSVG(elements, files, background, pad = 10) {
  const els = elements.filter((e) => !e.isDeleted);
  const box = unionBounds(els) ?? { x: 0, y: 0, w: 100, h: 100 };
  const x0 = box.x - pad, y0 = box.y - pad, W = box.w + pad * 2, H = box.h + pad * 2;
  const defs = new Map(), body = [];
  const pattern = (color, dense) => {
    const id = `hatch-${dense ? "x" : "h"}-${color.replace(/[^0-9a-z]/gi, "")}`;
    if (!defs.has(id)) defs.set(id, `<pattern id="${id}" patternUnits="userSpaceOnUse" width="8" height="8" patternTransform="rotate(-45)"><line x1="0" y1="0" x2="0" y2="8" stroke="${esc(color)}" stroke-width="1.5"/>${dense ? `<line x1="0" y1="0" x2="8" y2="0" stroke="${esc(color)}" stroke-width="1.5"/>` : ""}</pattern>`);
    return `url(#${id})`;
  };
  for (const el of els) {
    const op = (el.opacity ?? 100) / 100, opacity = op < 1 ? ` opacity="${op}"` : "";
    if (el.type === "text") {
      const lines = String(el.text ?? "").split("\n"), lh = el.fontSize * (el.lineHeight ?? LINE_HEIGHT);
      const anchor = el.textAlign === "center" ? "middle" : el.textAlign === "right" ? "end" : "start";
      const tx = el.textAlign === "center" ? el.x + el.width / 2 : el.textAlign === "right" ? el.x + el.width : el.x;
      const rotate = el.angle ? ` transform="rotate(${num(el.angle * 180 / Math.PI)} ${num(el.x + el.width / 2)} ${num(el.y + el.height / 2)})"` : "";
      body.push(`<text x="${num(tx)}" font-family="${esc(fontOf(el.fontFamily))}" font-size="${el.fontSize}" fill="${esc(el.strokeColor)}" text-anchor="${anchor}"${opacity}${rotate}>`
        + lines.map((l, i) => `<tspan x="${num(tx)}" y="${num(el.y + i * lh + lh / 2 + el.fontSize * 0.35)}">${esc(l) || " "}</tspan>`).join("") + `</text>`);
      continue;
    }
    if (el.type === "image") {
      const f = files?.[el.fileId];
      if (f?.dataURL) body.push(`<image href="${esc(f.dataURL)}" x="${num(el.x)}" y="${num(el.y)}" width="${num(el.width)}" height="${num(el.height)}" preserveAspectRatio="none"${opacity}/>`);
      continue;
    }
    const { segs, closed } = outline(el);
    if (!segs.length) continue;
    const d = pathData(segs), bg = el.backgroundColor;
    if (closed && bg && bg !== "transparent") {
      const fill = el.fillStyle === "solid" ? bg : pattern(bg, el.fillStyle === "cross-hatch");
      body.push(`<path d="${d}" fill="${esc(fill)}" stroke="none"${opacity}/>`);
    }
    const width = el.type === "freedraw" ? el.strokeWidth * 1.6 : el.strokeWidth, dash = dashOf(el);
    body.push(`<path d="${d}" fill="none" stroke="${esc(el.strokeColor)}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"${dash ? ` stroke-dasharray="${dash}"` : ""}${opacity}/>`);
    if (LINEAR.has(el.type)) for (const head of arrowheads(el, segs))
      body.push(`<path d="${pathData(head.segs)}" fill="${head.fill ? esc(el.strokeColor) : "none"}" stroke="${esc(el.strokeColor)}" stroke-width="${el.strokeWidth}" stroke-linecap="round" stroke-linejoin="round"${opacity}/>`);
  }
  return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="${num(x0)} ${num(y0)} ${num(W)} ${num(H)}" width="${num(W)}" height="${num(H)}">\n`
    + (defs.size ? `<defs>${[...defs.values()].join("")}</defs>\n` : "")
    + `<rect x="${num(x0)}" y="${num(y0)}" width="${num(W)}" height="${num(H)}" fill="${esc(background || "#ffffff")}"/>\n`
    + body.join("\n") + `\n</svg>\n`;
}
