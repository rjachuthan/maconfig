// The usage popup, opened from the status bar's Claude chip: one tab per
// provider (Claude, Codex, Copilot); the last one picked opens next time.
// Every tab has the same frame and the same size: header, limits, one list of
// facts, and the link pinned to the bottom, so switching never jumps or clips.
import { div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, shared, setShared, exec, window, closeOverlay, props } from "herdr";
import { PROVIDERS, refresh, until, ago, color } from "./usage.js";

export const POPUP = { width: 360, height: 512 };
const PAD = 14, INNER = POPUP.width - PAD * 2;
const TAB = "usage.tab";
// The Copilot account picked when gh has more than one; the last one picked opens next time.
const ACCOUNT = "usage.copilot.account";
const PAGES = {
  claude: ["claude.ai", "https://claude.ai/settings/usage"],
  codex: ["chatgpt.com", "https://chatgpt.com/codex/settings/usage"],
  copilot: ["github.com", "https://github.com/settings/copilot/features"],
};

// The company's own mark: full color as drawn (image), or a one-color mark
// (Copilot's) in the text color. Dimmed on a tab that isn't picked.
const logo = (t, p, size, on) => (p.colored
  ? image(`mods/gentle-status/${p.icon}.svg`).w(size).h(size).flex_none()
  : svg(`mods/gentle-status/${p.icon}.svg`).size(size).flex_none().text_color(on ? t.foreground : t.muted)
).when(!on, el => el.opacity(0.5));

// "Rate limited, trying again later" -> "Rate limited": the header has one short line.
const short = e => e.split(/[,:(]/)[0].trim();

const openUrl = url => {
  const p = window()?.platform;
  exec(p === "macos" ? "open" : p === "windows" ? "explorer.exe" : "xdg-open", [url]).catch(() => {});
};

export class UsagePopup {
  init(cx) {
    // Fresh numbers when opened, unless the last ones are under a minute old.
    for (const p of PROVIDERS) if (Date.now() - (shared(p.key)?.checked ?? 0) > 60000) refresh(p.id);
    cx.timer.every(30000, cx => cx.notify());
  }

  tabs(t, current) {
    return h_flex().p(3).gap(2).rounded(9).bg(t.input).border(1).border_color(t.border).flex_none()
      .children(PROVIDERS.map(p => {
        const on = p.id === current.id;
        return h_flex().id(`usage-tab-${p.id}`).flex_1().h(28).gap(7).items_center().justify_center().rounded(7).cursor_pointer()
          .text_size(12.5).text_color(on ? t.foreground : t.muted)
          .when(on, el => el.bg(t.raised).font_semibold())
          .when(!on, el => el.hover(s => s.bg(t.hover).text_color(t.foreground)))
          .on_click((_e, cx) => { setShared(TAB, p.id); cx.notify(); })
          .child(logo(t, p, 14, on))
          .child(p.name);
      }));
  }

  header(t, p, u) {
    return h_flex().items_center().gap(10).flex_none()
      // The logo spans both lines beside it: the name and plan, then when it was read.
      .child(div().size(40).flex_none().flex().items_center().justify_center().rounded(10).bg(t.raised).border(1).border_color(t.border)
        .child(logo(t, p, 24, true)))
      .child(v_flex().gap(3)
        .child(h_flex().items_center().gap(7)
          .child(div().font_semibold().text_size(14).text_color(t.foreground).child(p.name))
          .when(Boolean(u.plan), el => el.child(div().px(6).h(18).flex().items_center().rounded(5).bg(t.raised)
            .text_size(10.5).text_color(t.muted).child(u.plan))))
        // A failed refresh with numbers still shown: one amber line, not a banner.
        .child(u.error && u.limits?.length && !u.loading
          ? h_flex().gap(5).items_center().text_size(11).text_color(t.working).tooltip(u.error)
            .child(div().size(5).rounded_full().bg(t.working)).child(`${short(u.error)} · ${u.updated ? `from ${ago(u.updated)}` : "older numbers"}`)
          : div().text_size(11).text_color(t.dim).child(u.loading ? "Updating…" : u.updated ? `Updated ${ago(u.updated)}` : "Not loaded yet")))
      .child(div().flex_1())
      .child(div().id("usage-refresh").size(28).flex_none().flex().items_center().justify_center().rounded(7).cursor_pointer()
        .text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).tooltip("Refresh")
        .on_click((_e, cx) => { refresh(p.id, { force: true }); cx.notify(); })
        .child(svg("mods/gentle-status/refresh.svg").size(14)));
  }

  limit(t, p, l) {
    const fill = color(t, l, p.tint);
    return v_flex().gap(6).flex_none()
      .child(h_flex().items_center().gap(8)
        .child(div().flex_1().text_color(t.foreground).child(l.name))
        .child(div().font_semibold().text_color(l.percent >= 70 || l.severity !== "normal" ? fill : t.foreground).child(`${l.percent}%`)))
      .child(div().w(INNER).h(6).rounded(3).bg(t.border)
        .child(div().h_full().rounded(3).bg(fill).w(Math.max(l.percent ? 4 : 0, Math.min(INNER, (l.percent * INNER) / 100)))))
      .child(h_flex().items_center().text_size(11).text_color(t.dim)
        .child(div().flex_1().child(l.resets ? `Resets in ${until(l.resets)}` : ""))
        .when(Boolean(l.detail), el => el.child(div().child(`${l.detail} used`))));
  }

  // One pill per gh account, only when there are several.
  accounts(t, list, current) {
    return h_flex().gap(6).flex_none().children(list.map(a => {
      const on = a.login === current;
      return h_flex().id(`usage-account-${a.login}`).h(22).px(8).gap(6).items_center().rounded(6).cursor_pointer()
        .text_size(11.5).border(1).border_color(t.border)
        .text_color(on ? t.foreground : t.muted)
        .when(on, el => el.bg(t.raised))
        .when(!on, el => el.hover(s => s.bg(t.hover).text_color(t.foreground)))
        .on_click((_e, cx) => { setShared(ACCOUNT, a.login); cx.notify(); })
        .when(Boolean(a.error), el => el.child(div().size(5).rounded_full().bg(t.blocked)))
        .child(a.login);
    }));
  }

  section(t, s) {
    return v_flex().gap(2).flex_none()
      .child(div().pb(4).text_size(10.5).font_semibold().text_color(t.dim).child(s.title.toUpperCase()))
      .children(s.rows.map(r => h_flex().h(24).items_center().gap(12)
        .child(div().flex_1().text_color(t.muted).child(r.name))
        .child(div().text_color(t.foreground).child(r.value))));
  }

  render() {
    const t = theme();
    const p = PROVIDERS.find(x => x.id === shared(TAB)) ?? PROVIDERS[0];
    let u = shared(p.key) ?? {};
    // Copilot with several gh accounts: the picked one's numbers, the rest kept for the pills.
    const list = u.accounts?.length > 1 ? u.accounts : null;
    const acct = list && (list.find(a => a.login === shared(ACCOUNT)) ?? list.find(a => !a.error) ?? list[0]);
    if (acct) u = { ...u, plan: null, limits: null, section: null, error: null, ...acct };
    const limits = u.limits ?? [];
    const rule = () => div().h(1).bg(t.border).flex_none();
    // A fixed size, not size_full: a popup sizes to its content, and every tab
    // keeps the fullest one's (Claude's) height.
    return v_flex().w(POPUP.width).h(POPUP.height).flex_none().overflow_hidden().bg(t.popover).p(PAD).gap(12).text_size(12.5).text_color(t.muted).id("usage-popup")
      .child(this.tabs(t, p))
      .child(this.header(t, p, u))
      .when(Boolean(acct), el => el.child(this.accounts(t, list, acct.login)))
      // Nothing to show at all: the reason, where the limits would be.
      .when(Boolean(u.error && !limits.length), el => el.child(h_flex().px(10).py(8).gap(8).items_center().rounded(7).bg(t.raised).flex_none()
        .child(div().size(6).rounded_full().flex_none().bg(t.blocked))
        .child(div().flex_1().text_size(11.5).text_color(t.foreground).child(u.error))))
      .child(rule())
      .when(!limits.length && !u.error, el => el.child(div().py(8).text_color(t.dim).child(u.loading || !u.checked ? "Loading usage…" : "No limits reported for this plan")))
      .child(v_flex().gap(14).flex_none().children(limits.map(l => this.limit(t, p, l))))
      .when(Boolean(u.section?.rows?.length), el => el.child(rule()).child(this.section(t, u.section)))
      .child(div().flex_1())
      .child(rule())
      .child(h_flex().id("usage-open").items_center().h(30).px(6).rounded(7).cursor_pointer().flex_none()
        .text_color(t.muted).hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => { closeOverlay(props().overlay); openUrl(PAGES[p.id][1]); })
        .child(div().flex_1().child(`Open usage on ${PAGES[p.id][0]}`))
        .child(svg("mods/gentle-chrome/chevron-right.svg").size(13).text_color(t.dim)));
  }
}
