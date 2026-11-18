// Claude plan usage, as Claude Code's /usage reads it: the OAuth usage endpoint,
// signed with the login Claude Code keeps (macOS Keychain, else
// ~/.claude/.credentials.json, which is where it lives on Windows and Linux).
// The token is only read, never refreshed: refreshing it here would rotate the
// refresh token under Claude Code and sign it out. An expired one shows as
// stale until Claude Code next refreshes it.
// The result goes to shared("claude.usage") (no token in it), so the bar and the
// popup read the same thing.
import { exec, readTextFile, home, shared, setShared, window } from "herdr";

export const KEY = "claude.usage";
const URL = "https://api.anthropic.com/api/oauth/usage";

async function credentials() {
  if (window()?.platform === "macos") {
    try {
      const r = await exec("security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"], { timeout: 10000 });
      if (r.code === 0 && r.stdout.trim()) return JSON.parse(r.stdout).claudeAiOauth;
    } catch {}
  }
  const text = await readTextFile(`${home()}/.claude/.credentials.json`);
  return text ? JSON.parse(text).claudeAiOauth : null;
}

// "default_claude_max_5x" -> "Max 5x"; else the subscription type ("pro" -> "Pro").
export function planName(tier, type) {
  const m = /max_(\d+x)/.exec(tier ?? "");
  if (m) return `Max ${m[1]}`;
  return type ? type[0].toUpperCase() + type.slice(1) : null;
}

// The endpoint's `limits`, else its older five_hour / seven_day fields.
export function parseLimits(body) {
  const short = { session: "5h", weekly_all: "wk" };
  if (Array.isArray(body?.limits) && body.limits.length) {
    return body.limits.map(l => ({
      kind: l.kind,
      label: l.scope?.model?.display_name ?? l.scope?.surface?.display_name ?? short[l.kind] ?? l.kind,
      name: l.kind === "session" ? "Current session" : l.kind === "weekly_all" ? "Weekly · all models" : `Weekly · ${l.scope?.model?.display_name ?? l.scope?.surface?.display_name ?? l.kind}`,
      percent: Math.round(l.percent ?? 0),
      severity: l.severity ?? "normal",
      resets: l.resets_at ?? null,
    }));
  }
  return [["five_hour", "5h", "Current session"], ["seven_day", "wk", "Weekly · all models"]]
    .filter(([k]) => body?.[k]).map(([k, label, name]) => ({ kind: k === "five_hour" ? "session" : "weekly_all", label, name, percent: Math.round(body[k].utilization ?? 0), severity: "normal", resets: body[k].resets_at ?? null }));
}

export async function refresh() {
  // loading is saved with the rest: one left behind by a reload mid-request expires.
  const prev = shared(KEY) ?? {};
  if (prev.loading && Date.now() - prev.loading < 30000) return;
  setShared(KEY, { ...prev, loading: Date.now() });
  const done = (patch) => setShared(KEY, { ...prev, ...patch, loading: false, checked: Date.now() });
  try {
    const cred = await credentials();
    if (!cred?.accessToken) return done({ error: "Not signed in to Claude Code" });
    const plan = planName(cred.rateLimitTier, cred.subscriptionType);
    if (cred.expiresAt && cred.expiresAt < Date.now()) return done({ plan, error: "Login expired: run claude to refresh it" });
    const res = await fetch(URL, { headers: { Authorization: `Bearer ${cred.accessToken}`, "anthropic-beta": "oauth-2025-04-20", "Content-Type": "application/json" } });
    if (res.status === 401) return done({ plan, error: "Login expired: run claude to refresh it" });
    if (res.status === 429) return done({ plan, error: "Rate limited, trying again later" });
    if (!res.ok) return done({ plan, error: `Usage request failed (${res.status})` });
    const body = await res.json();
    const breakdown = (body.seven_day_breakdown?.rows ?? []).filter(r => r.percent > 0).map(r => ({ name: r.display_name, percent: r.percent }));
    const extra = body.extra_usage?.is_enabled ? { used: body.extra_usage.used_credits, limit: body.extra_usage.monthly_limit, currency: body.extra_usage.currency } : null;
    done({ plan, limits: parseLimits(body), breakdown, extra, error: null, updated: Date.now() });
  } catch (e) {
    done({ error: `Usage unavailable: ${e?.message ?? e}` });
  }
}

// "4h 44m", "3d 19h", "12m".
export function until(iso, now = Date.now()) {
  if (!iso) return "";
  const mins = Math.max(0, Math.round((Date.parse(iso) - now) / 60000));
  const d = Math.floor(mins / 1440), h = Math.floor((mins % 1440) / 60), m = mins % 60;
  return d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : `${m}m`;
}

export function ago(ms, now = Date.now()) {
  const mins = Math.round((now - ms) / 60000);
  return mins < 1 ? "just now" : mins < 60 ? `${mins}m ago` : `${Math.round(mins / 60)}h ago`;
}

export const color = (t, l) => l.severity !== "normal" || l.percent >= 90 ? t.blocked : l.percent >= 70 ? t.working : t.accent;
