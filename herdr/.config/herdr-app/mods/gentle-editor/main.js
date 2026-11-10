// A file as a tab: View (read-only) and Edit modes, Save with a stale-write guard.
// Opened by gentle-files with tab.new { mod: "gentle-editor", props: { root, path, on } }.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { props, readTextFile, writeTextFile, theme, settings, exec, run, spaces, panes, window } from "herdr";
import { isSaveKey, saveHint } from "./keys.js";

const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const LIMIT = 1048576; // readTextFile reads at most 1 MiB; a longer file would be saved truncated

export default class GentleEditor extends View {
  // Setting dirty also renames the tab ("● name" while unsaved), so every path that changes it keeps the tab in step.
  get dirty() { return this._dirty; }
  set dirty(value) {
    if (value === this._dirty) return;
    this._dirty = value;
    if (this.tabId) run("tab.rename", { id: this.tabId, name: value ? `● ${this.name}` : this.name });
  }

  init(_props, cx) {
    const p = props() ?? { root: "", path: "(no file)" };
    this.path = p.path;
    this.root = p.root;
    this.full = `${p.root}/${p.path}`;
    this.on = p.on ?? null;
    this.name = p.path.split("/").pop();
    this.ext = this.name.includes(".") ? this.name.split(".").pop() : "txt";
    this.mode = "view";
    this.saved = null; // text as last read or written: the guard for writeTextFile
    this._dirty = false;
    // Its own tab: the active tab of the active space that holds a gentle-editor pane (null if not found).
    const tab = spaces().find(s => s.active)?.tabs.find(c => c.active);
    this.tabId = tab && panes().some(p => p.tab === tab.id && p.mod === "gentle-editor") ? tab.id : null;
    this.conflict = false;
    this.git = null; // git status letter for this file: M, A, D or U (null when clean or not a repo)
    this.justSaved = false;
    this.error = null;
    this.locked = null; // why this file can only be viewed
    this.handle = cx.focus_handle();
    this.load(cx, true);
  }

  // Same letters as the Files tree; a failed or empty status (clean file, not a repo) clears the letter.
  refreshGit(cx) {
    cx.spawn(async cx => {
      try {
        const r = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "--", this.path], { cwd: this.root, on: this.on });
        const xy = r.code === 0 ? r.stdout.slice(0, 2) : "";
        this.git = !xy.trim() ? null : xy === "??" || xy.includes("A") ? "A" : xy.includes("U") ? "U" : xy.includes("D") ? "D" : "M";
      } catch { this.git = null; }
      finally { cx.notify(); }
    });
  }

  state(text, readonly) {
    const t = theme();
    const code = EditorState.new({
      language: LANG[this.ext] ?? this.ext, value: text, readonly, font_family: settings().font_family, font_size: 13,
      syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 }
    });
    code.on("change", (_e, cx) => { const dirty = code.value() !== this.saved; if (dirty !== this.dirty) { this.dirty = dirty; cx.notify(); } });
    return code;
  }

  load(cx, first) {
    cx.spawn(async cx => {
      try {
        const text = await readTextFile(this.full, { on: this.on });
        if (text === null) this.error = "This file is no longer available";
        else if (text.includes("\0")) this.error = "Binary file · no text preview";
        else {
          this.error = null; this.conflict = false; this.saved = text; this.dirty = false;
          this.locked = this.on ? "Remote file · view only" : text.length >= LIMIT ? "File over 1 MiB · view only" : null;
          this.code?.release();
          this.code = this.state(text, this.mode !== "edit" || Boolean(this.locked));
          this.refreshGit(cx);
        }
      } catch { this.error = "Cannot open this file (binary, too large, or unreadable)"; }
      finally { cx.notify(); }
    });
  }

  setMode(mode, cx) {
    if (!this.code || this.locked || mode === this.mode) return;
    const text = this.code.value();
    this.mode = mode;
    this.code.release();
    this.code = this.state(text, mode !== "edit");
    this.handle.focus();
    cx.notify();
  }

  save(cx) {
    if (!this.code || !this.dirty || this.locked || this.mode !== "edit") return;
    const text = this.code.value();
    cx.spawn(async cx => {
      try {
        await writeTextFile(this.full, text, this.saved);
        this.saved = text; this.dirty = this.code.value() !== text; this.conflict = false;
        this.justSaved = true;
        cx.timer.after(2000, cx => { this.justSaved = false; cx.notify(); });
        this.refreshGit(cx);
      } catch { this.conflict = true; }
      finally { cx.notify(); }
    });
  }

  // "Keep mine": re-read the disk text only to use it as the new guard, then write what is in the editor.
  overwrite(cx) {
    const text = this.code.value();
    cx.spawn(async cx => {
      try {
        const disk = await readTextFile(this.full, { on: this.on });
        await writeTextFile(this.full, text, disk);
        this.saved = text; this.dirty = false; this.conflict = false;
        this.refreshGit(cx);
      } catch { this.error = "Could not save this file"; }
      finally { cx.notify(); }
    });
  }

  render(cx) {
    const t = theme();
    const seg = (label, mode) => div().id(`mode-${mode}`).h(22).px(11).flex().items_center().rounded(6).cursor_pointer().text_size(12)
      .bg(this.mode === mode ? t.selected : t.raised).text_color(this.mode === mode ? t.foreground : t.muted)
      .on_click((_e, cx) => this.setMode(mode, cx)).child(label);
    const button = (id, label, primary, action) => div().id(id).h(28).px(12).flex().items_center().rounded(7).cursor_pointer().text_size(12)
      .border_1().border_color(primary ? t.accent : t.border).bg(primary ? t.accent : t.raised).text_color(primary ? t.accent_foreground : t.foreground)
      .on_click((_e, cx) => action(cx)).child(label);
    // Icon, label and a small key hint, vertically centered.
    const saveLabel = h_flex().gap(7).items_center()
      .child(svg("mods/gentle-editor/save.svg").size(14).flex_none())
      .child(div().child("Save"))
      .child(div().h(16).px(5).flex().items_center().rounded(4).border_1().border_color(t.accent_foreground).opacity(0.75).text_size(10).child(saveHint(window()?.platform)));
    const letter = this.git ?? (this.dirty ? "M" : null), dir = this.path.includes("/") ? this.path.slice(0, this.path.lastIndexOf("/")) : "";
    const canSave = this.dirty && this.mode === "edit" && !this.locked;
    return v_flex().id("gentle-editor").size_full().min_h(0).overflow_hidden().bg(t.background)
      .text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => { if (isSaveKey(e, window()?.platform)) { cx.stop_propagation(); this.save(cx); } })
      .child(h_flex().h(40).flex_none().px(14).gap(10).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child(this.name))
        .when(Boolean(letter), el => el.child(div().text_size(11).text_color(letter === "A" ? t.ansi2 : letter === "D" || letter === "U" ? t.ansi1 : t.blocked).child(letter)))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(dir))
        .child(h_flex().gap(2).p(2).rounded(8).bg(t.raised).border_1().border_color(t.border).child(seg("View", "view")).child(seg("Edit", "edit")))
        .when(this.mode === "edit", el => el.child(button("save", saveLabel, true, cx => this.save(cx)).opacity(canSave ? 1 : 0.5))))
      .when(this.conflict, el => el.child(h_flex().mx(12).mt(10).px(12).py(8).gap(10).items_center().rounded(9).border_1().border_color(t.blocked).text_size(12.5).text_color(t.blocked)
        .child(div().flex_1().child("Changed on disk since you opened it."))
        .child(button("keep-mine", "Keep mine", false, cx => this.overwrite(cx)))
        .child(button("reload", "Reload", true, cx => this.load(cx)))))
      .child(this.code ? Editor.new(this.code).flex_1().min_h(0) : div().p(12).text_color(t.dim).child(this.error || "Loading file…"))
      .child(h_flex().h(26).flex_none().px(14).gap(14).items_center().border_t(1).border_color(t.border).text_size(12).text_color(t.dim)
        .child(div().child(this.locked ?? (this.mode === "edit" ? "Editing" : "View")))
        .child(div().flex_1().text_right().child(this.dirty ? "Unsaved changes" : this.justSaved ? "Saved" : "")));
  }
}
