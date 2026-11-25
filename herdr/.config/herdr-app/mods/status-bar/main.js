// cloned_from: workspace-status (herdr-app 0.1.16); changes: Claude usage chip after the
// machine, opening the usage popup (props.role === "usage": Claude, Codex, Copilot);
// icons stay in mods/workspace-chrome/.
import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, agents, theme, run, window, keys, shared, props, openOverlay, checking, layout } from "herdr";
import { KEY, PROVIDERS, refreshAll, until, color } from "./usage.js";
import { UsagePopup, POPUP } from "./popup.js";

const EVERY = 5 * 60000;
// A Herdr notification (an agent finished or needs you; notifications pings
// shared("claude.usage.ping")) refreshes once usage has settled; ones close
// together share one request (the endpoint rate-limits).
const SETTLE = 5000, GAP = 30000, PING = "claude.usage.ping";

// Where the popup opens: its bottom just above the status bar (the bar is the
// window's bottom block), its left edge on the chip's. Window coordinates: the
// pointer minus where it is inside the chip, and gpui's own window (herdr's
// window() import shadows the global) for the height.
function anchor(e) {
  const vp = globalThis.window?.viewport_size?.();
  const bar = find(layout(), "status")?.size?.px ?? 28;
  if (!vp?.height) return "pointer";
  const left = (e.position?.x ?? 0) - (e.local_position?.x ?? 0);
  return { x: Math.max(8, Math.min(left - 2, vp.width - POPUP.width - 8)), y: Math.max(8, vp.height - bar - POPUP.height - 4) };
}

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

class StatusBar {
  init(cx) {
    if (checking()) return;
    this.last = 0;
    const go = () => { this.last = Date.now(); refreshAll(); };
    go();
    cx.timer.every(EVERY, () => { if (Date.now() - this.last > GAP) go(); });
    this.ping = shared(PING)?.at ?? 0;
    cx.timer.every(2000, () => {
      const at = shared(PING)?.at ?? 0;
      if (at <= this.ping) return;
      this.ping = at;
      if (this.pending) return;
      this.pending = true;
      cx.timer.after(Math.max(SETTLE, this.last + GAP - Date.now()), () => { this.pending = false; go(); });
    });
    // Reset countdowns move each minute.
    cx.timer.every(60000, cx => cx.notify());
  }

  // The keys as actually bound, not a hardcoded one; without a binding the hint
  // stays useful ("commands") instead of lying.
  hint() {
    const mac = window()?.platform === "macos";
    const mod = { cmd: mac ? "⌘" : "Ctrl+", ctrl: mac ? "⌃" : "Ctrl+", shift: mac ? "⇧" : "Shift+", alt: mac ? "⌥" : "Alt+", option: mac ? "⌥" : "Alt+" };
    const b = keys().find((k) => k.section === "global" && k.action === "app.palette");
    const parts = b && b.keys.endsWith("--") ? [...b.keys.slice(0, -2).split("-"), "-"] : b?.keys.split("-");
    const key = parts && parts.map((p) => mod[p.toLowerCase()] ?? p.toUpperCase()).join("");
    return key ? `${key}  commands` : "commands";
  }

  usage(t) {
    const u = shared(KEY);
    const bar = l => div().w(22).h(4).rounded(2).bg(t.border).child(div().h_full().rounded(2).bg(color(t, l, PROVIDERS[0].tint)).w(Math.max(l.percent ? 2 : 0, Math.min(22, l.percent * 0.22))));
    // The bar shows the session only; the weekly limits are in the popup.
    const l = u?.limits?.find(x => x.kind === "session") ?? u?.limits?.[0];
    return h_flex().id("claude-usage").h(20).px(6).gap(7).items_center().rounded(5).cursor_pointer()
      .hover(s => s.bg(t.hover).text_color(t.foreground))
      .tooltip("Claude usage")
      // Anchored above the chip, its left edge on the chip's, wherever the press was.
      .on_mouse_down("left", (e, cx) => {
        cx.stop_propagation();
        openOverlay({ mod: "status-bar", kind: "popup", ...POPUP, props: { role: "usage" }, at: anchor(e) });
      })
      .child(image("mods/status-bar/claude.svg").w(13).h(13).flex_none())
      .when(!l, el => el.child(div().text_color(t.dim).child(u?.error && !u?.loading ? "—" : "…")))
      .when(Boolean(l), el => el.child(bar(l))
        .child(div().text_color(l.percent >= 70 ? color(t, l, PROVIDERS[0].tint) : t.muted).child(`${l.percent}%`))
        .child(div().text_color(t.dim).child(until(l.resets))))
      // Numbers kept from before a failed refresh: a dot says they may be old.
      .when(Boolean(u?.error && l), el => el.child(div().size(5).rounded_full().bg(t.working)));
  }

  render() {
    const t = theme();
    const space = spaces().find(s => s.active);
    const list = agents();
    const needs = list.filter(a => a.status === "blocked").length;
    const label = (icon, text) => h_flex().gap(6).items_center().child(svg(`mods/workspace-chrome/${icon}.svg`).size(13)).child(text);
    return h_flex().size_full().px(14).gap(16).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine ?? "This computer"))
      .child(this.usage(t))
      .when(Boolean(space?.branch), el => el.child(label("branch", space.branch)))
      .child(h_flex().gap(6).items_center().child(div().size(6).rounded(3).bg(t.dim)).child(`${list.length} agents`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))))
      .child(div().flex_1())
      .child(div().id("palette").text_color(t.dim).on_click(() => run("app.palette")).child(this.hint()));
  }
}

export default class StatusBarView extends View {
  init(_props, cx) {
    this.part = props()?.role === "usage" ? new UsagePopup() : new StatusBar();
    this.part.init(cx);
  }
  render(cx) { return this.part.render(cx); }
}
