// @ts-nocheck
import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const LEFT_GAP = 1; // dashes between the top-left corner and the label

// Nerd Font glyphs (checked against the installed 0xProto Nerd Font) and brand colours.
const PROVIDERS: [RegExp, string, string, string][] = [
	[/copilot/, "\uec1e", "", "8957e5"],
	[/codex/, "\uec81", "", "10a37f"],
	[/azure/, "\u{f0805}", "", "0078d4"],
	[/openai/, "\uec81", "", "10a37f"],
	[/anthropic|claude/, "\uec82", "", "d97757"],
	[/google|gemini|vertex/, "\uf1a0", "", "4285f4"],
	[/bedrock|aws|amazon/, "\u{f0e0f}", "", "ff9900"],
	[/github/, "\uf09b", "", "c9d1d9"],
	[/ollama/, "\u{f06a9}", "", "e6e6e6"],
];
const providerLogo = (provider = "") => {
	const hit = PROVIDERS.find(([re]) => re.test(provider.toLowerCase()));
	const [glyph, hex] = hit ? [hit[1], hit[3]] : ["\uee0d", "9aa5b1"];
	const [r, g, b] = [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16));
	return `\x1b[38;2;${r};${g};${b}m${glyph}\x1b[39m`;
};

let working = false;
let frame = 0;
let timer: ReturnType<typeof setInterval> | undefined;
let activeTui;
let uiCtx;

// Draws the input box as a rounded rectangle with left and right borders,
// and shows the "Working" indicator inside the top border.
class RoundedEditor extends CustomEditor {
	constructor(tui, editorTheme, keybindings) {
		super(tui, editorTheme, keybindings, { paddingX: 1 });
		activeTui = tui;
	}

	render(width: number): string[] {
		if (width < 4) return super.render(width);
		const inner = width - 2;
		const lines = super.render(inner);
		if (lines.length < 3) return lines;

		const b = (t: string) => this.borderColor(t);
		const bottom = Math.min(lines.length - 1, (this.renderedVisibleLineCount ?? lines.length - 3) + 1);
		const out: string[] = [];

		lines.forEach((line, i) => {
			if (i === 0) out.push(b("╭") + this.topLine(line, inner, b) + b("╮"));
			else if (i < bottom) out.push(b("│") + line + b("│"));
			else if (i === bottom) out.push(b("╰") + line + b("╯"));
			else out.push(" " + line + " "); // autocomplete rows below the box
		});
		return out;
	}

	paint(text: string): string {
		try {
			return uiCtx.ui.theme.fg("accent", text);
		} catch {
			return text;
		}
	}

	topLine(line: string, inner: number, b: (t: string) => string): string {
		if (!working) return line;
		const label = ` ${FRAMES[frame]} Working `;
		const w = visibleWidth(label);
		if (w + LEFT_GAP + 2 > inner) return line;
		return b("─".repeat(LEFT_GAP)) + this.paint(label) + b("─".repeat(inner - w - LEFT_GAP));
	}
}

export default function (pi: ExtensionAPI) {
	const stop = () => {
		if (timer) clearInterval(timer);
		timer = undefined;
	};

	pi.on("agent_start", () => {
		working = true;
		stop();
		timer = setInterval(() => {
			frame = (frame + 1) % FRAMES.length;
			activeTui?.requestRender();
		}, 80);
		activeTui?.requestRender();
	});

	pi.on("agent_settled", () => {
		working = false;
		stop();
		activeTui?.requestRender();
	});

	pi.on("session_shutdown", () => {
		stop();
		activeTui = undefined;
	});

	pi.on("session_start", (_event, ctx) => {
		uiCtx = ctx;
		ctx.ui.setWorkingVisible(false);
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			const c = (color: string, text: string) => {
				try {
					return theme.fg(color, text);
				} catch {
					return text;
				}
			};
			const sep = c("dim", "  │  ");

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const usage = ctx.getContextUsage();
					const pct = usage?.percent ?? null;
					const pctColor = pct === null ? "muted" : pct >= 85 ? "error" : pct >= 60 ? "warning" : "success";
					const filled = pct === null ? 0 : Math.min(10, Math.round(pct / 10));
					const bar = "▰".repeat(filled) + "▱".repeat(10 - filled);
					const window = usage?.contextWindow ?? ctx.model?.contextWindow;
					const ctxText = pct === null ? "ctx —" : `${Math.round(pct)}%${window ? ` of ${Math.round(window / 1000)}k` : ""}`;

					const left =
						" " +
						providerLogo(ctx.model?.provider) +
						" " +
						c("muted", `${ctx.model?.provider ?? "no provider"} / `) +
						c("accent", ctx.model?.id ?? "no model") +
						sep +
						c("muted", `✦ ${pi.getThinkingLevel()}`) +
						sep +
						c(pctColor, bar) +
						" " +
						c("muted", ctxText);

					const home = process.env.HOME;
					const cwd = home && ctx.cwd.startsWith(home) ? `~${ctx.cwd.slice(home.length)}` : ctx.cwd;
					const branch = footerData.getGitBranch();
					const right = c("warning", "") + " " + c("muted", cwd) + (branch ? sep + c("accent", `⎇ ${branch}`) : "") + " ";

					const gap = width - visibleWidth(left) - visibleWidth(right);
					if (gap < 1) return [truncateToWidth(left, width)];
					return [left + " ".repeat(gap) + right];
				},
			};
		});
		ctx.ui.setEditorComponent((tui, editorTheme, keybindings) => new RoundedEditor(tui, editorTheme, keybindings));
	});
}
