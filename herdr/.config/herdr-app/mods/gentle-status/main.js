// cloned_from: workspace-status (herdr-app 0.1.16); changes: Claude usage chip after the
// machine, opening the usage popup (props.role === "usage"); icons stay in mods/workspace-chrome/.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, agents, theme, run, window, keys, shared, props, openOverlay, checking } from "herdr";
import { KEY, refresh, until, color } from "./usage.js";
import { UsagePopup } from "./popup.js";

const EVERY = 5 * 60000;
// A Herdr notification (an agent finished or needs you; gentle-toast pings
// shared("claude.usage.ping")) refreshes once usage has settled; ones close
// together share one request (the endpoint rate-limits).
const SETTLE = 5000, GAP = 30000, PING = "claude.usage.ping";

// Sized to what it shows: header, each limit, the weekly breakdown, the link.
const popupHeight = u => 104 + (u?.error ? 22 : 0) + (u?.limits?.length ?? 0) * 52 + (u?.breakdown?.length ? 42 + u.breakdown.length * 20 : 0) + (u?.extra ? 30 : 0);

class StatusBar {
  init(cx) {
    if (checking()) return;
    this.last = 0;
    const go = () => { this.last = Date.now(); refresh(); };
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
    const bar = l => div().w(22).h(4).rounded(2).bg(t.border).child(div().h_full().rounded(2).bg(color(t, l)).w(Math.max(l.percent ? 2 : 0, Math.min(22, l.percent * 0.22))));
    // The bar shows the session only; the weekly limits are in the popup.
    const l = u?.limits?.find(x => x.kind === "session") ?? u?.limits?.[0];
    return h_flex().id("claude-usage").h(20).px(6).gap(7).items_center().rounded(5).cursor_pointer()
      .hover(s => s.bg(t.hover).text_color(t.foreground))
      .tooltip("Claude usage")
      // Anchored above the chip, its left edge on the chip's, wherever the press was.
      .on_mouse_down("left", (e, cx) => {
        cx.stop_propagation();
        const b = e.bounds, height = popupHeight(shared(KEY));
        openOverlay({ mod: "gentle-status", kind: "popup", width: 340, height, props: { role: "usage" },
          at: b ? { x: Math.max(8, b.x - 4), y: Math.max(8, b.y - height - 6) } : "pointer" });
      })
      .child(svg("mods/gentle-status/claude.svg").size(12).text_color("#d97757"))
      .when(!l, el => el.child(div().text_color(t.dim).child(u?.error && !u?.loading ? "—" : "…")))
      .when(Boolean(l), el => el.child(bar(l))
        .child(div().text_color(l.percent >= 70 ? color(t, l) : t.muted).child(`${l.percent}%`))
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

export default class GentleStatus extends View {
  init(_props, cx) {
    this.part = props()?.role === "usage" ? new UsagePopup() : new StatusBar();
    this.part.init(cx);
  }
  render(cx) { return this.part.render(cx); }
}
