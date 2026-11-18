// The usage popup, opened from the status bar's Claude chip.
import { div, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, shared, exec, window, closeOverlay, props } from "herdr";
import { KEY, refresh, until, ago, color } from "./usage.js";

const BAR = 120;
const openUrl = url => {
  const p = window()?.platform;
  exec(p === "macos" ? "open" : p === "windows" ? "explorer.exe" : "xdg-open", [url]).catch(() => {});
};

export class UsagePopup {
  init(cx) {
    // Fresh numbers when opened, unless the last ones are under a minute old.
    if (Date.now() - (shared(KEY)?.checked ?? 0) > 60000) refresh();
    cx.timer.every(30000, cx => cx.notify());
  }

  bar(t, l, w = BAR) {
    return div().w(w).h(5).rounded(3).bg(t.border).flex_none()
      .child(div().h_full().rounded(3).bg(color(t, l)).w(Math.max(l.percent ? 3 : 0, Math.min(w, (l.percent * w) / 100))));
  }

  limit(t, l) {
    return v_flex().gap(5)
      .child(h_flex().items_center().gap(8)
        .child(div().flex_1().text_color(t.foreground).child(l.name))
        .child(div().text_color(color(t, l)).font_semibold().child(`${l.percent}%`)))
      .child(h_flex().items_center().gap(8)
        .child(this.bar(t, l, 200))
        .child(div().flex_1())
        .child(div().text_size(11).text_color(t.dim).child(l.resets ? `resets in ${until(l.resets)}` : "")));
  }

  render() {
    const t = theme();
    const u = shared(KEY) ?? {};
    const limits = u.limits ?? [];
    const rule = () => div().h(1).bg(t.border).flex_none();
    return v_flex().size_full().bg(t.popover).p(12).gap(12).text_size(12.5).text_color(t.muted).id("claude-usage-popup")
      .child(h_flex().items_center().gap(8)
        .child(div().size(24).flex_none().flex().items_center().justify_center().rounded(6).bg(t.raised)
          .child(svg("mods/gentle-status/claude.svg").size(14).text_color("#d97757")))
        .child(div().font_semibold().text_size(13.5).text_color(t.foreground).child("Claude"))
        .when(Boolean(u.plan), el => el.child(div().text_color(t.muted).child(`· ${u.plan}`)))
        .child(div().flex_1())
        .child(div().text_size(11).text_color(t.dim).child(u.loading ? "updating…" : u.updated ? ago(u.updated) : ""))
        .child(div().id("usage-refresh").size(24).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer()
          .text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip("Refresh")
          .on_click((_e, cx) => { refresh(); cx.notify(); })
          .child(svg("mods/gentle-status/refresh.svg").size(14))))
      .when(Boolean(u.error), el => el.child(div().text_size(11.5).text_color(limits.length ? t.working : t.blocked).child(u.error)))
      .children(limits.map(l => this.limit(t, l)))
      .when(Boolean(u.breakdown?.length), el => el.child(rule()).child(v_flex().gap(4)
        .child(div().text_size(11).text_color(t.dim).child("This week by surface"))
        .children(u.breakdown.map(b => h_flex().items_center().gap(8)
          .child(div().flex_1().child(b.name))
          .child(div().text_color(t.foreground).child(`${b.percent}%`))))))
      .when(Boolean(u.extra), el => el.child(rule()).child(h_flex().items_center()
        .child(div().flex_1().child("Extra usage"))
        .child(div().text_color(t.foreground).child(`${u.extra.used} / ${u.extra.limit} ${u.extra.currency}`))))
      .child(div().flex_1())
      .child(h_flex().id("usage-open").items_center().h(26).px(6).rounded(6).cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => { closeOverlay(props().overlay); openUrl("https://claude.ai/settings/usage"); })
        .child(div().flex_1().child("Usage details on claude.ai"))
        .child(div().text_color(t.dim).child("›")));
  }
}
