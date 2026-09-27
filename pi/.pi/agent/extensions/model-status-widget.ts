// @ts-nocheck
// Shows one line above the editor with a provider-specific fact that isn't
// already in the footer: Ollama's currently loaded model, GitHub
// Copilot's premium-request quota (read from the account's own OAuth token,
// same endpoint VS Code and pi itself use to refresh the completions
// token), or OpenRouter's remaining account credit (read from the stored
// api_key credential, same endpoint the OpenRouter dashboard uses).
// Nothing is shown when there's nothing real to say — no placeholder text
// for an unconfigured provider or a failed fetch.
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const fmtK = (n: number) => (n >= 1000 ? `${Math.round(n / 1000)}k` : `${n}`);

// --- Ollama: what's currently loaded locally ---
let ollamaStatus: { text: string; ok: boolean } | undefined;
async function pollOllama(onDone?: () => void) {
	try {
		const res = await fetch("http://127.0.0.1:11434/api/ps", { signal: AbortSignal.timeout(1500) });
		const data = await res.json();
		const m = data?.models?.[0];
		if (!m) {
			ollamaStatus = { text: "idle, no model loaded", ok: true };
			return;
		}
		const vram = m.size_vram ? `${(m.size_vram / 1e9).toFixed(1)}GB VRAM` : "";
		const quant = m.details?.quantization_level ?? "";
		const until = m.expires_at ? new Date(m.expires_at) : undefined;
		const mins = until ? Math.max(0, Math.round((until.getTime() - Date.now()) / 60000)) : undefined;
		const bits = [m.name, quant, vram, mins !== undefined ? `unloads in ${mins}m` : ""].filter(Boolean);
		ollamaStatus = { text: bits.join(" · "), ok: true };
	} catch {
		ollamaStatus = undefined; // Ollama not running — say nothing rather than "unavailable"
	} finally {
		onDone?.();
	}
}

// --- GitHub Copilot: premium-request quota for this account ---
let copilotQuota: { text: string; severity: "success" | "warning" | "error" } | undefined;
let copilotQuotaError: string | undefined; // for /copilot-quota to explain a blank line
async function pollCopilotQuota(onDone?: () => void) {
	copilotQuotaError = undefined;
	try {
		const authPath = join(homedir(), ".pi", "agent", "auth.json");
		const auth = JSON.parse(readFileSync(authPath, "utf8"));
		const token = auth?.["github-copilot"]?.refresh; // the actual GitHub OAuth token, not the short-lived completions token
		if (!token) {
			copilotQuota = undefined;
			copilotQuotaError = "no github-copilot.refresh token in auth.json";
			return;
		}
		const res = await fetch("https://api.github.com/copilot_internal/v2/token", {
			headers: {
				Authorization: `token ${token}`,
				"User-Agent": "GitHubCopilotChat/0.35.0",
				"Editor-Version": "vscode/1.107.0",
				"Editor-Plugin-Version": "copilot-chat/0.35.0",
				Accept: "application/json",
			},
			signal: AbortSignal.timeout(5000),
		});
		if (!res.ok) {
			copilotQuota = undefined;
			copilotQuotaError = `HTTP ${res.status} from copilot_internal/v2/token`;
			return;
		}
		const data = await res.json();
		const q = data?.quota_snapshots?.premium_interactions;
		if (!q) {
			copilotQuota = undefined;
			copilotQuotaError = "response had no quota_snapshots.premium_interactions field";
		} else if (q.unlimited) {
			copilotQuota = { text: "premium requests: unlimited", severity: "success" };
		} else {
			const pct = q.percent_remaining ?? 0;
			const reset = data.quota_reset_date ? `, resets ${data.quota_reset_date}` : "";
			copilotQuota = {
				text: `premium requests: ${Math.round(q.remaining)} / ${q.entitlement} left (${pct.toFixed(0)}%)${reset}`,
				severity: pct >= 50 ? "success" : pct >= 20 ? "warning" : "error",
			};
		}
	} catch (err) {
		copilotQuota = undefined;
		copilotQuotaError = err instanceof Error ? err.message : String(err);
	} finally {
		onDone?.();
	}
}

// --- OpenRouter: remaining account credit ---
const BAR_WIDTH = 10;
// Braille dot-fill per cell, 0..8 dots lit — same "growing block" sequence used by
// braille progress bars elsewhere (gauge, cli-spinners): bottom row first, then the
// left column, then the right column, so it fills like a rising bar graph.
const BRAILLE_LEVELS = ["⠀", "⡀", "⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"];
const BRAILLE_TRACK = "⠂"; // sparse single dot for the unfilled track

// Green -> yellow -> red gradient, interpolated per cell across the bar's width so
// filled dots shade smoothly from "healthy" to "critical" as the bar empties.
type Rgb = [number, number, number];
const GRADIENT_STOPS: [number, Rgb][] = [
	[0, [34, 197, 94]], // green
	[0.5, [234, 179, 8]], // yellow
	[1, [239, 68, 68]], // red
];
function lerp(a: number, b: number, t: number) {
	return a + (b - a) * t;
}
function gradientColor(t: number): Rgb {
	t = Math.max(0, Math.min(1, t));
	for (let i = 0; i < GRADIENT_STOPS.length - 1; i++) {
		const [t0, c0] = GRADIENT_STOPS[i];
		const [t1, c1] = GRADIENT_STOPS[i + 1];
		if (t <= t1) {
			const localT = t1 === t0 ? 0 : (t - t0) / (t1 - t0);
			return [Math.round(lerp(c0[0], c1[0], localT)), Math.round(lerp(c0[1], c1[1], localT)), Math.round(lerp(c0[2], c1[2], localT))];
		}
	}
	return GRADIENT_STOPS[GRADIENT_STOPS.length - 1][1];
}
// Standard 6x6x6 cube + grayscale ramp mapping, for terminals without truecolor.
function rgbToAnsi256([r, g, b]: Rgb): number {
	if (r === g && g === b) {
		if (r < 8) return 16;
		if (r > 248) return 231;
		return Math.round(((r - 8) / 247) * 24) + 232;
	}
	return 16 + 36 * Math.round((r / 255) * 5) + 6 * Math.round((g / 255) * 5) + Math.round((b / 255) * 5);
}
function fgRgb(rgb: Rgb, text: string, truecolor: boolean): string {
	const code = truecolor ? `38;2;${rgb[0]};${rgb[1]};${rgb[2]}` : `38;5;${rgbToAnsi256(rgb)}`;
	return `\u001b[${code}m${text}\u001b[39m`;
}
// Colored, gradient braille bar for the widget line.
function renderGradientBar(pct: number, truecolor: boolean): string {
	const totalDots = BAR_WIDTH * 8;
	const filledDots = Math.max(0, Math.min(totalDots, Math.round((pct / 100) * totalDots)));
	let out = "";
	for (let i = 0; i < BAR_WIDTH; i++) {
		const cellDots = Math.max(0, Math.min(8, filledDots - i * 8));
		if (cellDots === 0) {
			out += `\u001b[2m${BRAILLE_TRACK}\u001b[22m`; // dim
		} else {
			const t = BAR_WIDTH > 1 ? i / (BAR_WIDTH - 1) : 0;
			out += fgRgb(gradientColor(t), BRAILLE_LEVELS[cellDots], truecolor);
		}
	}
	return out;
}
type OpenrouterCredit = { remaining: number; total: number; pct: number; severity: "success" | "warning" | "error" };
let openrouterCredit: OpenrouterCredit | undefined;
let openrouterCreditError: string | undefined; // for /openrouter-credits to explain a blank line
// Plain-text summary (no ANSI) for /openrouter-credits, which goes through ui.notify.
function fmtOpenrouterCredit(c: OpenrouterCredit): string {
	const filled = Math.max(0, Math.min(BAR_WIDTH, Math.round((c.pct / 100) * BAR_WIDTH)));
	const bar = "█".repeat(filled) + "░".repeat(BAR_WIDTH - filled);
	return `${bar} $${c.remaining.toFixed(2)} / $${c.total.toFixed(2)} (${c.pct.toFixed(0)}%)`;
}
async function pollOpenrouterCredit(onDone?: () => void) {
	openrouterCreditError = undefined;
	try {
		const authPath = join(homedir(), ".pi", "agent", "auth.json");
		const auth = JSON.parse(readFileSync(authPath, "utf8"));
		const key = auth?.openrouter?.key;
		if (!key) {
			openrouterCredit = undefined;
			openrouterCreditError = "no openrouter.key in auth.json";
			return;
		}
		const res = await fetch("https://openrouter.ai/api/v1/credits", {
			headers: { Authorization: `Bearer ${key}` },
			signal: AbortSignal.timeout(5000),
		});
		if (!res.ok) {
			openrouterCredit = undefined;
			openrouterCreditError = `HTTP ${res.status} from api/v1/credits`;
			return;
		}
		const data = await res.json();
		const total = data?.data?.total_credits;
		const used = data?.data?.total_usage;
		if (total === undefined || used === undefined) {
			openrouterCredit = undefined;
			openrouterCreditError = "response had no data.total_credits/total_usage field";
		} else {
			const remaining = total - used;
			const pct = total > 0 ? (remaining / total) * 100 : 0;
			openrouterCredit = {
				remaining,
				total,
				pct,
				severity: pct >= 50 ? "success" : pct >= 20 ? "warning" : "error",
			};
		}
	} catch (err) {
		openrouterCredit = undefined;
		openrouterCreditError = err instanceof Error ? err.message : String(err);
	} finally {
		onDone?.();
	}
}

export default function (pi: ExtensionAPI) {
	let ollamaTimer: ReturnType<typeof setInterval> | undefined;
	let copilotTimer: ReturnType<typeof setInterval> | undefined;
	let openrouterTimer: ReturnType<typeof setInterval> | undefined;

	pi.on("session_start", (_event, ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;

		let activeTui;
		const bump = () => activeTui?.requestRender();
		for (const evt of ["message_update", "model_select", "thinking_level_select"] as const) {
			pi.on(evt, bump);
		}

		// Each poll updates module-level state asynchronously; without calling
		// bump() afterwards, pi never repaints the widget until something else
		// (like a chat message) happens to trigger a render.
		pollOllama(bump);
		ollamaTimer = setInterval(() => pollOllama(bump), 15000);
		pollCopilotQuota(bump);
		copilotTimer = setInterval(() => pollCopilotQuota(bump), 5 * 60 * 1000);
		pollOpenrouterCredit(bump);
		openrouterTimer = setInterval(() => pollOpenrouterCredit(bump), 5 * 60 * 1000);

		ctx.ui.setWidget(
			"model-status",
			(tui, theme) => {
				activeTui = tui;
				const c = (color: string, text: string) => {
					try {
						return theme.fg(color, text);
					} catch {
						return text;
					}
				};

				return {
					dispose() {
						clearInterval(ollamaTimer);
						clearInterval(copilotTimer);
						clearInterval(openrouterTimer);
					},
					invalidate() {},
					render(width: number): string[] {
						const provider = ctx.model?.provider ?? "";
						let icon: string;
						let color: string;
						let text: string | undefined;

						if (/ollama/i.test(provider)) {
							icon = "\u{f06a9}";
							color = ollamaStatus?.ok ? "success" : "muted";
							text = ollamaStatus?.text;
						} else if (/copilot/i.test(provider)) {
							icon = "";
							color = copilotQuota?.severity ?? "muted";
							text = copilotQuota?.text;
						} else if (/openrouter/i.test(provider)) {
							if (!openrouterCredit) return []; // fetch hasn't succeeded (yet, or ever) — say nothing rather than guess
							const { remaining, total, pct, severity } = openrouterCredit;
							const truecolor = theme.getColorMode() === "truecolor";
							const bar = renderGradientBar(pct, truecolor);
							const line = `   ${c(severity, "")}  ${bar} ${c("dim", `$${remaining.toFixed(2)} / $${total.toFixed(2)} (${pct.toFixed(0)}%)`)}`;
							return ["", truncateToWidth(line, width)];
						} else {
							return []; // no provider-specific fact for this one — stay out of the way
						}

						if (!text) return []; // fetch hasn't succeeded (yet, or ever) — say nothing rather than guess

						const line = `   ${c(color, icon)}  ${c("dim", text)}`;
						return ["", truncateToWidth(line, width)];
					},
				};
			},
			{ placement: "aboveEditor" },
		);

		pi.registerCommand("models", {
			description: "List configured models grouped by provider, with context window sizes",
			handler: async (_args, cmdCtx) => {
				const byProvider = new Map<string, { id: string; ctx?: number }[]>();
				for (const { model: m } of cmdCtx.scopedModels) {
					const list = byProvider.get(m.provider) ?? [];
					list.push({ id: m.id, ctx: m.contextWindow });
					byProvider.set(m.provider, list);
				}
				const lines: string[] = [];
				for (const [provider, models] of [...byProvider].sort()) {
					lines.push(`${provider} (${models.length})`);
					for (const m of models.sort((a, b) => a.id.localeCompare(b.id))) {
						lines.push(`  ${m.id.padEnd(28)} ${m.ctx ? fmtK(m.ctx) : "?"}`);
					}
				}
				cmdCtx.ui.notify(lines.join("\n") || "No models configured", "info");
			},
		});

		pi.registerCommand("copilot-quota", {
			description: "Refresh and show the raw Copilot quota status (useful if the widget line stays blank)",
			handler: async (_args, cmdCtx) => {
				await pollCopilotQuota(bump);
				cmdCtx.ui.notify(
					copilotQuota ? copilotQuota.text : `No quota to show: ${copilotQuotaError ?? "unknown reason"}`,
					copilotQuota ? "info" : "warning",
				);
			},
		});

		pi.registerCommand("openrouter-credits", {
			description: "Refresh and show the raw OpenRouter account credit balance (useful if the widget line stays blank)",
			handler: async (_args, cmdCtx) => {
				await pollOpenrouterCredit(bump);
				cmdCtx.ui.notify(
					openrouterCredit ? fmtOpenrouterCredit(openrouterCredit) : `No credit info to show: ${openrouterCreditError ?? "unknown reason"}`,
					openrouterCredit ? "info" : "warning",
				);
			},
		});
	});

	pi.on("session_shutdown", () => {
		clearInterval(ollamaTimer);
		clearInterval(copilotTimer);
		clearInterval(openrouterTimer);
	});
}
