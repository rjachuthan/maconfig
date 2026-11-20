// An .excalidraw file as a tab: view, draw, edit and save diagrams without leaving Herdr.
// Herdr mods can't host a web view, so this is a native editor over the same file format:
// files round-trip with excalidraw.com and the Obsidian/VS Code plugins.
// Opened with tab.new { mod: "excalidraw", props: { file } } (Neovim's `o`) or { root, path, on } (gentle-files).
import { View, div, svg, image, PathBuilder, Background } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea } from "gpui-base";
import { props, readTextFile, writeTextFile, theme, settings, exec, run, spaces, panes, shared, setShared, appHome, checking, window as host } from "herdr";
import { createHash } from "crypto";
import * as fs from "fs/promises";
import { Buffer } from "buffer";
import * as S from "./scene.js";
import { toSVG } from "./svg.js";

const ICON = (n) => `mods/excalidraw/icons/${n}.svg`;
const TOOLS = [["select", "V"], ["hand", "H"], ["rectangle", "R"], ["diamond", "D"], ["ellipse", "O"], ["arrow", "A"], ["line", "L"], ["freedraw", "P"], ["text", "T"], ["eraser", "E"]];
const KEYS = { v: "select", 1: "select", h: "hand", r: "rectangle", 2: "rectangle", d: "diamond", 3: "diamond", o: "ellipse", 4: "ellipse",
  a: "arrow", 5: "arrow", l: "line", 6: "line", p: "freedraw", x: "freedraw", 7: "freedraw", t: "text", 8: "text", e: "eraser", 0: "eraser" };
const HINTS = {
  select: "Click to select · drag to move · double-click to add text · Alt-drag duplicates",
  hand: "Drag to pan · scroll pans anywhere, ⌘/Ctrl-scroll zooms",
  rectangle: "Drag to draw · Shift for a square", diamond: "Drag to draw · Shift keeps proportions", ellipse: "Drag to draw · Shift for a circle",
  arrow: "Drag from a shape to another to connect them · Shift snaps the angle", line: "Drag to draw · Shift snaps the angle",
  freedraw: "Drag to sketch", text: "Click to place text · ⌘/Ctrl-Enter or Esc to finish", eraser: "Click or drag over elements to erase",
};
const LIMIT = 1048576;
const HISTORY = 100;
const TOL = 6;      // hit tolerance, screen px
const GRIP = 9;     // handle size, screen px
const MIN_Z = 0.1, MAX_Z = 30;
const IMAGE_DIR = "data/excalidraw/images";
const BLANK = () => ({ type: "excalidraw", version: 2, source: "https://excalidraw.com", elements: [], appState: { gridSize: 20, viewBackgroundColor: "#ffffff" }, files: {} });
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

export default class Excalidraw extends View {
  // Setting dirty also renames the tab ("● name" while unsaved), as gentle-editor does.
  get dirty() { return this._dirty; }
  set dirty(value) {
    if (value === this._dirty) return;
    this._dirty = value;
    if (this.tabId) run("tab.rename", { id: this.tabId, name: value ? `● ${this.name}` : this.name });
  }

  init(_props, cx) {
    const p = props() ?? {};
    this.on = p.on ?? null;
    this.full = p.file ?? (p.path ? (p.root ? `${p.root}/${p.path}` : p.path) : null);
    this.name = this.full ? this.full.split(/[\\/]/).pop() : "Untitled.excalidraw";
    this.dir = this.full ? this.full.slice(0, Math.max(0, this.full.length - this.name.length - 1)) : "";
    this.doc = null; this.els = []; this.files = {};
    this.saved = undefined;   // the text last read or written: writeTextFile's guard (null: a new file)
    this.clean = "[]";        // JSON of the elements as saved, for the dirty flag
    this._dirty = false;
    this.cam = { ox: 0, oy: 0, z: 1 }; this.fitPending = true; this.size = null;
    this.sel = new Set(); this.tool = "select"; this.toolLock = false;
    this.style = { ...S.DEFAULT_STYLE };
    this.drag = null; this.edit = null; this.pending = null;
    this.undoStack = []; this.redoStack = [];
    this.canvasTheme = null;  // null follows Herdr; "light" or "dark" pins it
    this.images = {};         // fileId → image path under the app home (null while it's being written)
    this.cursor = "default"; this.pointer = [0, 0]; this.spaceHeld = false;
    this.handFont = null; this.message = null; this.error = null; this.conflict = false;
    this.tabId = null;
    this.handle = cx.focus_handle();
    this.findHandFont(cx);
    this.load(cx);
    this.claimTab(cx, 0);
  }

  // Its own tab. A new tab is focused and listed a moment after the mod starts: the focused excalidraw pane
  // no other copy has claimed. When none turns up (a reload restarts every copy), the tab registered for its file.
  findTab(tries) {
    const claimed = new Set(Object.values(shared("excalidraw.tabs") ?? {}));
    const fresh = panes().find((q) => q.mod === "excalidraw" && q.focused && !claimed.has(q.tab));
    if (fresh) return fresh.tab;
    const known = shared("excalidraw.tabs")?.[this.full];
    return tries >= 5 && known && panes().some((q) => q.tab === known && q.mod === "excalidraw") ? known : null;
  }
  claimTab(cx, tries) {
    if (checking()) return;
    this.tabId = this.findTab(tries);
    if (!this.tabId) { if (tries < 20) cx.timer.after(100, (cx) => this.claimTab(cx, tries + 1)); return; }
    if (!this.dedupe() && this._dirty) run("tab.rename", { id: this.tabId, name: `● ${this.name}` });
  }

  // A file already open in another tab: show that one and close this.
  dedupe() {
    if (!this.full || !this.tabId || checking()) return false;
    const reg = { ...(shared("excalidraw.tabs") ?? {}) }, other = reg[this.full];
    if (other && other !== this.tabId && spaces().some((s) => s.tabs.some((c) => c.id === other))) {
      this.duplicateTab = true;
      run("tab.select", { id: other });
      run("tab.close", { id: this.tabId, confirmed: true });
      return true;
    }
    reg[this.full] = this.tabId;
    setShared("excalidraw.tabs", reg);
    return false;
  }

  async close() {
    if (!this.full || this.duplicateTab) return;
    const reg = { ...(shared("excalidraw.tabs") ?? {}) };
    if (reg[this.full] === this.tabId) { delete reg[this.full]; setShared("excalidraw.tabs", reg); }
  }

  // Excalidraw's handwriting fonts when installed (Excalifont, Virgil), else Comic Sans where it ships, else the UI font.
  findHandFont(cx) {
    if (checking()) return;
    const platform = host()?.platform;
    this.handFont = platform === "macos" || platform === "windows" ? "Comic Sans MS" : null;
    cx.spawn(async (cx) => {
      const r = platform === "windows"
        ? await exec("powershell", ["-NoProfile", "-Command", "Get-ChildItem C:/Windows/Fonts, $env:LOCALAPPDATA/Microsoft/Windows/Fonts -Name -ErrorAction SilentlyContinue"]).catch(() => null)
        : await exec("sh", ["-c", 'ls "$HOME/Library/Fonts" /Library/Fonts "$HOME/.local/share/fonts" 2>/dev/null; fc-list : family 2>/dev/null']).catch(() => null);
      const names = r?.stdout ?? "";
      if (/excalifont/i.test(names)) this.handFont = "Excalifont";
      else if (/virgil/i.test(names)) this.handFont = "Virgil";
      cx.notify();
    });
  }

  // ---------- file ----------

  load(cx) {
    cx.spawn(async (cx) => {
      try {
        let text = this.full ? await readTextFile(this.full, { on: this.on }) : null;
        if (text && text.length >= LIMIT - 4 && !this.on) text = await fs.readFile(this.full, "utf8").catch(() => text);
        this.readonly = this.on ? "Remote file · view only" : !this.full ? "No file" : null;
        if (text === null || !text.trim()) { this.doc = BLANK(); this.saved = text; }
        else {
          const doc = JSON.parse(text);
          if (!doc || !Array.isArray(doc.elements)) throw new Error("not an Excalidraw scene");
          this.doc = doc; this.saved = text;
        }
        this.els = this.doc.elements.filter((e) => e && !e.isDeleted);
        this.files = this.doc.files ?? {};
        this.clean = JSON.stringify(this.els);
        this.undoStack = []; this.redoStack = []; this.sel.clear();
        this.dirty = false; this.conflict = false; this.error = null; this.fitPending = true;
        this.loadImages(cx);
      } catch (e) { this.error = `Cannot open this file: ${e?.message ?? e}`; }
      finally { cx.notify(); }
    });
  }

  serialize() {
    if (this.reordered) for (const e of this.els) delete e.index; // Excalidraw regenerates fractional indices
    const used = new Set(this.els.filter((e) => e.type === "image").map((e) => e.fileId));
    const files = Object.fromEntries(Object.entries(this.files).filter(([id]) => used.has(id)));
    const doc = { ...this.doc, type: "excalidraw", version: this.doc.version ?? 2, source: this.doc.source ?? "https://excalidraw.com",
      elements: this.els, appState: { ...(this.doc.appState ?? {}), viewBackgroundColor: this.viewBg() }, files };
    return JSON.stringify(doc, null, 2);
  }

  writable() { return this.doc && !this.readonly && !this.error; }

  save(cx) {
    if (!this.writable() || this.edit) return;
    const text = this.serialize(), els = JSON.stringify(this.els);
    cx.spawn(async (cx) => {
      try {
        await writeTextFile(this.full, text, this.saved ?? null);
        this.saved = text; this.clean = els; this.reordered = false;
        this.dirty = JSON.stringify(this.els) !== els; this.conflict = false;
        this.flash("Saved", cx);
      } catch { this.conflict = true; }
      finally { cx.notify(); }
    });
  }

  // "Keep mine": the disk text becomes the guard, then the scene is written over it.
  overwrite(cx) {
    const text = this.serialize(), els = JSON.stringify(this.els);
    cx.spawn(async (cx) => {
      try {
        const disk = await readTextFile(this.full);
        await writeTextFile(this.full, text, disk);
        this.saved = text; this.clean = els; this.dirty = false; this.conflict = false;
        this.flash("Saved", cx);
      } catch { this.error = "Could not save this file"; }
      finally { cx.notify(); }
    });
  }

  exportAs(kind, cx) {
    if (!this.doc || !this.full || this.on) return;
    const base = this.full.replace(/\.excalidraw(\.json)?$/i, ""), short = base.split(/[\\/]/).pop();
    const text = toSVG(this.els, this.files, this.viewBg());
    cx.spawn(async (cx) => {
      try {
        if (kind === "svg") {
          await writeTextFile(`${base}.svg`, text, await readTextFile(`${base}.svg`));
          this.flash(`Exported ${short}.svg`, cx);
        } else {
          const dir = `${appHome()}/data/excalidraw`, tmp = `${dir}/export-${Date.now()}.svg`, out = `${base}.png`;
          await fs.mkdir(dir, { recursive: true });
          await fs.writeFile(tmp, text);
          let done = false;
          for (const [cmd, args] of [["rsvg-convert", ["-z", "2", "-o", out, tmp]], ["resvg", ["--zoom", "2", tmp, out]], ["magick", ["-density", "192", "-background", "none", tmp, out]]]) {
            try { if ((await exec(cmd, args, { timeout: 60000 })).code === 0) { done = true; break; } } catch { /* not installed */ }
          }
          await fs.unlink(tmp).catch(() => {});
          this.flash(done ? `Exported ${short}.png` : "PNG export needs rsvg-convert, resvg or ImageMagick", cx);
        }
      } catch (e) { this.flash(`Export failed: ${e?.message ?? e}`, cx); }
      finally { cx.notify(); }
    });
  }

  flash(message, cx) {
    this.message = message;
    cx.timer.after(2500, (cx) => { if (this.message === message) { this.message = null; cx.notify(); } });
  }

  // Embedded images (data URLs in `files`) are written once under the app home, where image() can read them.
  loadImages(cx) {
    if (checking()) return;
    for (const el of this.els) {
      const f = el.type === "image" && this.files[el.fileId];
      if (!f?.dataURL || el.fileId in this.images) continue;
      const m = /^data:image\/(png|jpeg|jpg|gif|webp|svg\+xml);base64,(.*)$/s.exec(f.dataURL);
      if (!m) continue;
      this.images[el.fileId] = null;
      const ext = m[1] === "svg+xml" ? "svg" : m[1] === "jpeg" ? "jpg" : m[1];
      const rel = `${IMAGE_DIR}/${el.fileId.replace(/[^\w-]/g, "_")}.${ext}`, abs = `${appHome()}/${rel}`;
      cx.spawn(async (cx) => {
        try {
          if (!(await fs.exists(abs))) {
            await fs.mkdir(`${appHome()}/${IMAGE_DIR}`, { recursive: true });
            await fs.writeFile(abs, Buffer.from(m[2], "base64"));
          }
          this.images[el.fileId] = rel;
        } catch { /* stays a placeholder */ }
        cx.notify();
      });
    }
  }

  // Images dropped from Finder/Explorer become image elements at the drop point.
  dropFiles(paths, at, cx) {
    if (!this.writable()) return;
    const TYPES = { png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", gif: "image/gif", webp: "image/webp", svg: "image/svg+xml" };
    cx.spawn(async (cx) => {
      let [x, y] = at;
      for (const path of paths) {
        const mime = TYPES[path.split(".").pop().toLowerCase()];
        if (!mime) continue;
        try {
          const bytes = await fs.readFile(path);
          const [w, h] = imageSize(bytes) ?? [300, 200];
          const scale = Math.min(1, 600 / Math.max(w, h));
          const fileId = createHash("sha1").update(bytes).digest("hex");
          this.files[fileId] = { mimeType: mime, id: fileId, dataURL: `data:${mime};base64,${Buffer.from(bytes).toString("base64")}`, created: Date.now(), lastRetrieved: Date.now() };
          this.mutate(() => {
            const el = S.newElement("image", x, y, this.style);
            Object.assign(el, { width: w * scale, height: h * scale, fileId, status: "saved", scale: [1, 1], strokeColor: "transparent", backgroundColor: "transparent" });
            this.els.push(el); this.sel = new Set([el.id]);
          });
          x += 24; y += 24;
        } catch (e) { this.flash(`Cannot add ${path.split(/[\\/]/).pop()}: ${e?.message ?? e}`, cx); }
      }
      this.loadImages(cx);
      cx.notify();
    });
  }

  // ---------- history ----------

  begin() { if (this.pending == null) this.pending = JSON.stringify(this.els); }
  commit() {
    if (this.pending == null) return;
    const now = JSON.stringify(this.els);
    if (now !== this.pending) {
      this.undoStack.push(this.pending);
      if (this.undoStack.length > HISTORY) this.undoStack.shift();
      this.redoStack = [];
    }
    this.pending = null;
    this.dirty = now !== this.clean;
  }
  mutate(fn) { if (!this.writable()) return; this.begin(); fn(); this.commit(); }
  restore(from, to) {
    if (!from.length || !this.writable()) return;
    to.push(JSON.stringify(this.els));
    this.els = JSON.parse(from.pop());
    const ids = new Set(this.els.map((e) => e.id));
    this.sel = new Set([...this.sel].filter((id) => ids.has(id)));
    this.dirty = JSON.stringify(this.els) !== this.clean;
  }

  // ---------- coordinates ----------

  // Pointer positions come in window units; layout sizes are these units times Herdr's zoom.
  unit() { return settings().zoom ?? 1; }
  local(e) { const u = this.unit(), p = e.local_position ?? { x: 0, y: 0 }; return [p.x / u, p.y / u]; }
  toScene([sx, sy]) { const { ox, oy, z } = this.cam; return [(sx - ox) / z, (sy - oy) / z]; }
  sx(x) { return x * this.cam.z + this.cam.ox; }
  sy(y) { return y * this.cam.z + this.cam.oy; }

  fit() {
    if (!this.size) return;
    const b = S.unionBounds(this.els), { w, h } = this.size;
    if (!b) { this.cam = { ox: 0, oy: 0, z: 1 }; return; }
    const z = clamp(Math.min(1, (w - 120) / (b.w || 1), (h - 160) / (b.h || 1)), MIN_Z, MAX_Z);
    this.cam = { z, ox: w / 2 - (b.x + b.w / 2) * z, oy: h / 2 + 10 - (b.y + b.h / 2) * z };
  }
  zoomAt([sx, sy], factor) {
    const z = clamp(this.cam.z * factor, MIN_Z, MAX_Z), k = z / this.cam.z;
    this.cam = { z, ox: sx - (sx - this.cam.ox) * k, oy: sy - (sy - this.cam.oy) * k };
  }
  zoomCenter(factor) { if (this.size) this.zoomAt([this.size.w / 2, this.size.h / 2], factor); }

  // ---------- scene queries ----------

  byId() { return new Map(this.els.map((e) => [e.id, e])); }
  selected() { return this.els.filter((e) => this.sel.has(e.id)); }
  // The selection plus labels of selected containers: what moves, copies and deletes together.
  withLabels(ids = this.sel) {
    const out = new Set(ids), byId = this.byId();
    for (const id of ids) for (const b of byId.get(id)?.boundElements ?? []) if (b.type === "text") out.add(b.id);
    return out;
  }
  groupOf(el) {
    const g = el.groupIds?.at(-1);
    return g ? this.els.filter((e) => e.groupIds?.includes(g)) : [el];
  }

  // The topmost element under a scene point; a label stands for its container.
  pick(x, y, test = () => true) {
    const tol = TOL / this.cam.z;
    let body = null;
    for (let i = this.els.length - 1; i >= 0; i--) {
      const el = this.els[i];
      if (el.locked || !test(el)) continue;
      const hit = S.hitTest(el, x, y, tol);
      if (hit === "hit") return el.containerId ? this.byId().get(el.containerId) ?? el : el;
      if (hit === "body" && !body) body = el;
    }
    return body;
  }
  bindTarget(p, exclude) { return this.pick(p[0], p[1], (e) => S.bindable(e) && e.id !== exclude); }

  selBox() { const s = this.selected(); return s.length ? S.unionBounds(s) : null; }
  singleLinear() { const s = this.selected(); return s.length === 1 && S.LINEAR.has(s[0].type) ? s[0] : null; }

  // Corner handles of the selection box, in screen coordinates.
  grips() {
    const b = this.selBox();
    if (!b || this.singleLinear()) return [];
    const x0 = this.sx(b.x) - 4, y0 = this.sy(b.y) - 4, x1 = this.sx(b.x + b.w) + 4, y1 = this.sy(b.y + b.h) + 4;
    return [["nw", x0, y0], ["ne", x1, y0], ["sw", x0, y1], ["se", x1, y1]];
  }
  gripAt([sx, sy]) { return this.grips().find(([, x, y]) => Math.abs(sx - x) <= GRIP && Math.abs(sy - y) <= GRIP)?.[0] ?? null; }

  // A linear element's points (and the midpoints that add one), in screen coordinates.
  pointGrips() {
    const el = this.singleLinear();
    if (!el) return [];
    const pts = S.absPoints(el).map(([x, y]) => [this.sx(x), this.sy(y)]);
    const out = pts.map((p, i) => ({ index: i, x: p[0], y: p[1], mid: false }));
    for (let i = 1; i < pts.length; i++) {
      const mx = (pts[i - 1][0] + pts[i][0]) / 2, my = (pts[i - 1][1] + pts[i][1]) / 2;
      if (Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]) > 30) out.push({ index: i, x: mx, y: my, mid: true });
    }
    return out;
  }
  pointAt([sx, sy]) { return this.pointGrips().find((g) => Math.hypot(sx - g.x, sy - g.y) <= GRIP) ?? null; }

  // ---------- scene edits ----------

  bind(arrow, end, shape) {
    const key = `${end}Binding`, old = arrow[key];
    if (old?.elementId === shape?.id) return;
    if (old) {
      arrow[key] = null;
      const other = arrow[end === "start" ? "endBinding" : "startBinding"];
      if (other?.elementId !== old.elementId) S.removeBound(this.byId().get(old.elementId), arrow.id);
    }
    if (shape) { arrow[key] = { elementId: shape.id, focus: 0, gap: 4 }; S.addBound(shape, arrow.id, "arrow"); S.touch(shape); }
  }

  // Arrows bound to any of `ids` (and not moving with them) re-aim at their shapes; their labels follow.
  follow(ids) {
    const byId = this.byId();
    for (const a of this.els) {
      if (!S.LINEAR.has(a.type) || ids.has(a.id)) continue;
      if (!(a.startBinding && ids.has(a.startBinding.elementId)) && !(a.endBinding && ids.has(a.endBinding.elementId))) continue;
      S.reroute(a, byId);
      const label = S.boundText(a, byId);
      if (label) S.layoutLabel(label, a);
    }
  }

  removeIds(ids) {
    ids = this.withLabels(ids);
    const byId = this.byId();
    for (const id of ids) {
      const el = byId.get(id);
      if (!el) continue;
      if (el.containerId && !ids.has(el.containerId)) S.removeBound(byId.get(el.containerId), id);
      for (const end of ["startBinding", "endBinding"]) if (el[end]) S.removeBound(byId.get(el[end].elementId), id);
      for (const b of el.boundElements ?? []) {
        const a = b.type === "arrow" && byId.get(b.id);
        if (!a) continue;
        if (a.startBinding?.elementId === id) a.startBinding = null;
        if (a.endBinding?.elementId === id) a.endBinding = null;
      }
    }
    this.els = this.els.filter((e) => !ids.has(e.id));
    for (const id of ids) this.sel.delete(id);
  }

  // Copies with fresh ids, keeping bindings, labels and groups that stay within the copied set.
  cloneSet(els, dx, dy) {
    const ids = new Map(els.map((e) => [e.id, S.newId()])), groups = new Map();
    return els.map((e) => {
      const c = JSON.parse(JSON.stringify(e));
      c.id = ids.get(e.id); c.x += dx; c.y += dy; delete c.index;
      c.seed = Math.floor(Math.random() * 2 ** 31); S.touch(c);
      c.groupIds = (c.groupIds ?? []).map((g) => groups.get(g) ?? groups.set(g, S.newId()).get(g));
      if (c.containerId) c.containerId = ids.get(c.containerId) ?? null;
      if (c.boundElements) { c.boundElements = c.boundElements.filter((b) => ids.has(b.id)).map((b) => ({ ...b, id: ids.get(b.id) })); if (!c.boundElements.length) c.boundElements = null; }
      for (const end of ["startBinding", "endBinding"]) if (c[end]) c[end] = ids.has(c[end].elementId) ? { ...c[end], elementId: ids.get(c[end].elementId) } : null;
      return c;
    });
  }

  duplicate() {
    this.mutate(() => {
      const ids = this.withLabels(), src = this.els.filter((e) => ids.has(e.id));
      const copies = this.cloneSet(src, 10, 10);
      this.els.push(...copies);
      this.sel = new Set(copies.filter((c) => !c.containerId).map((c) => c.id));
    });
  }

  copy(cx) {
    const ids = this.withLabels(), elements = this.els.filter((e) => ids.has(e.id));
    if (!elements.length) return;
    const files = Object.fromEntries(elements.filter((e) => e.type === "image" && this.files[e.fileId]).map((e) => [e.fileId, this.files[e.fileId]]));
    // Excalidraw's own clipboard format: pastes into excalidraw.com too.
    cx.write_to_clipboard(JSON.stringify({ type: "excalidraw/clipboard", elements, files }));
  }

  paste(cx) {
    const text = cx.read_from_clipboard();
    if (!text || !this.writable()) return;
    let data = null;
    try { data = JSON.parse(text); } catch { /* plain text */ }
    const [px, py] = this.pointer;
    this.mutate(() => {
      if (data && Array.isArray(data.elements) && (data.type === "excalidraw/clipboard" || data.type === "excalidraw")) {
        const src = data.elements.filter((e) => e && !e.isDeleted), b = S.unionBounds(src);
        if (!b) return;
        Object.assign(this.files, data.files ?? {});
        const copies = this.cloneSet(src, px - (b.x + b.w / 2), py - (b.y + b.h / 2));
        this.els.push(...copies);
        this.sel = new Set(copies.filter((c) => !c.containerId).map((c) => c.id));
      } else {
        const el = S.newElement("text", px, py, { ...this.style, backgroundColor: "transparent" });
        el.text = el.originalText = text;
        Object.assign(el, S.measure(text, el.fontSize, el.fontFamily));
        this.els.push(el);
        this.sel = new Set([el.id]);
      }
    });
    this.loadImages(cx);
  }

  group() {
    const s = this.selected();
    if (s.length < 2) return;
    this.mutate(() => { const g = S.newId(); for (const e of this.els.filter((e) => this.withLabels().has(e.id))) { e.groupIds = [...(e.groupIds ?? []), g]; S.touch(e); } });
  }
  ungroup() {
    this.mutate(() => { for (const e of this.els.filter((e) => this.withLabels().has(e.id))) if (e.groupIds?.length) { e.groupIds = e.groupIds.slice(0, -1); S.touch(e); } });
  }

  // Bring forward/back by one, or to the front/back with `all`. Selected runs move as blocks, so labels stay above their containers.
  reorder(dir, all) {
    this.mutate(() => {
      const ids = this.withLabels();
      if (!ids.size) return;
      const moving = this.els.filter((e) => ids.has(e.id)), rest = this.els.filter((e) => !ids.has(e.id));
      if (all) this.els = dir > 0 ? [...rest, ...moving] : [...moving, ...rest];
      else {
        const els = [...this.els];
        if (dir > 0) { for (let i = els.length - 2; i >= 0; i--) if (ids.has(els[i].id) && !ids.has(els[i + 1].id)) [els[i], els[i + 1]] = [els[i + 1], els[i]]; }
        else for (let i = 1; i < els.length; i++) if (ids.has(els[i].id) && !ids.has(els[i - 1].id)) [els[i], els[i - 1]] = [els[i - 1], els[i]];
        this.els = els;
      }
      this.reordered = true;
    });
  }

  nudge(dx, dy) {
    this.mutate(() => {
      const ids = this.withLabels();
      for (const e of this.els) if (ids.has(e.id)) { e.x += dx; e.y += dy; S.touch(e); }
      this.follow(ids);
    });
  }

  // Style changes go to the selection and become the defaults for new elements.
  apply(changes) {
    Object.assign(this.style, changes);
    if (!this.sel.size) return;
    this.mutate(() => {
      const byId = this.byId();
      for (const id of this.withLabels()) {
        const el = byId.get(id);
        if (!el) continue;
        for (const [k, v] of Object.entries(changes)) {
          if ((k === "backgroundColor" || k === "fillStyle") && (el.type === "text" || S.LINEAR.has(el.type) && el.type !== "line")) continue;
          if ((k === "fontSize" || k === "fontFamily" || k === "textAlign") && el.type !== "text") continue;
          if ((k === "strokeWidth" || k === "strokeStyle") && el.type === "text") continue;
          if ((k === "startArrowhead" || k === "endArrowhead") && el.type !== "arrow") continue;
          if (k === "textAlign" && el.containerId) continue;
          if (k === "roundness") {
            if (el.type === "rectangle") el.roundness = v ? { type: 3 } : null;
            else if (el.type === "diamond" || S.LINEAR.has(el.type)) el.roundness = v ? { type: 2 } : null;
            continue;
          }
          el[k] = v;
        }
        if (el.type === "text" && ("fontSize" in changes || "fontFamily" in changes)) {
          const container = el.containerId && byId.get(el.containerId);
          if (container) S.layoutLabel(el, container); else Object.assign(el, S.measure(el.text, el.fontSize, el.fontFamily));
        }
        S.touch(el);
      }
    });
  }
  // What the panel shows: the first selected element's value, else the default.
  current(key) {
    const el = this.selected()[0], byId = this.byId();
    const src = el && (key === "fontSize" || key === "fontFamily" || key === "textAlign") && el.type !== "text" ? S.boundText(el, byId) : el;
    if (src && key === "roundness") return Boolean(src.roundness);
    return src && src[key] !== undefined ? src[key] : this.style[key];
  }

  // ---------- text editing ----------

  // Start editing `el` (a text element already in the scene). `begin()` was called before it was added.
  startText(el, now = false) {
    const state = TextareaState.new({ value: el.originalText ?? el.text ?? "" });
    state.set_auto_grow(1, 16);
    state.on("focus", () => { if (this.edit?.state === state) this.edit.ready = true; });
    state.on("blur", (_e, cx) => { if (this.edit?.state === state && this.edit.ready) { this.commitText(); cx.notify(); } });
    // From a press, focus waits for the release: the press itself still moves the keyboard to the canvas.
    this.edit = { id: el.id, state, ready: false, focusOnUp: !now };
    this.sel = new Set([el.containerId ?? el.id]);
    this.tool = this.toolLock ? this.tool : "select";
    if (now) state.focus();
  }

  newText(x, y) {
    this.begin();
    const el = S.newElement("text", x, y, { ...this.style, backgroundColor: "transparent" });
    el.width = 1; el.height = el.fontSize * S.LINE_HEIGHT; el.y -= el.height / 2;
    this.els.push(el);
    this.startText(el);
  }

  editLabel(container, now = false) {
    const byId = this.byId(), existing = S.boundText(container, byId);
    this.begin();
    if (existing) return this.startText(existing, now);
    const el = S.newElement("text", 0, 0, { ...this.style, strokeColor: container.strokeColor === "transparent" ? this.style.strokeColor : container.strokeColor, backgroundColor: "transparent" });
    Object.assign(el, { containerId: container.id, textAlign: "center", verticalAlign: "middle" });
    S.addBound(container, el.id, "text");
    S.layoutLabel(el, container);
    this.els.splice(this.els.indexOf(container) + 1, 0, el);
    this.startText(el, now);
  }

  commitText() {
    const ed = this.edit;
    if (!ed) return;
    this.edit = null;
    const value = ed.state.value().replace(/\s+$/, "");
    ed.state.release();
    const byId = this.byId(), el = byId.get(ed.id);
    if (el) {
      if (!value.trim()) this.removeIds(new Set([el.id]));
      else {
        el.text = el.originalText = value;
        const container = el.containerId && byId.get(el.containerId);
        if (container) S.layoutLabel(el, container);
        else Object.assign(el, S.measure(value, el.fontSize, el.fontFamily));
        S.touch(el);
        this.sel = new Set([container?.id ?? el.id]);
      }
    }
    this.commit();
    this.handle.focus();
  }

  // ---------- pointer ----------

  setTool(tool) {
    this.tool = tool;
    if (tool !== "select") this.sel.clear();
  }

  down(e, cx) {
    if (this.edit) { this.commitText(); cx.notify(); return; }
    this.handle.focus();
    const s = this.local(e), p = this.toScene(s);
    this.pointer = p;
    if (!this.doc) return;
    if (this.tool === "hand" || this.spaceHeld) { this.drag = { kind: "pan", s0: s, cam: { ...this.cam } }; return cx.notify(); }
    const tool = this.writable() ? this.tool : "select";
    if (tool === "select") this.selectDown(e, s, p);
    else if (tool === "text") {
      const hit = this.pick(p[0], p[1]);
      if (hit?.type === "text") { this.begin(); this.startText(hit); }
      else if (hit && (S.SHAPES.has(hit.type) || S.LINEAR.has(hit.type))) this.editLabel(hit);
      else this.newText(p[0], p[1]);
    } else if (tool === "eraser") { this.begin(); this.drag = { kind: "erase" }; this.eraseAt(p); }
    else {
      this.begin();
      const el = S.newElement(tool, p[0], p[1], this.style);
      if (tool === "freedraw") el.backgroundColor = "transparent";
      this.els.push(el);
      this.drag = { kind: tool === "freedraw" ? "free" : "create", el, p0: p, start: S.LINEAR.has(tool) && tool === "arrow" ? this.bindTarget(p, el.id) : null };
    }
    cx.notify();
  }

  selectDown(e, s, p) {
    const m = e.modifiers;
    if (e.click_count >= 2 && this.writable()) {
      const hit = this.pick(p[0], p[1]);
      if (hit?.type === "text") { this.begin(); this.startText(hit); }
      else if (hit && (S.SHAPES.has(hit.type) || S.LINEAR.has(hit.type))) this.editLabel(hit);
      else if (!hit) this.newText(p[0], p[1]);
      return;
    }
    if (this.writable()) {
      const pt = this.pointAt(s);
      if (pt) {
        this.begin();
        const el = this.singleLinear();
        if (pt.mid) { const abs = S.absPoints(el); abs.splice(pt.index, 0, p); S.setPointsAbs(el, abs); }
        this.drag = { kind: "point", el, index: pt.index };
        return;
      }
      const grip = this.gripAt(s);
      if (grip) {
        this.begin();
        const orig = new Map(this.selected().filter((e) => !e.containerId).map((e) => [e.id, JSON.parse(JSON.stringify({ x: e.x, y: e.y, width: e.width, height: e.height, points: e.points, fontSize: e.fontSize }))]));
        this.drag = { kind: "resize", grip, box: this.selBox(), orig };
        return;
      }
    }
    const hit = this.pick(p[0], p[1]);
    if (!hit) {
      if (!m.shift) this.sel.clear();
      this.drag = { kind: "marquee", p0: p, p1: p, base: new Set(this.sel) };
      return;
    }
    const group = this.groupOf(hit);
    if (m.shift) {
      if (this.sel.has(hit.id)) { for (const g of group) this.sel.delete(g.id); return; }
      for (const g of group) this.sel.add(g.id);
    } else if (!this.sel.has(hit.id)) this.sel = new Set(group.map((g) => g.id));
    if (!this.writable()) return;
    this.begin();
    if (m.alt) {
      const ids = this.withLabels(), copies = this.cloneSet(this.els.filter((x) => ids.has(x.id)), 0, 0);
      this.els.push(...copies);
      this.sel = new Set(copies.filter((c) => !c.containerId).map((c) => c.id));
    }
    const ids = this.withLabels();
    this.drag = { kind: "move", p0: p, ids, orig: new Map(this.els.filter((x) => ids.has(x.id)).map((x) => [x.id, [x.x, x.y]])), moved: false };
  }

  move(e, cx) {
    const s = this.local(e), p = this.toScene(s);
    this.pointer = p;
    const d = this.drag;
    if (!d) {
      const c = this.cursorAt(s, p);
      if (c !== this.cursor) { this.cursor = c; cx.notify(); }
      return;
    }
    if (d.kind === "pan") {
      this.cam = { ...d.cam, ox: d.cam.ox + s[0] - d.s0[0], oy: d.cam.oy + s[1] - d.s0[1] };
    } else if (d.kind === "move") {
      let dx = p[0] - d.p0[0], dy = p[1] - d.p0[1];
      if (e.modifiers.shift) Math.abs(dx) > Math.abs(dy) ? (dy = 0) : (dx = 0);
      const byId = this.byId();
      for (const [id, [x, y]] of d.orig) { const el = byId.get(id); if (el) { el.x = x + dx; el.y = y + dy; } }
      d.moved = dx !== 0 || dy !== 0;
      this.follow(d.ids);
    } else if (d.kind === "resize") this.resizeTo(p, e.modifiers.shift);
    else if (d.kind === "marquee") {
      d.p1 = p;
      const x0 = Math.min(d.p0[0], p[0]), y0 = Math.min(d.p0[1], p[1]), x1 = Math.max(d.p0[0], p[0]), y1 = Math.max(d.p0[1], p[1]);
      const sel = new Set(d.base);
      for (const el of this.els) {
        if (el.containerId || el.locked) continue;
        const b = S.bounds(el);
        if (b.x >= x0 && b.y >= y0 && b.x + b.w <= x1 && b.y + b.h <= y1) for (const g of this.groupOf(el)) sel.add(g.id);
      }
      this.sel = sel;
    } else if (d.kind === "create") {
      const el = d.el;
      let dx = p[0] - d.p0[0], dy = p[1] - d.p0[1];
      if (S.LINEAR.has(el.type)) {
        if (e.modifiers.shift) {
          const a = Math.round(Math.atan2(dy, dx) / (Math.PI / 12)) * (Math.PI / 12), r = Math.hypot(dx, dy);
          dx = r * Math.cos(a); dy = r * Math.sin(a);
        }
        el.points = [[0, 0], [dx, dy]]; el.width = Math.abs(dx); el.height = Math.abs(dy);
      } else {
        if (e.modifiers.shift) { const n = Math.max(Math.abs(dx), Math.abs(dy)); dx = Math.sign(dx || 1) * n; dy = Math.sign(dy || 1) * n; }
        Object.assign(el, { x: Math.min(d.p0[0], d.p0[0] + dx), y: Math.min(d.p0[1], d.p0[1] + dy), width: Math.abs(dx), height: Math.abs(dy) });
      }
    } else if (d.kind === "free") {
      const last = d.el.points.at(-1), q = [p[0] - d.el.x, p[1] - d.el.y];
      if (Math.hypot(q[0] - last[0], q[1] - last[1]) * this.cam.z >= 1.5) d.el.points.push(q);
    } else if (d.kind === "point") {
      const abs = S.absPoints(d.el);
      abs[d.index] = p;
      S.setPointsAbs(d.el, abs);
      const label = S.boundText(d.el, this.byId());
      if (label) S.layoutLabel(label, d.el);
    } else if (d.kind === "erase") this.eraseAt(p);
    cx.notify();
  }

  up(_e, cx) {
    const d = this.drag;
    this.drag = null;
    if (this.edit?.focusOnUp) { this.edit.focusOnUp = false; this.edit.state.focus(); }
    if (!d) return;
    const byId = this.byId();
    if (d.kind === "create") {
      const el = d.el, linear = S.LINEAR.has(el.type);
      const tiny = linear ? Math.hypot(el.width, el.height) * this.cam.z < 4 : (el.width * this.cam.z < 3 && el.height * this.cam.z < 3);
      if (tiny) this.els = this.els.filter((x) => x !== el);
      else {
        if (el.type === "arrow") {
          const end = S.absPoints(el).at(-1), target = this.bindTarget(end, el.id);
          if (d.start) this.bind(el, "start", d.start);
          if (target && target !== d.start) this.bind(el, "end", target);
          S.reroute(el, this.byId());
        }
        S.touch(el);
        this.sel = new Set([el.id]);
        if (!this.toolLock) this.tool = "select";
      }
    } else if (d.kind === "free") {
      if (d.el.points.length < 2) d.el.points.push([0.5, 0.5]);
      S.setPointsAbs(d.el, S.absPoints(d.el));
      S.touch(d.el);
    } else if (d.kind === "point") {
      const el = d.el, last = el.points.length - 1;
      if (el.type === "arrow" && (d.index === 0 || d.index === last)) {
        const end = d.index === 0 ? "start" : "end";
        this.bind(el, end, this.bindTarget(S.absPoints(el)[d.index], el.id));
        S.reroute(el, this.byId());
      }
      S.touch(el);
    } else if (d.kind === "move" && d.moved) {
      for (const id of d.orig.keys()) {
        const el = byId.get(id);
        if (!el) continue;
        S.touch(el);
        // An arrow dragged away from the shapes it was bound to lets go of them.
        if (S.LINEAR.has(el.type)) for (const end of ["start", "end"]) {
          const b = el[`${end}Binding`];
          if (b && !d.ids.has(b.elementId)) this.bind(el, end, null);
        }
      }
    } else if (d.kind === "resize") for (const id of d.orig.keys()) S.touch(byId.get(id));
    if (d.kind !== "pan" && d.kind !== "marquee") this.commit();
    cx.notify();
  }

  resizeTo(p, keep) {
    const d = this.drag, b = d.box, byId = this.byId();
    const fx = d.grip.includes("w") ? b.x + b.w : b.x, fy = d.grip.includes("n") ? b.y + b.h : b.y;
    let sx = Math.max(1, Math.abs(p[0] - fx)) / (b.w || 1), sy = Math.max(1, Math.abs(p[1] - fy)) / (b.h || 1);
    const onlyText = [...d.orig.keys()].every((id) => byId.get(id)?.type === "text");
    if (keep || onlyText) sx = sy = Math.max(sx, sy);
    if (!b.w) sx = 1;
    if (!b.h) sy = 1;
    const w = b.w * sx, h = b.h * sy, nx = p[0] < fx ? fx - w : fx, ny = p[1] < fy ? fy - h : fy;
    for (const [id, o] of d.orig) {
      const el = byId.get(id);
      if (!el) continue;
      el.x = nx + (o.x - b.x) * sx; el.y = ny + (o.y - b.y) * sy;
      el.width = o.width * sx; el.height = o.height * sy;
      if (o.points) el.points = o.points.map(([a, c]) => [a * sx, c * sy]);
      if (el.type === "text") el.fontSize = Math.max(4, o.fontSize * sy);
      const label = S.boundText(el, byId);
      if (label) S.layoutLabel(label, el);
    }
    this.follow(new Set(d.orig.keys()));
  }

  eraseAt(p) {
    const hit = this.pick(p[0], p[1]);
    if (hit) this.removeIds(new Set(this.groupOf(hit).map((e) => e.id)));
  }

  cursorAt(s, p) {
    if (this.tool === "hand" || this.spaceHeld) return "grab";
    if (this.tool === "text") return "text";
    if (this.tool !== "select") return "crosshair";
    if (this.pointAt(s)) return "pointer";
    const grip = this.gripAt(s);
    if (grip) return grip === "nw" || grip === "se" ? "nwse" : "nesw";
    return this.pick(p[0], p[1]) ? "move" : "default";
  }

  wheel(e, cx) {
    const u = this.unit(), dx = e.delta.x / u, dy = e.delta.y / u;
    if (e.modifiers.control || e.modifiers.platform) this.zoomAt(this.local(e), Math.exp(dy * 0.01));
    else if (e.modifiers.shift && !dx) this.cam = { ...this.cam, ox: this.cam.ox + dy };
    else this.cam = { ...this.cam, ox: this.cam.ox + dx, oy: this.cam.oy + dy };
    cx.notify();
  }

  // ---------- keys ----------

  primary(e) { return host()?.platform === "macos" ? e.modifiers.platform : e.modifiers.control; }

  key(e, cx) {
    const k = (e.key ?? "").toLowerCase(), mod = this.primary(e), shift = e.modifiers.shift;
    if (this.edit) {
      if (k === "escape" || (k === "enter" && mod)) { cx.stop_propagation(); this.commitText(); cx.notify(); }
      return;
    }
    if (mod && k === "s") this.save(cx);
    else if (mod && k === "z") shift ? this.restore(this.redoStack, this.undoStack) : this.restore(this.undoStack, this.redoStack);
    else if (mod && k === "y") this.restore(this.redoStack, this.undoStack);
    else if (mod && k === "a") this.sel = new Set(this.els.filter((x) => !x.containerId).map((x) => x.id));
    else if (mod && k === "d") this.duplicate();
    else if (mod && k === "c") this.copy(cx);
    else if (mod && k === "x") { this.copy(cx); this.mutate(() => this.removeIds(new Set(this.sel))); }
    else if (mod && k === "v") this.paste(cx);
    else if (mod && k === "g") shift ? this.ungroup() : this.group();
    else if (mod && (k === "=" || k === "+")) this.zoomCenter(1.25);
    else if (mod && k === "-") this.zoomCenter(0.8);
    else if (mod && k === "0") this.zoomCenter(1 / this.cam.z);
    else if (mod && (k === "]" || k === "}")) this.reorder(1, shift);
    else if (mod && (k === "[" || k === "{")) this.reorder(-1, shift);
    else if (mod) return;
    else if (shift && (k === "1" || k === "!")) this.fit();
    else if (k === "backspace" || k === "delete") this.mutate(() => this.removeIds(new Set(this.sel)));
    else if (k === "escape") { this.sel.clear(); this.tool = "select"; }
    else if (k === "enter" && this.sel.size === 1 && this.writable()) {
      const el = this.selected()[0];
      if (el.type === "text") { this.begin(); this.startText(el, true); } else if (S.SHAPES.has(el.type) || S.LINEAR.has(el.type)) this.editLabel(el, true);
    }
    else if (["left", "right", "up", "down"].includes(k) && this.sel.size) {
      const n = shift ? 10 : 1;
      this.nudge(k === "left" ? -n : k === "right" ? n : 0, k === "up" ? -n : k === "down" ? n : 0);
    }
    else if (k === "space") { this.spaceHeld = true; this.cursor = "grab"; }
    else if (k === "q") this.toolLock = !this.toolLock;
    else if (KEYS[k] && !shift) this.setTool(KEYS[k]);
    else return;
    cx.stop_propagation();
    cx.notify();
  }

  keyUp(e, cx) {
    if ((e.key ?? "").toLowerCase() === "space" && this.spaceHeld) { this.spaceHeld = false; this.cursor = "default"; cx.notify(); }
  }

  // ---------- drawing ----------

  dark() { return this.canvasTheme ? this.canvasTheme === "dark" : Boolean(settings().dark); }
  color(c) { return this.dark() ? S.darkColor(c) : c; }
  viewBg() { return this.doc?.appState?.viewBackgroundColor ?? "#ffffff"; }

  path(segs, builder) {
    const { ox, oy, z } = this.cam;
    let pb = builder;
    for (const s of segs) {
      if (s[0] === "M") pb = pb.move_to(s[1] * z + ox, s[2] * z + oy);
      else if (s[0] === "L") pb = pb.line_to(s[1] * z + ox, s[2] * z + oy);
      else if (s[0] === "C") pb = pb.cubic_bezier_to(s[5] * z + ox, s[6] * z + oy, s[1] * z + ox, s[2] * z + oy, s[3] * z + ox, s[4] * z + oy);
      else pb = pb.close();
    }
    return pb.build();
  }
  paint(segs, builder, bg) { return window.paint_path(this.path(segs, builder), bg).absolute().top(0).left(0).size_full(); }
  solid(color, opacity) { const b = Background.solid(color); return opacity < 1 ? b.opacity(opacity) : b; }

  visible(el) {
    if (!this.size) return true;
    const b = S.bounds(el), m = 40 + (el.strokeWidth ?? 0) * this.cam.z;
    return this.sx(b.x + b.w) >= -m && this.sx(b.x) <= this.size.w + m && this.sy(b.y + b.h) >= -m && this.sy(b.y) <= this.size.h + m;
  }

  drawElement(el, t, out) {
    if (!this.visible(el)) return;
    const z = this.cam.z, op = (el.opacity ?? 100) / 100;
    if (el.type === "text") { if (this.edit?.id !== el.id) out.push(this.drawText(el, op)); return; }
    if (el.type === "image") {
      const src = this.images[el.fileId], box = div().absolute().left(this.sx(el.x)).top(this.sy(el.y)).w(el.width * z).h(el.height * z).opacity(op);
      out.push(src ? box.child(image(src).size_full()) : box.border_1().border_color(t.border).flex().items_center().justify_center().text_color(t.dim).text_size(11).child("image"));
      return;
    }
    const { segs, closed } = S.outline(el);
    if (!segs.length) return;
    const bg = el.backgroundColor;
    if (closed && bg && bg !== "transparent") {
      const c = this.color(bg);
      let fill = el.fillStyle === "solid" ? Background.solid(c) : Background.pattern_slash(c, Math.max(1, 1.3 * z), Math.max(3, (el.fillStyle === "cross-hatch" ? 5 : 8) * z));
      if (op < 1) fill = fill.opacity(op);
      out.push(this.paint(segs, PathBuilder.fill(), fill));
    }
    if (el.strokeColor && el.strokeColor !== "transparent") {
      const sw = el.strokeWidth ?? 1, width = Math.max(0.6, (el.type === "freedraw" ? sw * 1.6 : sw) * z);
      let pb = PathBuilder.stroke(width);
      if (el.strokeStyle === "dashed") pb = pb.dash_array([8 * z, (8 + sw) * z]);
      else if (el.strokeStyle === "dotted") pb = pb.dash_array([1.5 * z, (6 + sw) * z]);
      const stroke = this.solid(this.color(el.strokeColor), op);
      out.push(this.paint(segs, pb, stroke));
      for (const head of S.arrowheads(el, segs)) {
        if (head.fill) out.push(this.paint(head.segs, PathBuilder.fill(), stroke));
        out.push(this.paint(head.segs, PathBuilder.stroke(Math.max(0.6, sw * z)), stroke));
      }
    }
  }

  drawText(el, op) {
    const z = this.cam.z, fs = el.fontSize * z, lh = fs * (el.lineHeight ?? S.LINE_HEIGHT);
    const lines = String(el.text ?? "").split("\n"), kind = S.fontStack(el.fontFamily);
    const family = kind === "code" ? settings().font_family : kind === "hand" ? this.handFont : null;
    return v_flex().absolute().left(this.sx(el.x)).top(this.sy(el.y)).w(Math.max(1, el.width * z))
      .when(el.textAlign === "center", (x) => x.items_center()).when(el.textAlign === "right", (x) => x.items_end())
      .text_size(fs).line_height(`${lh}px`).text_color(this.color(el.strokeColor)).opacity(op)
      .when(Boolean(family), (x) => x.font_family(family))
      .children(lines.map((line) => div().flex_none().h(lh).whitespace_nowrap().child(line || " ")));
  }

  drawSelection(t, out) {
    if (this.drag?.kind === "create" || this.drag?.kind === "free") return;
    const sel = this.selected();
    if (sel.length) {
      const accent = t.accent, z = this.cam.z;
      const box = (b, pad) => [["M", b.x - pad / z, b.y - pad / z], ["L", b.x + b.w + pad / z, b.y - pad / z], ["L", b.x + b.w + pad / z, b.y + b.h + pad / z], ["L", b.x - pad / z, b.y + b.h + pad / z], ["Z"]];
      const linear = this.singleLinear();
      if (sel.length > 1) for (const el of sel) out.push(this.paint(box(S.bounds(el), 2), PathBuilder.stroke(1).dash_array([3, 3]), Background.solid(accent).opacity(0.6)));
      if (!linear) out.push(this.paint(box(this.selBox(), 4), PathBuilder.stroke(1), Background.solid(accent)));
      for (const [name, x, y] of this.grips())
        out.push(div().id(`grip-${name}`).absolute().left(x - 4).top(y - 4).size(8).rounded(2).border_1().border_color(accent).bg(t.background));
      for (const g of this.pointGrips()) {
        const r = g.mid ? 4 : 5.5;
        out.push(div().absolute().left(g.x - r).top(g.y - r).size(r * 2).rounded(r).border_1().border_color(accent).bg(g.mid ? accent : t.background).opacity(g.mid ? 0.55 : 1));
      }
    }
    const d = this.drag;
    if (d?.kind === "marquee") {
      const x0 = this.sx(Math.min(d.p0[0], d.p1[0])), y0 = this.sy(Math.min(d.p0[1], d.p1[1]));
      const w = Math.abs(d.p1[0] - d.p0[0]) * this.cam.z, h = Math.abs(d.p1[1] - d.p0[1]) * this.cam.z;
      out.push(div().absolute().left(x0).top(y0).w(w).h(h).border_1().border_color(t.accent).bg(t.selection).opacity(0.5));
    }
  }

  // ---------- chrome ----------

  button(id, t, { icon, label, active, onClick, primary, disabled }) {
    return div().id(id).h(28).min_w(28).px(label ? 10 : 0).flex().gap(6).items_center().justify_center().rounded(7).text_size(12)
      .when(!disabled, (x) => x.cursor_pointer().hover((s) => s.bg(primary ? t.accent : t.hover)).on_click((_e, cx) => { onClick(cx); cx.notify(); }))
      .when(primary, (x) => x.bg(t.accent).text_color(t.accent_foreground))
      .when(!primary && active, (x) => x.bg(t.selected).text_color(t.accent))
      .when(!primary && !active, (x) => x.text_color(t.foreground))
      .when(disabled, (x) => x.opacity(0.45))
      .when(Boolean(icon), (x) => x.child(svg(ICON(icon)).size(15).flex_none()))
      .when(Boolean(label), (x) => x.child(div().child(label)));
  }

  // Overlays stop presses so they don't reach the canvas underneath.
  floating(id, t) {
    return h_flex().id(id).gap(2).p(4).rounded(10).bg(t.popover).border_1().border_color(t.border)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_mouse_up("left", (_e, cx) => cx.stop_propagation());
  }

  toolbar(t) {
    const tools = TOOLS.map(([tool, key]) => div().id(`tool-${tool}`).relative().size(32).rounded(7).flex().items_center().justify_center().cursor_pointer()
      .when(this.tool === tool, (x) => x.bg(t.selected).text_color(t.accent)).when(this.tool !== tool, (x) => x.text_color(t.foreground).hover((s) => s.bg(t.hover)))
      .on_click((_e, cx) => { this.setTool(tool); this.handle.focus(); cx.notify(); })
      .child(svg(ICON(tool)).size(16))
      .child(div().absolute().right(3).bottom(1).text_size(8).text_color(t.dim).child(key)));
    return this.floating("toolbar", t)
      .child(this.button("lock", t, { icon: this.toolLock ? "lock" : "unlock", active: this.toolLock, onClick: () => { this.toolLock = !this.toolLock; } }))
      .child(div().w(1).h(20).mx(3).bg(t.border))
      .children(this.writable() ? tools : tools.slice(0, 2));
  }

  chip(id, t, active, content, onClick) {
    return div().id(id).h(26).min_w(26).px(5).flex().items_center().justify_center().rounded(6).cursor_pointer().text_size(11)
      .border_1().border_color(active ? t.accent : t.border).when(active, (x) => x.bg(t.selected))
      .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { onClick(); cx.notify(); }).child(content);
  }

  swatches(id, t, colors, key) {
    const now = this.current(key);
    return h_flex().gap(4).children(colors.map((c) => div().id(`${id}-${c}`).size(22).rounded(5).cursor_pointer().flex().items_center().justify_center()
      .border_1().border_color(now === c ? t.accent : t.border).when(now === c, (x) => x.border_2())
      .when(c !== "transparent", (x) => x.bg(this.color(c)))
      .when(c === "transparent", (x) => x.text_color(t.dim).text_size(12).child("∅"))
      .on_click((_e, cx) => { this.apply({ [key]: c }); cx.notify(); })));
  }

  panel(t) {
    const sel = this.selected(), byId = this.byId();
    const types = new Set(sel.map((e) => e.type));
    const creating = this.tool !== "select" && this.tool !== "hand" && this.tool !== "eraser";
    if (!this.writable() || (!sel.length && !creating)) return null;
    const kinds = sel.length ? types : new Set([this.tool]);
    const has = (...ts) => ts.some((x) => kinds.has(x));
    const labelled = sel.some((e) => e.type === "text" || S.boundText(e, byId));
    const fills = has("rectangle", "ellipse", "diamond", "line", "image");
    const row = (label, ...items) => v_flex().gap(5).child(div().text_size(11).text_color(t.muted).child(label)).child(h_flex().gap(4).flex_wrap().children(items));
    const line = (w) => div().w(16).h(Math.max(1, w)).rounded(1).bg(t.foreground);
    const set = (key, value, label) => this.chip(`${key}-${value}`, t, this.current(key) === value, label, () => this.apply({ [key]: value }));
    const rows = [row("Stroke", this.swatches("stroke", t, S.STROKES, "strokeColor"))];
    if (fills) rows.push(row("Background", this.swatches("fill", t, S.FILLS, "backgroundColor")));
    if (fills) rows.push(row("Fill", set("fillStyle", "hachure", "Hatch"), set("fillStyle", "cross-hatch", "Cross"), set("fillStyle", "solid", "Solid")));
    if (!(kinds.size === 1 && has("text"))) {
      rows.push(row("Stroke width", set("strokeWidth", 1, line(1)), set("strokeWidth", 2, line(2)), set("strokeWidth", 4, line(4))));
      rows.push(row("Stroke style", set("strokeStyle", "solid", "──"), set("strokeStyle", "dashed", "- -"), set("strokeStyle", "dotted", "···")));
    }
    if (has("rectangle", "diamond", "arrow", "line")) rows.push(row("Edges", set("roundness", false, "Sharp"), set("roundness", true, "Round")));
    if (has("arrow")) {
      const heads = (key) => [[null, "—"], ["arrow", "→"], ["triangle", "▶"], ["bar", "⊢"], ["dot", "●"]].map(([v, l]) => set(key, v, l));
      rows.push(row("Start", ...heads("startArrowhead")), row("End", ...heads("endArrowhead")));
    }
    if (labelled || has("text")) {
      rows.push(row("Font size", ...S.FONT_SIZES.map(([l, v]) => set("fontSize", v, l))));
      rows.push(row("Font", set("fontFamily", 5, "Hand"), set("fontFamily", 6, "Normal"), set("fontFamily", 8, "Code")));
    }
    if (has("text") && sel.every((e) => !e.containerId)) rows.push(row("Align", set("textAlign", "left", "Left"), set("textAlign", "center", "Center"), set("textAlign", "right", "Right")));
    rows.push(row("Opacity", ...[100, 75, 50, 25].map((v) => set("opacity", v, `${v}`))));
    if (sel.length) rows.push(row("Actions",
      this.button("to-back", t, { icon: "back", onClick: () => this.reorder(-1, true) }),
      this.button("to-front", t, { icon: "front", onClick: () => this.reorder(1, true) }),
      this.button("dup", t, { icon: "copy", onClick: () => this.duplicate() }),
      this.button("del", t, { icon: "trash", onClick: () => this.mutate(() => this.removeIds(new Set(this.sel))) })));
    return v_flex().id("props").absolute().left(12).top(60).w(208).max_h(this.size ? this.size.h - 110 : 500).overflow_y_scrollbar()
      .gap(10).p(10).rounded(10).bg(t.popover).border_1().border_color(t.border).text_color(t.foreground)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_mouse_up("left", (_e, cx) => cx.stop_propagation())
      .on_scroll_wheel((_e, cx) => cx.stop_propagation())
      .children(rows);
  }

  editor(t) {
    const ed = this.edit, el = ed && this.byId().get(ed.id);
    if (!el) return null;
    const z = this.cam.z, container = el.containerId && this.byId().get(el.containerId);
    const fs = el.fontSize * z, width = container ? Math.max(120, S.bounds(container).w * z) : Math.max(160, el.width * z + 40);
    const left = container ? this.sx(S.center(container)[0]) - width / 2 : this.sx(el.x) - 4;
    const top = container ? this.sy(S.center(container)[1]) - fs * 0.9 : this.sy(el.y) - 4;
    return div().absolute().left(left).top(top).w(width)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_mouse_up("left", (_e, cx) => cx.stop_propagation())
      .child(Textarea.new(ed.state).w_full().text_size(fs).text_color(this.color(el.strokeColor)).bg(t.popover).border_1().border_color(t.accent).rounded(4)
        .when(Boolean(this.handFont) && S.fontStack(el.fontFamily) === "hand", (x) => x.font_family(this.handFont)));
  }

  render(cx) {
    const t = theme();
    if (this.fitPending && this.size && this.doc) { this.fit(); this.fitPending = false; }
    const platform = host()?.platform, hint = platform === "macos" ? "⌘S" : "Ctrl S";
    const header = h_flex().h(40).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().font_semibold().child(this.name))
      .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.message ?? this.dir))
      .child(this.button("theme", t, { icon: this.dark() ? "sun" : "moon", onClick: () => { this.canvasTheme = this.dark() ? "light" : "dark"; } }))
      .child(this.button("svg", t, { icon: "export", label: "SVG", disabled: !this.doc || Boolean(this.on), onClick: (cx) => this.exportAs("svg", cx) }))
      .child(this.button("png", t, { icon: "export", label: "PNG", disabled: !this.doc || Boolean(this.on), onClick: (cx) => this.exportAs("png", cx) }))
      .when(this.writable(), (x) => x.child(this.button("save", t, {
        primary: true, disabled: !this.dirty, onClick: (cx) => this.save(cx),
        label: h_flex().gap(7).items_center().child(div().child("Save")).child(div().h(16).px(5).flex().items_center().rounded(4).border_1().border_color(t.accent_foreground).opacity(0.75).text_size(10).child(hint)),
      })));

    const root = v_flex().id("excalidraw").size_full().min_h(0).overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13)
      .track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx)).on_key_up((e, cx) => this.keyUp(e, cx))
      .child(header)
      .when(this.conflict, (x) => x.child(h_flex().mx(12).mt(10).px(12).py(8).gap(10).items_center().rounded(9).border_1().border_color(t.blocked).text_size(12.5).text_color(t.blocked)
        .child(div().flex_1().child("Changed on disk since you opened it."))
        .child(this.button("keep-mine", t, { label: "Keep mine", onClick: (cx) => this.overwrite(cx) }))
        .child(this.button("reload", t, { label: "Reload", primary: true, onClick: (cx) => this.load(cx) }))));
    if (this.error || !this.doc) return root.child(div().p(14).text_color(t.dim).child(this.error ?? "Loading diagram…"));

    const art = [];
    for (const el of this.els) this.drawElement(el, t, art);
    this.drawSelection(t, art);
    const cursor = this.drag?.kind === "pan" ? "grabbing" : this.drag?.kind === "move" ? "move" : this.cursor;
    const canvas = div().id("canvas").absolute().inset_0().overflow_hidden().bg(this.color(this.viewBg()))
      .when(cursor === "crosshair", (x) => x.cursor_crosshair()).when(cursor === "text", (x) => x.cursor_text())
      .when(cursor === "grab", (x) => x.cursor_grab()).when(cursor === "grabbing", (x) => x.cursor_grabbing())
      .when(cursor === "move", (x) => x.cursor_move()).when(cursor === "pointer", (x) => x.cursor_pointer())
      .when(cursor === "nwse", (x) => x.cursor_nwse_resize()).when(cursor === "nesw", (x) => x.cursor_nesw_resize())
      .on_mouse_down("left", (e, cx) => this.down(e, cx))
      .on_mouse_down("middle", (e, cx) => { this.drag = { kind: "pan", s0: this.local(e), cam: { ...this.cam } }; cx.notify(); })
      .on_mouse_move((e, cx) => this.move(e, cx))
      .on_mouse_up("left", (e, cx) => this.up(e, cx))
      .on_mouse_up("middle", (e, cx) => this.up(e, cx))
      .on_hover((hovered, cx) => { if (!hovered && this.drag) this.up(null, cx); })
      .on_scroll_wheel((e, cx) => this.wheel(e, cx))
      .on_drop((e, cx) => this.dropFiles(e.paths, this.pointer, cx))
      .children(art)
      .when(!this.els.length && !this.drag, (x) => x.child(v_flex().absolute().inset_0().items_center().justify_center().gap(6).text_color(t.dim)
        .child(div().text_size(15).child(this.writable() ? "An empty canvas" : "Nothing to show"))
        .when(this.writable(), (y) => y.child(div().text_size(12).child("Pick a tool above (R, O, D, A, T…) and draw. Drop images here to add them.")))));

    const zoom = this.floating("zoom", t)
      .child(this.button("zoom-out", t, { icon: "minus", onClick: () => this.zoomCenter(0.8) }))
      .child(div().id("zoom-reset").w(46).h(28).flex().items_center().justify_center().rounded(7).cursor_pointer().text_size(12).hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { this.zoomCenter(1 / this.cam.z); cx.notify(); }).child(`${Math.round(this.cam.z * 100)}%`))
      .child(this.button("zoom-in", t, { icon: "plus", onClick: () => this.zoomCenter(1.25) }))
      .child(this.button("zoom-fit", t, { icon: "fit", onClick: () => this.fit() }))
      .when(this.writable(), (x) => x.child(div().w(1).h(20).mx(3).bg(t.border))
        .child(this.button("undo", t, { icon: "undo", disabled: !this.undoStack.length, onClick: () => this.restore(this.undoStack, this.redoStack) }))
        .child(this.button("redo", t, { icon: "redo", disabled: !this.redoStack.length, onClick: () => this.restore(this.redoStack, this.undoStack) })));

    const stage = div().id("stage").relative().flex_1().min_h(0).overflow_hidden()
      .on_size_change((size, cx) => { const u = this.unit(); this.size = { w: size.width / u, h: size.height / u }; cx.notify(); })
      .child(canvas)
      .child(h_flex().absolute().top(10).left(0).right(0).justify_center().child(this.toolbar(t)))
      .child(div().absolute().left(12).bottom(12).child(zoom))
      .child(div().absolute().right(14).bottom(18).text_size(11).text_color(t.dim)
        .child(this.readonly ?? (this.toolLock ? `${HINTS[this.tool] ?? ""} · tool locked (Q)` : HINTS[this.tool] ?? "")));
    const panel = this.panel(t), editor = this.editor(t);
    return root.child(stage.when(Boolean(panel), (x) => x.child(panel)).when(Boolean(editor), (x) => x.child(editor)));
  }
}

// Pixel size from a PNG, GIF, JPEG or WebP header.
function imageSize(b) {
  const u32 = (i) => (b[i] << 24 | b[i + 1] << 16 | b[i + 2] << 8 | b[i + 3]) >>> 0;
  if (b[0] === 0x89 && b[1] === 0x50) return [u32(16), u32(20)];
  if (b[0] === 0x47 && b[1] === 0x49) return [b[6] | b[7] << 8, b[8] | b[9] << 8];
  if (b[0] === 0x52 && b[8] === 0x57 && b[12] === 0x56 && b[15] === 0x20) return [(b[26] | b[27] << 8) & 0x3fff, (b[28] | b[29] << 8) & 0x3fff];
  if (b[0] === 0xff && b[1] === 0xd8) {
    for (let i = 2; i < b.length - 9;) {
      if (b[i] !== 0xff) { i++; continue; }
      const marker = b[i + 1], len = b[i + 2] << 8 | b[i + 3];
      if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) return [b[i + 7] << 8 | b[i + 8], b[i + 5] << 8 | b[i + 6]];
      i += 2 + len;
    }
  }
  return null;
}
