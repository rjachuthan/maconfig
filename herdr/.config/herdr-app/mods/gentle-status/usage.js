// Plan usage for Claude, Codex and GitHub Copilot, each read the way its own
// tool reads it, signed with the login that tool keeps. Tokens are only read,
// never refreshed: refreshing one here would rotate it under the tool and sign
// it out. An expired one shows as an error until the tool refreshes it.
// Each provider's result goes to shared(<id>.usage) (no token in it), so the
// bar and the popup read the same thing. Every limit has one shape:
// { kind, label, name, percent, severity, resets (ISO), detail? }, and below them
// one titled list of facts: section { title, rows: [{ name, value }] }.
import { exec, readTextFile, home, shared, setShared, window } from "herdr";

const cap = s => (s ? s[0].toUpperCase() + s.slice(1) : null);
// 5500 -> "5,500", the same in every locale.
const num = n => String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
const iso = secs => (secs ? new Date(secs * 1000).toISOString() : null);

// ── Claude: Claude Code's /usage endpoint, its login in the macOS Keychain,
// else ~/.claude/.credentials.json (Windows, Linux).
async function claudeLogin() {
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
export function claudePlan(tier, type) {
  const m = /max_(\d+x)/.exec(tier ?? "");
  return m ? `Max ${m[1]}` : cap(type);
}

// The endpoint's `limits`, else its older five_hour / seven_day fields.
export function claudeLimits(body) {
  const short = { session: "5h", weekly_all: "wk" };
  if (Array.isArray(body?.limits) && body.limits.length) {
    return body.limits.map(l => {
      const scope = l.scope?.model?.display_name ?? l.scope?.surface?.display_name;
      return {
        kind: l.kind,
        label: scope ?? short[l.kind] ?? l.kind,
        name: l.kind === "session" ? "Current session" : l.kind === "weekly_all" ? "Weekly · all models" : `Weekly · ${scope ?? l.kind}`,
        percent: Math.round(l.percent ?? 0),
        severity: l.severity ?? "normal",
        resets: l.resets_at ?? null,
      };
    });
  }
  return [["five_hour", "session", "Current session"], ["seven_day", "weekly_all", "Weekly · all models"]]
    .filter(([k]) => body?.[k])
    .map(([k, kind, name]) => ({ kind, label: short[kind], name, percent: Math.round(body[k].utilization ?? 0), severity: "normal", resets: body[k].resets_at ?? null }));
}

async function claude() {
  const cred = await claudeLogin();
  if (!cred?.accessToken) return { error: "Not signed in to Claude Code" };
  const plan = claudePlan(cred.rateLimitTier, cred.subscriptionType);
  const expired = { plan, error: "Login expired: run claude to refresh it" };
  if (cred.expiresAt && cred.expiresAt < Date.now()) return expired;
  const res = await fetch("https://api.anthropic.com/api/oauth/usage", {
    headers: { Authorization: `Bearer ${cred.accessToken}`, "anthropic-beta": "oauth-2025-04-20", "Content-Type": "application/json" },
  });
  if (res.status === 401) return expired;
  if (!res.ok) return { plan, error: failed(res.status) };
  const body = await res.json();
  return {
    plan,
    limits: claudeLimits(body),
    section: {
      title: "This week by surface",
      rows: [
        ...(body.seven_day_breakdown?.rows ?? []).filter(r => r.percent > 0).map(r => ({ name: r.display_name, value: `${r.percent}%` })),
        ...(body.extra_usage?.is_enabled ? [{ name: "Extra usage", value: `${body.extra_usage.used_credits} / ${body.extra_usage.monthly_limit} ${body.extra_usage.currency}` }] : []),
      ],
    },
  };
}

// ── Codex: the ChatGPT usage endpoint Codex's /status reads, its login in
// ~/.codex/auth.json ($CODEX_HOME is not followed).
// A window's length names it: 5h -> "5-hour", 7d -> "Weekly", 30d -> "30-day".
function windowName(secs) {
  const h = Math.round((secs ?? 0) / 3600);
  return h === 168 ? "Weekly" : h % 24 === 0 && h ? `${h / 24}-day` : h ? `${h}-hour` : "Usage";
}

export function codexLimits(body) {
  const out = [];
  const add = (w, prefix, kind) => w && out.push({
    kind, label: windowName(w.limit_window_seconds), name: prefix ? `${prefix} · ${windowName(w.limit_window_seconds)}` : `${windowName(w.limit_window_seconds)} limit`,
    percent: Math.round(w.used_percent ?? 0), severity: body?.rate_limit?.limit_reached ? "reached" : "normal",
    resets: iso(w.reset_at) ?? (w.reset_after_seconds ? new Date(Date.now() + w.reset_after_seconds * 1000).toISOString() : null),
  });
  add(body?.rate_limit?.primary_window, null, "primary");
  add(body?.rate_limit?.secondary_window, null, "secondary");
  add(body?.code_review_rate_limit?.primary_window, "Code review", "review");
  for (const extra of Array.isArray(body?.additional_rate_limits) ? body.additional_rate_limits : []) {
    const r = extra.rate_limit ?? extra;
    add(r?.primary_window, extra.limit_name ?? extra.name ?? "Other", "additional");
  }
  return out;
}

async function codex() {
  const text = await readTextFile(`${home()}/.codex/auth.json`);
  const tokens = text ? JSON.parse(text).tokens : null;
  if (!tokens?.access_token) return { error: "Not signed in to Codex with ChatGPT" };
  const res = await fetch("https://chatgpt.com/backend-api/wham/usage", {
    headers: { Authorization: `Bearer ${tokens.access_token}`, "ChatGPT-Account-Id": tokens.account_id ?? "", "User-Agent": "codex-cli" },
  });
  if (res.status === 401 || res.status === 403) return { error: "Login expired: run codex to refresh it" };
  if (!res.ok) return { error: failed(res.status) };
  const body = await res.json();
  const c = body.credits, plan = cap(body.plan_type);
  const w = body.rate_limit?.primary_window;
  return {
    plan,
    limits: codexLimits(body),
    section: {
      title: "Account",
      rows: [
        { name: "Plan", value: plan ? `ChatGPT ${plan}` : "ChatGPT" },
        ...(w?.limit_window_seconds ? [{ name: "Limit window", value: w.limit_window_seconds >= 86400 ? `${Math.round(w.limit_window_seconds / 86400)} days` : `${Math.round(w.limit_window_seconds / 3600)} hours` }] : []),
        { name: "Status", value: body.rate_limit?.limit_reached ? "Limit reached" : body.rate_limit?.allowed === false ? "Paused" : "Available" },
        { name: "Credits", value: c?.unlimited ? "Unlimited" : c?.has_credits && c.balance != null ? num(c.balance) : "None" },
      ],
    },
  };
}

// ── GitHub Copilot: the quota Copilot's own editors read, once for every account
// gh is signed in to (`gh auth token --user`), so a personal and a work seat both
// show. Business and Enterprise seats included.
export function copilotLimits(body) {
  const q = body?.quota_snapshots ?? {};
  const resets = body?.quota_reset_date_utc ?? (body?.quota_reset_date ? `${body.quota_reset_date}T00:00:00Z` : null);
  const names = { premium_interactions: "Premium requests", chat: "Chat", completions: "Completions" };
  return Object.entries(q).filter(([, s]) => s && !s.unlimited).map(([id, s]) => ({
    kind: id, label: names[id] ?? id, name: names[id] ?? id,
    percent: Math.round(100 - (s.percent_remaining ?? 100)),
    severity: s.remaining <= 0 && !s.overage_permitted ? "reached" : "normal",
    resets,
    detail: s.entitlement ? `${num(s.entitlement - s.remaining)} / ${num(s.entitlement)}` : null,
  }));
}

// Every github.com login gh keeps, the active one first.
async function ghAccounts() {
  const r = await exec("gh", ["auth", "status", "--json", "hosts"], { timeout: 10000 });
  const list = (r.code === 0 ? JSON.parse(r.stdout).hosts?.["github.com"] : null) ?? [];
  return list.filter(a => a.login).sort((a, b) => b.active - a.active).map(a => a.login);
}

async function copilotAccount(login) {
  const r = await exec("gh", ["auth", "token", "--user", login], { timeout: 10000 });
  const token = r.code === 0 ? r.stdout.trim() : null;
  if (!token) return { error: `gh has no token for ${login}: run gh auth login` };
  const res = await fetch("https://api.github.com/copilot_internal/user", {
    headers: { Authorization: `token ${token}`, Accept: "application/json", "User-Agent": "GitHubCopilotChat/0.26.7", "Editor-Version": "vscode/1.99.0", "X-GitHub-Api-Version": "2025-04-01" },
  });
  if (res.status === 401) return { error: `gh login for ${login} expired: run gh auth login` };
  if (res.status === 404) return { error: `No Copilot seat on ${login}` };
  if (!res.ok) return { error: failed(res.status) };
  const body = await res.json();
  const q = body.quota_snapshots ?? {}, premium = q.premium_interactions;
  return {
    plan: cap(body.copilot_plan),
    limits: copilotLimits(body),
    section: {
      title: "Seat",
      rows: [
        ...(body.organization_login_list?.length ? [{ name: "Organization", value: body.organization_login_list.join(", ") }] : []),
        ...Object.entries(q).filter(([, s]) => s?.unlimited).map(([id]) => ({ name: { chat: "Chat", completions: "Completions" }[id] ?? id, value: "Unlimited" })),
        ...(premium ? [{ name: "Overage", value: premium.overage_count ? `${num(premium.overage_count)} requests` : premium.overage_permitted ? "Allowed" : "Not allowed" }] : []),
      ],
    },
  };
}

// One result per account in `accounts` ({ login, ...result }); the top level is
// the first account with a seat, so anything reading only it still works.
async function copilot() {
  let logins;
  try { logins = await ghAccounts(); } catch { return { error: "gh isn't installed: Copilot is read with gh's login" }; }
  if (!logins.length) return { error: "Not signed in to gh: run gh auth login" };
  const accounts = await Promise.all(logins.map(async login => {
    try { return { login, ...(await copilotAccount(login)) }; }
    catch (e) { return { login, error: `Usage unavailable: ${e?.message ?? e}` }; }
  }));
  const main = accounts.find(a => !a.error) ?? accounts[0];
  const { login: _, ...top } = main;
  return { ...top, accounts };
}

const failed = status => (status === 429 ? "Rate limited, trying again later" : `Usage request failed (${status})`);

// The popup's tabs, in order. `key`: where each one's result is kept; `icon`: the
// company's mark (Lobe Icons, @lobehub/icons-static-svg 1.101.0); `colored`: drawn
// in its own colors; `tint`: its bars.
export const PROVIDERS = [
  { id: "claude", name: "Claude", icon: "claude", colored: true, tint: "#d97757", key: "claude.usage", read: claude },
  { id: "codex", name: "Codex", icon: "codex", colored: true, tint: "#7b8cff", key: "codex.usage", read: codex },
  { id: "copilot", name: "Copilot", icon: "copilot", tint: "#a371f7", key: "copilot.usage", read: copilot },
];
export const KEY = PROVIDERS[0].key;

// Automatic refreshes skip a provider checked in the last 45s (reloads, bursts of
// notifications: the endpoints rate-limit); the popup's refresh button forces one.
export async function refresh(id = "claude", { force = false } = {}) {
  const p = PROVIDERS.find(x => x.id === id);
  // loading is saved with the rest: one left behind by a reload mid-request expires.
  const prev = shared(p.key) ?? {};
  if (prev.loading && Date.now() - prev.loading < 30000) return;
  if (!force && Date.now() - (prev.checked ?? 0) < 45000) return;
  setShared(p.key, { ...prev, loading: Date.now() });
  let next;
  try {
    const got = await p.read();
    // A failed read keeps the last numbers, marked by the error.
    next = got.error ? { ...prev, ...got } : { section: null, ...got, error: null, updated: Date.now() };
  } catch (e) {
    next = { ...prev, error: `Usage unavailable: ${e?.message ?? e}` };
  }
  setShared(p.key, { ...next, loading: false, checked: Date.now() });
}

export const refreshAll = opts => Promise.all(PROVIDERS.map(p => refresh(p.id, opts)));

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

// A limit's bar: the provider's own color, amber from 70%, red from 90% or once reached.
export const color = (t, l, tint) => l.severity !== "normal" || l.percent >= 90 ? t.blocked : l.percent >= 70 ? t.working : tint ?? t.accent;
