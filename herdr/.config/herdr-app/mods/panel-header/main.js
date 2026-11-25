// The header over a sub-row Agent sidebar shows in the panel (agent-sidebar's showInPanel):
// what it is, and a close button that hides the panel (and ends the viewer
// agent-sidebar started for it, if any). Reads shared "agent-sidebar.panelView":
// { terminal, title, viewer }.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, shared, setShared, run, hc } from "herdr";

export default class PanelHead extends View {
  close() {
    const v = shared("agent-sidebar.panelView");
    run("layout.hide", { id: "panel" });
    run("layout.select", { stack: "panel-body", child: "files" });
    if (v?.viewer) hc(["kill", v.terminal]).catch(() => null);
    setShared("agent-sidebar.panelView", null);
  }

  render() {
    const t = theme();
    const v = shared("agent-sidebar.panelView");
    return h_flex().id("panel-head").size_full().px(10).gap(8).items_center().bg(t.chrome).border_b(1).border_color(t.border)
      .text_size(12).text_color(t.muted)
      .child(div().flex_1().min_w(0).truncate().child(v?.title ?? ""))
      .child(h_flex().id("panel-close").size(20).flex_none().items_center().justify_center().rounded(5).cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => this.close())
        .child(svg("mods/workspace-chrome/x.svg").size(12)));
  }
}
