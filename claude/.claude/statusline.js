#!/usr/bin/env node
// Claude Code status line: model, thinking mode, effort. Runs on macOS and Windows (no jq/bash needed).
let raw = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let d = {};
  try { d = JSON.parse(raw); } catch {}

  const c = (n, s, bold) => `\x1b[${bold ? "1;" : ""}38;5;${n}m${s}\x1b[0m`;
  const sep = c(240, "  ●  ");

  const model = (d.model && d.model.display_name) || "Claude";
  const thinking = !!(d.thinking && d.thinking.enabled);
  const effort = d.effort && d.effort.level;

  const bar = (pct, w = 10) => {
    const n = Math.round((Math.min(Math.max(pct, 0), 100) / 100) * w);
    const col = pct >= 85 ? 203 : pct >= 60 ? 215 : 114;
    return c(col, "\u2588".repeat(n)) + c(238, "\u2591".repeat(w - n)) + c(col, ` ${Math.round(pct)}%`);
  };
  const ctx = d.context_window && d.context_window.used_percentage;
  const limit = d.rate_limits && d.rate_limits.five_hour;

  const parts = [
    c(141, ` ${model}`, true),
    thinking ? c(114, "󰧑 On") : c(245, "󰧑 Off"),
  ];
  if (effort) parts.push(c(215, `󰓅 ${effort}`));
  if (typeof ctx === "number") parts.push(c(245, "ctx ") + bar(ctx));
  if (limit && limit.resets_at) {
    let t = Number(limit.resets_at);
    if (t < 1e12) t *= 1000; // epoch seconds -> ms
    const mins = Math.max(0, Math.round((t - Date.now()) / 60000));
    const left = mins >= 60 ? `${Math.floor(mins / 60)}h ${mins % 60}m` : `${mins}m`;
    const at = new Date(t).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
    parts.push(c(111, `\u21bb ${left}`) + c(245, ` (${at})`));
  }

  process.stdout.write(parts.join(sep) + "\n");
});
