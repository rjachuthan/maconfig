// @ts-nocheck
// Shows one line above the editor with a provider-specific fact that isn't
// already in the footer: Ollama's currently loaded model, or GitHub
// Copilot's premium-request quota (read from the account's own OAuth token,
// same endpoint VS Code and pi itself use to refresh the completions
// token). Nothing is shown when there's nothing real to say — no
// placeholder text for an unconfigured provider or a failed fetch.
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

export default function (pi: ExtensionAPI) {
	let ollamaTimer: ReturnType<typeof setInterval> | undefined;
	let copilotTimer: ReturnType<typeof setInterval> | undefined;

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
	});

	pi.on("session_shutdown", () => {
		clearInterval(ollamaTimer);
		clearInterval(copilotTimer);
	});
}
