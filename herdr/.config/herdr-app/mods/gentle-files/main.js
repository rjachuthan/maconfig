// cloned_from: files (herdr-app 0.1.12); changes: file-type icons, files open in an editor tab (gentle-editor) instead of an in-panel preview, keeps the last folder when a mod pane takes focus, git-index tree, file search
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, focused, exec, watchFolder, theme, settings, window, run } from "herdr";

// Last location seen with a terminal focused, per space. A mod pane (an editor tab, this panel) or no focus keeps
// that space's own location (its folder when it has none yet), so opening a file does not reset the panel and
// switching spaces never shows another space's files; the key also ignores slash style and trailing slashes.
const lastBySpace = new Map(); // space id -> last location seen there with a terminal focused
const clean = p => { const s = p?.replaceAll("\\", "/"); return s && s.length > 1 && !/^[A-Za-z]:\/$/.test(s) ? s.replace(/\/+$/, "") || "/" : s; };
function location() {
  const space = spaces().find(s => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const modFocus = !f || pane?.terminal === null || (f.pane === null && f.terminal === null);
  if (modFocus) return lastBySpace.get(space?.id) ?? { cwd: clean(space?.folder), on: space?.machine ?? null, space: space?.id };
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  const location = { cwd: clean(pane?.cwd || f?.cwd || space?.folder), on, space: space?.id };
  if (location.cwd) lastBySpace.set(space?.id, location);
  return location;
}
const key = () => JSON.stringify(location());
const CODE = new Set("js mjs cjs jsx ts tsx mts cts json jsonc html htm css scss svelte vue py rs go java kt gradle c h cpp cs rb php sh ps1 bat sql yaml yml toml xml svg lua swift dart".split(" "));
const IMAGE = new Set("png jpg jpeg gif webp bmp ico avif".split(" "));
const TEXT = new Set("md mdx txt rst log csv lock gitignore gitattributes env pro".split(" "));
// Icon and color by file type: code green, images green, text/config yellow, anything else muted.
function kind(name, t) {
  const ext = name.includes(".") ? name.split(".").pop().toLowerCase() : "";
  if (name.startsWith(".") && !ext) return { icon: "file-text", color: t.ansi3 };
  if (name.startsWith(".") && TEXT.has(ext)) return { icon: "file-text", color: t.ansi3 };
  if (CODE.has(ext)) return { icon: "file-code", color: t.ansi2 };
  if (IMAGE.has(ext)) return { icon: "file-image", color: t.ansi2 };
  if (ext === "md" || ext === "mdx") return { icon: "file-text", color: t.ansi4 };
  if (TEXT.has(ext)) return { icon: "file-text", color: t.ansi3 };
  return { icon: "file", color: t.muted };
}
const NONE = [];
const PER_FOLDER = 500, TOTAL = 5000, HITS = 100, IGNORED_TREE = 20000, IGNORED_SEARCH = 50000;
// git reports mark paths with "/" and a lowercase drive on Windows; herdr may report "\\" and an uppercase one.
const norm = p => p.replaceAll("\\", "/").replace(/^[A-Za-z]:/, m => m.toLowerCase());
const sortEntries = list => list.sort((a, b) => Number(b.dir) - Number(a.dir) || a.name.localeCompare(b.name));

// The whole tree from `git ls-files` paths: Map folder path ("" is the root) -> entries.
// `ignoredOut` is the `--others --ignored --directory` listing: ignored directories end in "/" and are not
// expanded (they stay one row, listed lazily); a path that is already listed is never duplicated.
function fromPaths(stdout, ignoredOut = "") {
  const split = out => out.split("\0").filter(Boolean).map(p => p.replaceAll("\\", "/"));
  const tracked = [...new Set(split(stdout))], known = new Set(tracked);
  const ignored = split(ignoredOut).filter(p => !known.has(p.replace(/\/$/, "")));
  const ignoredFiles = new Set(ignored.filter(p => !p.endsWith("/"))), ignoredDirs = new Set(ignored.filter(p => p.endsWith("/")).map(p => p.slice(0, -1)));
  const files = [...tracked, ...ignoredFiles];
  const folders = new Map();
  for (const file of [...tracked, ...ignored]) {
    const parts = file.replace(/\/$/, "").split("/");
    let folder = "";
    parts.forEach((name, i) => {
      const path = folder ? `${folder}/${name}` : name;
      const dir = i < parts.length - 1 || ignoredDirs.has(path);
      if (!folders.has(folder)) folders.set(folder, new Map());
      if (dir || !folders.get(folder).has(name)) folders.get(folder).set(name, { dir, ignored: ignoredDirs.has(path) || ignoredFiles.has(path) });
      folder = path;
    });
  }
  const entries = new Map();
  for (const [folder, names] of folders) entries.set(folder, sortEntries([...names].map(([name, v]) => ({ name, dir: v.dir, ...(v.ignored ? { ignored: true } : {}) }))));
  return { entries, index: { files, dirs: new Set(entries.keys()), ignoredFiles, ignoredDirs } };
}

// A whole ignored folder from its `--others --ignored` listing (every file below it): Map folder -> entries,
// all marked ignored. Past IGNORED_TREE paths the list is cut and `capped` is set.
function ignoredSubtree(stdout, folder) {
  const paths = stdout.split("\0").filter(Boolean);
  const { entries } = fromPaths(paths.slice(0, IGNORED_TREE).join("\0"));
  const tree = new Map([[folder, []]]);
  for (const [path, list] of entries) if (path === folder || path.startsWith(folder + "/")) tree.set(path, list.map(e => ({ ...e, ignored: true })));
  return { tree, capped: paths.length > IGNORED_TREE };
}

// Every ignored file outside dependency trees; keeps node_modules out of the results and bounds the list.
function ignoredPaths(stdout) {
  return stdout.split("\0").filter(p => p && !/(^|[\\/])node_modules[\\/]/.test(p)).slice(0, IGNORED_SEARCH).map(p => p.replaceAll("\\", "/"));
}

// Search hits for a lowercase query: name starts with it, then name contains it, then path contains it.
// Non-ignored matches come before ignored ones, so they win the HITS cap.
function rankHits(files, ignoredFiles, extra, q) {
  const ranked = [];
  const add = (path, ignored) => {
    const lower = path.toLowerCase(), name = lower.slice(lower.lastIndexOf("/") + 1);
    const rank = name.startsWith(q) ? 0 : name.includes(q) ? 1 : lower.includes(q) ? 2 : -1;
    if (rank >= 0) ranked.push({ path, rank, ignored });
  };
  for (const path of files) add(path, ignoredFiles.has(path));
  for (const path of extra) add(path, true);
  return ranked.sort((a, b) => Number(a.ignored) - Number(b.ignored) || a.rank - b.rank || a.path.length - b.path.length || a.path.localeCompare(b.path)).slice(0, HITS).map(({ path, ignored }) => ({ path, ignored }));
}

async function directory(path, on) {
  const windowsDirectory = async () => {
    // Windows PowerShell otherwise uses the console code page; exec decodes UTF-8.
    // Links keep directory attributes even when dangling; check their target.
    // Other reparse points (OneDrive's folders) have no LinkType and are folders.
    // PowerShell reads curly single quotes as quotes too, so they're doubled like '.
    const r = await exec("powershell", ["-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); & { param($p) @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Where-Object Name -ne '.git' | Select-Object -First 501 | ForEach-Object { @{ name=$_.Name; dir=($_.PSIsContainer -and (-not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -or -not $_.LinkType -or ($_.Target -and [IO.Directory]::Exists(([IO.Path]::Combine([IO.Path]::GetDirectoryName($_.FullName), $_.Target[0])))))) } }) | ConvertTo-Json -Compress } '" + path.replace(/['‘’‚‛]/g, "$&$&") + "'"], { on });
    if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
    const result = JSON.parse(r.stdout || "[]");
    return Array.isArray(result) ? result : [result];
  };
  if (!on && window()?.platform === "windows") return windowsDirectory();
  const script = 'n=0; for p in "$1"/* "$1"/.[!.]* "$1"/..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; name=${p##*/}; [ "$name" = .git ] && continue; if [ -d "$p" ]; then kind=d; else kind=f; fi; printf "%s\\0%s\\0" "$kind" "$name"; n=$((n+1)); [ "$n" -gt 500 ] && break; done; test -d "$1"';
  let r;
  try { r = await exec("sh", ["-c", script, "files", path], { on }); }
  catch (e) {
    if (on && String(e).includes("cannot start sh: program not found")) return windowsDirectory();
    throw e;
  }
  if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
  const fields = r.stdout.split("\0"), out = [];
  for (let i = 0; i + 1 < fields.length; i += 2) out.push({ name: fields[i + 1], dir: fields[i] === "d" });
  return out;
}

export default class Files extends View {
  init(_props, cx) {
    this.saved = new Map();
    this.entries = new Map(); this.folders = new Set(); this.pending = new Set(); this.marks = {}; this.ignoredDirs = new Set();
    // Lazily loaded ignored subtrees (root dir -> Map folder -> entries), merged back after every refresh rebuild.
    this.ignoredTrees = new Map(); this.ignoredFound = null; this.ignoredStale = false; this.ignoredLoading = false;
    this.index = null; this.query = ""; this.hits = null;
    this.search = InputState.new({ placeholder: "Search files" });
    this.search.on("change", (_e, cx) => { this.query = this.search.value(); cx.notify(); });
    this.refresh(cx);
    cx.timer.every(10000, cx => this.refresh(cx));
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    const context = this.context;
    cx.spawn(async cx => {
      try { while (this.context === context) { await watchFolder(root); if (this.current(context)) this.refresh(cx); } }
      catch { if (this.context === context) this.watched = null; }
    });
  }

  current(context) {
    return this.context === context && key() === context.key;
  }

  async loadFolder(path, context) {
    const { on, cwd: root } = context;
    const entries = await directory(path ? `${root}/${path}` : root, on);
    if (!this.current(context) || (path && !this.folders.has(path))) return;
    const used = [...this.entries.entries()].filter(([p]) => p !== path).reduce((n, [, e]) => n + e.length, 0);
    // Children of an ignored folder are ignored too; its subfolders list lazily the same way.
    const shown = entries.slice(0, Math.max(0, Math.min(PER_FOLDER, TOTAL - used)));
    if (this.ignoredDirs.has(path)) for (const e of shown) { e.ignored = true; if (e.dir) this.ignoredDirs.add(path ? `${path}/${e.name}` : e.name); }
    this.entries.set(path, sortEntries(shown));
    if (this.ignoredDirs.has(path)) this.ignoredTrees.set(path, new Map([[path, this.entries.get(path)]]));
    if (entries.length > PER_FOLDER || used + entries.length > TOTAL) this.limited = true;
  }

  // Expands an ignored folder: one git call lists every ignored file below it and the subtree is built in memory,
  // so nested ignored folders open instantly. The per-folder listing is only the fallback when git fails.
  async loadTree(path, context) {
    if (this.index) {
      const r = await exec("git", ["ls-files", "-z", "--others", "--ignored", "--exclude-standard", "--", `:(literal)${path}/`], { cwd: context.cwd, on: context.on }).catch(() => null);
      if (!this.current(context) || !this.folders.has(path)) return;
      if (r?.code === 0) {
        const { tree, capped } = ignoredSubtree(r.stdout, path);
        for (const [folder, list] of tree) { this.entries.set(folder, list); this.ignoredDirs.add(folder); }
        this.ignoredTrees.set(path, tree);
        if (capped) this.limited = true;
        return;
      }
    }
    await this.loadFolder(path, context);
  }

  async ensureTree(path, context) {
    if (this.entries.has(path) || this.pending.has(path)) return;
    this.pending.add(path);
    try { await this.loadTree(path, context); }
    finally { if (this.context === context) this.pending.delete(path); }
  }

  refresh(cx) {
    const { cwd, on } = location(), next = key();
    if (next !== this.context?.key) {
      if (this.context) this.saved.set(this.context.key, { folders: this.folders });
      const saved = this.saved.get(next);
      this.context = { key: next, cwd, on }; this.root = cwd; this.on = on; this.entries = new Map(); this.index = null; this.ignoredDirs = new Set(); this.ignoredTrees = new Map(); this.ignoredFound = null; this.ignoredStale = false; this.ignoredLoading = false; this.hits = null; this.folders = new Set(saved?.folders);
      this.pending = new Set(); this.marks = {}; this.watched = null; this.error = null; this.limited = false;
      this.loading = false;
    }
    if (!cwd || this.loading) return;
    const context = this.context;
    this.loading = true;
    this.limited = false;
    cx.spawn(async cx => {
      try {
        // Inside a git repo one listing gives the whole tree; otherwise folders are listed lazily.
        const listing = await exec("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard"], { cwd, on }).catch(() => null);
        if (!this.current(context)) return;
        if (listing?.code === 0) {
          const ignored = await exec("git", ["ls-files", "-z", "--others", "--ignored", "--exclude-standard", "--directory"], { cwd, on }).catch(() => null);
          if (!this.current(context)) return;
          const built = fromPaths(listing.stdout, ignored?.code === 0 ? ignored.stdout : "");
          this.entries = built.entries; this.index = built.index; this.ignoredDirs = new Set(built.index.ignoredDirs);
          // Loaded ignored subtrees are not in the git listing; merge them back so an open folder never blinks.
          for (const [root, tree] of this.ignoredTrees) {
            for (const [folder, list] of tree) { this.entries.set(folder, list); this.ignoredDirs.add(folder); }
            this.ignoredDirs.add(root);
          }
          this.ignoredStale = true;
          // Only folders restored without a loaded subtree (a switched-back location) are fetched, parents first.
          for (const path of [...this.folders].sort((a, b) => a.length - b.length)) {
            if (!this.current(context)) return;
            if (this.ignoredDirs.has(path)) await this.ensureTree(path, context);
          }
        } else {
          this.index = null;
          for (const path of ["", ...this.folders]) {
            if (!this.current(context)) return;
            await this.loadFolder(path, context);
          }
        }
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null);
        const marks = {};
        if (top?.code === 0) {
          // Writes nothing under .git (index lock, fsmonitor cookie): the folder watch would refresh again.
          const status = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"], { cwd, on }).catch(() => null);
          if (status?.code === 0) for (const entry of status.stdout.split("\0").filter(Boolean).slice(0, TOTAL)) {
            const xy = entry.slice(0, 2);
            marks[`${norm(top.stdout.trim())}/${entry.slice(3)}`] = xy === "??" || xy.includes("A") ? "A" : xy.includes("U") ? "U" : xy.includes("D") ? "D" : "M";
          }
        }
        if (!this.current(context)) return;
        this.marks = marks; this.error = null; this.watch(cwd, cx);
      } catch (e) { if (this.current(context)) this.error = String(e); }
      finally { if (this.context === context) this.loading = false; cx.notify(); }
    });
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) {
        this.folders.delete(folder);
        if (!this.index) this.entries.delete(folder);
        const tree = this.ignoredTrees.get(folder);
        if (tree) { for (const p of tree.keys()) this.entries.delete(p); this.ignoredTrees.delete(folder); }
      }
    } else {
      this.folders.add(path);
      if ((!this.index || this.ignoredDirs.has(path)) && !this.entries.has(path) && !this.pending.has(path)) {
        const context = this.context;
        cx.spawn(async cx => {
          try { await this.ensureTree(path, context); }
          catch (e) { if (this.current(context)) this.error = String(e); }
          finally { cx.notify(); }
        });
      }
    }
    cx.notify();
  }

  // A file opens as its own tab holding gentle-editor; reopening it selects that tab.
  open(path) {
    const space = spaces().find(p => p.active);
    if (!space) return;
    const full = `${this.root}/${path}`, name = path.split("/").pop();
    this.tabs ??= new Map();
    const known = this.tabs.get(full);
    if (known && space.tabs.some(c => c.id === known)) return run("tab.select", { id: known });
    const before = new Set(space.tabs.map(c => c.id));
    run("tab.new", { name, space: space.id, mod: "gentle-editor", props: { root: this.root, path, on: this.on } });
    // The new tab's id is not returned; find it on the next tick so a second click selects it.
    this.waiting = { full, before, space: space.id };
  }

  track() {
    const w = this.waiting;
    if (!w) return;
    const space = spaces().find(p => p.id === w.space), fresh = space?.tabs.find(c => !w.before.has(c.id));
    if (fresh) { this.tabs.set(w.full, fresh.id); this.waiting = null; }
  }

  rows(prefix, depth, out, t) {
    if (out.length >= TOTAL || depth > 40) return out;
    for (const entry of this.entries.get(prefix) ?? []) {
      if (out.length >= TOTAL) break;
      const path = prefix ? `${prefix}/${entry.name}` : entry.name, open = this.folders.has(path), mark = entry.ignored ? null : this.marks[`${norm(this.root)}/${path}`];
      const k = kind(entry.name, t), dim = entry.ignored;
      out.push(h_flex().id(`file-${path}`).h(28).flex_none().pl(8 + depth * 18).pr(8).gap(7).items_center().rounded(7).cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => entry.dir ? this.toggle(path, cx) : this.open(path))
        .child(entry.dir ? svg(`mods/gentle-files/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none().text_color(t.dim) : div().w(12).flex_none())
        .child(entry.dir ? svg(`mods/gentle-files/${open ? "folder-open" : "folder"}.svg`).size(15).flex_none().text_color(dim ? t.dim : t.ansi5) : svg(`mods/gentle-files/${k.icon}.svg`).size(15).flex_none().text_color(dim ? t.dim : k.color))
        .child(div().flex_1().min_w(0).truncate().text_color(dim ? t.dim : t.foreground).child(entry.name))
        .when(Boolean(mark), el => el.child(div().text_size(11).text_color(mark === "A" ? t.ansi2 : mark === "D" || mark === "U" ? t.ansi1 : t.blocked).child(mark))));
      if (entry.dir && open && this.pending.has(path)) out.push(div().h(24).flex_none().pl(8 + (depth + 1) * 18 + 19).flex().items_center().text_size(12).text_color(t.dim).child("Loading…"));
      else if (entry.dir && open) this.rows(path, depth + 1, out, t);
    }
    return out;
  }

  // Ignored files are not in the index (their folders stay collapsed): fetched once per refresh on the first query.
  loadIgnoredFound(cx) {
    const context = this.context, index = this.index;
    this.ignoredLoading = true;
    cx.spawn(async cx => {
      try {
        const r = await exec("git", ["ls-files", "-z", "--others", "--ignored", "--exclude-standard"], { cwd: context.cwd, on: context.on }).catch(() => null);
        if (this.context !== context || this.index !== index) return;
        const known = new Set(index.files);
        this.ignoredFound = r?.code === 0 ? ignoredPaths(r.stdout).filter(p => !known.has(p)) : [];
        this.ignoredStale = false;
      } finally { if (this.context === context) this.ignoredLoading = false; cx.notify(); }
    });
  }

  // Matches for the query, as { path, ignored }.
  results(cx) {
    const q = this.query.trim().toLowerCase();
    if (!q) return null;
    if (this.index && (!this.ignoredFound || this.ignoredStale) && !this.ignoredLoading) this.loadIgnoredFound(cx);
    const source = this.index?.files ?? [...this.entries].flatMap(([folder, list]) => list.filter(e => !e.dir).map(e => folder ? `${folder}/${e.name}` : e.name));
    const extra = (this.index && this.ignoredFound) || NONE;
    if (this.hits?.q === q && this.hits.source === source && this.hits.extra === extra) return this.hits.list;
    const list = rankHits(source, this.index?.ignoredFiles ?? new Set(), extra, q);
    this.hits = { q, source, extra, list };
    return list;
  }

  hitRows(hits, t) {
    return hits.map(({ path, ignored: dim }) => {
      const cut = path.lastIndexOf("/"), name = path.slice(cut + 1), folder = cut < 0 ? "" : path.slice(0, cut), k = kind(name, t);
      return h_flex().id(`hit-${path}`).h(28).flex_none().px(8).gap(7).items_center().rounded(7).cursor_pointer().hover(s => s.bg(t.hover))
        .on_click(() => this.open(path))
        .child(svg(`mods/gentle-files/${k.icon}.svg`).size(15).flex_none().text_color(dim ? t.dim : k.color))
        .child(div().flex_none().max_w(160).truncate().text_color(dim ? t.dim : t.foreground).child(name))
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(folder));
    });
  }

  render(cx) {
    if (key() !== this.context?.key) this.refresh(cx);
    this.track();
    const t = theme(), hits = this.results(cx);
    return v_flex().id("files").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Files"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(this.root?.split(/[\/]/).pop() ?? "")))
      .child(h_flex().id("files-search").h(32).flex_none().mx(8).mt(8).px(10).gap(8).items_center().rounded(8).border_1().border_color(t.border).bg(t.raised)
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .child(svg("mods/gentle-files/search.svg").size(14).flex_none().text_color(t.dim))
        .child(Input.new(this.search).flex_1().min_w(0).h_full().text_size(12).text_color(t.foreground))
        .when(Boolean(this.query), el => el.child(div().id("files-search-clear").size(18).flex_none().flex().items_center().justify_center().rounded(4).cursor_pointer().text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
          .on_click((_e, cx) => { this.search.set_value(""); this.query = ""; cx.notify(); }).child("×"))))
      .child(v_flex().id("files-tree").flex_1().min_h(0).overflow_y_scrollbar().p(6).children(hits ? this.hitRows(hits, t) : this.rows("", 0, [], t))
        .when(Boolean(hits) && !hits.length, el => el.child(div().p(8).text_size(12).text_color(t.dim).child("No matching files")))
        .when(!hits && (Boolean(this.error) || !this.entries.get("")?.length), el => el.child(div().p(8).text_size(12).text_color(t.dim).child(this.error || (this.loading ? "Loading files…" : this.root ? "No files" : "No folder"))))
        .when(this.limited && !hits, el => el.child(div().p(8).text_size(11).text_color(t.dim).child("File list limited to 500 entries per folder and 5,000 total"))));
  }
}
