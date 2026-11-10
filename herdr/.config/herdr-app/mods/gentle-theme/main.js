// Keeps herdr's `gentle-shell` theme in step with the active Gentle Shell (Pi) theme, and shows
// the sync state in a 30px row. It reads the theme name from settings.json (settings.js), finds the Pi theme
// (a file, or an embedded built-in such as `dark`/`light`), derives the herdr theme (derive.js) and
// rewrites themes/gentle-shell.json only when the result changed.
//
// Timing: the theme name is the only thing that changes when the user switches themes, so only
// settings.json is polled, every 500 ms (one small read), which makes a switch feel immediate.
// The Pi theme file is re-read only when the name changes or every 5 s (to notice edits to a custom
// theme), and the output is compared in memory with what was last written, never re-read per cycle.
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { home, appHome, readTextFile, writeTextFile, theme, layout } from "herdr";
import { isNarrow } from "./rail.js";
import { derive, resolveTheme, BASE } from "./derive.js";
import { BUILTIN } from "./builtin.js";
import { readSettings } from "./settings.js";

const EVERY_MS = 500;
const THEME_RECHECK_MS = 5000;
const OUT = "gentle-shell";
const SAFE_NAME = /^[\w .-]+$/;

export default class GentleTheme extends View {
  init(_props, cx) {
    this.name = null;
    this.state = "waiting";
    this.reason = "";
    this.builtin = false;
    this.busy = false;
    this.cache = null; // { name, at, result: { name, error?, builtin? }, next? }
    this.written = undefined; // text last known to be in the output file
    this.check(cx);
    cx.timer.every(EVERY_MS, (cx) => this.check(cx));
  }

  set(state, reason, builtin, cx) {
    if (state !== this.state || reason !== this.reason || builtin !== this.builtin) {
      this.state = state;
      this.reason = reason;
      this.builtin = builtin;
      cx.notify();
    }
  }

  async load(h, name) {
    // Pi's `system` theme has no file: it follows the terminal's own colors, so herdr keeps the
    // shipped Gentle palette instead of showing a "theme file not found" error.
    if (name === "system") return { result: { name, builtin: false }, next: JSON.stringify(BASE, null, 2) + "\n" };
    const files = [
      `${h}/.gentle-shell/agent/themes/${name}.json`,
      `${h}/.pi/agent/themes/${name}.json`,
      `${h}/.pi/agent/npm/node_modules/gentle-pi/themes/${name}.json`,
    ];
    const texts = [];
    for (const f of files) {
      const text = await readTextFile(f);
      texts.push(text);
      if (text !== null) break;
    }
    const r = resolveTheme(name, texts, BUILTIN);
    if (r.error) return { result: { name, error: r.error } };
    return { result: { name, builtin: r.builtin === true }, next: JSON.stringify(derive(r.pi, BASE), null, 2) + "\n" };
  }

  async sync() {
    const h = home().replace(/[\/]+$/, "");
    const settings = await readSettings(h, readTextFile);
    if (settings === undefined) return { error: "settings.json missing or invalid" };
    const name = settings?.theme;
    if (typeof name !== "string" || !SAFE_NAME.test(name) || name.startsWith(".")) return { name: null, wait: "no theme set" };

    const now = Date.now();
    if (!this.cache || this.cache.name !== name || now - this.cache.at >= THEME_RECHECK_MS) {
      this.cache = { name, at: now, ...(await this.load(h, name)) };
    }
    const { result, next } = this.cache;
    if (next === undefined || next === this.written) return result;

    const out = `${appHome().replace(/[\/]+$/, "")}/themes/${OUT}.json`;
    const current = await readTextFile(out);
    if (current !== next) await writeTextFile(out, next, current);
    this.written = next;
    return result;
  }

  async check(cx) {
    if (this.busy) return;
    this.busy = true;
    try {
      const r = await this.sync();
      if (r.name !== undefined && r.name !== this.name) { this.name = r.name; cx.notify(); }
      if (r.error) this.set("error", r.error, false, cx);
      else if (r.wait) this.set("waiting", r.wait, false, cx);
      else this.set("synced", "", r.builtin === true, cx);
    } catch (e) {
      this.set("error", String(e?.message ?? e).slice(0, 60), false, cx);
    } finally {
      this.busy = false;
    }
  }

  render() {
    const t = theme();
    const color = { synced: t.done, waiting: t.muted, error: t.blocked }[this.state];
    const label = this.state === "error" || (this.state === "waiting" && this.reason)
      ? `${this.state}: ${this.reason}`
      : this.builtin ? "synced (built-in)" : this.state;
    // On the narrow rail only the flower fits: it takes the state's color (accent when synced).
    if (isNarrow(layout())) {
      const dot = { synced: t.accent, waiting: t.muted, error: t.blocked }[this.state];
      return h_flex().size_full().h(30).items_center().justify_center().bg(t.chrome).text_size(13)
        .child(div().flex_none().text_color(dot).child("✿"));
    }
    return h_flex().size_full().h(30).px(14).gap(8).items_center().bg(t.chrome).text_size(11.8)
      .child(div().flex_none().text_color(t.accent).child("✿"))
      .child(div().flex_none().text_color(t.muted).child("Theme"))
      .child(div().flex_1().truncate().text_color(t.foreground).child(this.name ?? "—"))
      .child(div().flex_none().text_color(color).child(label));
  }
}
