// @ts-nocheck
// Renders `edit` tool diffs with full-width tinted backgrounds: full-width tinted
// backgrounds on changed lines, a "+"/"-" gutter, and inverse-highlighted
// word-level changes on single-line edits. Pi's own diff view only colors
// the text, with no background block, so this replaces it entirely.
import { createEditTool, type EditToolDetails, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Minimal LCS-based word diff — avoids depending on the "diff" package,
// which isn't guaranteed resolvable from an extension file.
function diffWords(oldText: string, newText: string): { value: string; added?: boolean; removed?: boolean }[] {
	const split = (s: string) => s.match(/\s+|[^\s]+/g) ?? [];
	const a = split(oldText);
	const b = split(newText);
	const dp: number[][] = Array.from({ length: a.length + 1 }, () => new Array(b.length + 1).fill(0));
	for (let i = a.length - 1; i >= 0; i--) {
		for (let j = b.length - 1; j >= 0; j--) {
			dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
		}
	}
	const parts: { value: string; added?: boolean; removed?: boolean }[] = [];
	let i = 0;
	let j = 0;
	while (i < a.length && j < b.length) {
		if (a[i] === b[j]) {
			parts.push({ value: a[i] });
			i++;
			j++;
		} else if (dp[i + 1][j] >= dp[i][j + 1]) {
			parts.push({ value: a[i], removed: true });
			i++;
		} else {
			parts.push({ value: b[j], added: true });
			j++;
		}
	}
	while (i < a.length) parts.push({ value: a[i++], removed: true });
	while (j < b.length) parts.push({ value: b[j++], added: true });
	return parts;
}

type DiffLine = { kind: "add" | "del" | "ctx" | "hunk"; num: string; text: string };

function parseDiff(diffText: string): DiffLine[] {
	const lines: DiffLine[] = [];
	for (const raw of diffText.split("\n")) {
		if (raw.startsWith("@@")) {
			lines.push({ kind: "hunk", num: "", text: raw });
			continue;
		}
		const m = raw.match(/^([+\-\s])(\s*\d*)\s(.*)$/);
		if (!m) continue;
		const [, prefix, num, text] = m;
		lines.push({ kind: prefix === "+" ? "add" : prefix === "-" ? "del" : "ctx", num: num.trim(), text });
	}
	return lines;
}

// Word-level highlight for a single-line change, mirroring pi's own approach.
function intraLineHighlight(oldText: string, newText: string, theme): { removed: string; added: string } {
	const parts = diffWords(oldText, newText);
	let removed = "";
	let added = "";
	for (const part of parts) {
		if (part.removed) removed += theme.bold(part.value);
		else if (part.added) added += theme.bold(part.value);
		else {
			removed += part.value;
			added += part.value;
		}
	}
	return { removed, added };
}

class DiffViewComponent {
	constructor(
		private path: string,
		private lines: DiffLine[],
		private theme,
	) {}

	invalidate() {}

	render(width: number): string[] {
		const c = (color: string, text: string) => {
			try {
				return this.theme.fg(color, text);
			} catch {
				return text;
			}
		};
		const bg = (role: string, text: string) => {
			try {
				return this.theme.bg(role, text);
			} catch {
				return text;
			}
		};
		const numWidth = Math.max(3, ...this.lines.map((l) => l.num.length));
		const out: string[] = [c("toolTitle", this.theme.bold(this.path))];

		const row = (gutter: string, gutterColor: string, num: string, text: string, bgRole?: string) => {
			const plain = `${gutter} ${num.padStart(numWidth)} │ ${text}`;
			const contentWidth = Math.max(0, width - visibleWidth(plain) + visibleWidth(text));
			const padded = text + " ".repeat(Math.max(0, contentWidth - visibleWidth(text)));
			const line = `${c(gutterColor, gutter)} ${c("dim", num.padStart(numWidth))} ${c("borderMuted", "│")} ${padded}`;
			out.push(bgRole ? bg(bgRole, truncateToWidth(line, width)) : truncateToWidth(line, width));
		};

		let i = 0;
		while (i < this.lines.length) {
			const line = this.lines[i];
			if (line.kind === "hunk") {
				out.push(c("dim", truncateToWidth(line.text, width)));
				i++;
				continue;
			}
			if (line.kind === "ctx") {
				row(" ", "dim", line.num, line.text);
				i++;
				continue;
			}
			// Group consecutive del/add runs to apply intra-line highlighting on 1:1 changes.
			const dels: DiffLine[] = [];
			while (i < this.lines.length && this.lines[i].kind === "del") dels.push(this.lines[i++]);
			const adds: DiffLine[] = [];
			while (i < this.lines.length && this.lines[i].kind === "add") adds.push(this.lines[i++]);

			if (dels.length === 1 && adds.length === 1) {
				const { removed, added } = intraLineHighlight(dels[0].text, adds[0].text, this.theme);
				row("-", "error", dels[0].num, removed, "toolErrorBg");
				row("+", "success", adds[0].num, added, "toolSuccessBg");
			} else {
				for (const d of dels) row("-", "error", d.num, d.text, "toolErrorBg");
				for (const a of adds) row("+", "success", a.num, a.text, "toolSuccessBg");
			}
		}
		return out;
	}
}

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();
	const original = createEditTool(cwd);

	pi.registerTool({
		name: "edit",
		label: "edit",
		description: original.description,
		parameters: original.parameters,
		renderShell: "self",

		async execute(toolCallId, params, signal, onUpdate) {
			return original.execute(toolCallId, params, signal, onUpdate);
		},

		renderCall(args, theme, _context) {
			return { render: () => [theme.fg("toolTitle", theme.bold("edit ")) + theme.fg("accent", args.path)], invalidate() {} };
		},

		renderResult(result, { expanded, isPartial }, theme, context) {
			if (isPartial) return { render: () => [theme.fg("warning", "Editing...")], invalidate() {} };

			const details = result.details as EditToolDetails | undefined;
			const path = context.args?.path ?? "";
			const content = result.content[0];
			if (content?.type === "text" && content.text.startsWith("Error")) {
				return { render: () => [theme.fg("error", content.text.split("\n")[0])], invalidate() {} };
			}
			if (!details?.diff) return { render: () => [theme.fg("success", "Applied")], invalidate() {} };

			const lines = parseDiff(details.diff);
			const adds = lines.filter((l) => l.kind === "add").length;
			const dels = lines.filter((l) => l.kind === "del").length;

			if (!expanded) {
				const stat = `${theme.fg("success", `+${adds}`)}${theme.fg("dim", " / ")}${theme.fg("error", `-${dels}`)}`;
				return { render: () => [theme.fg("accent", path) + "  " + stat], invalidate() {} };
			}

			return new DiffViewComponent(path, lines, theme);
		},
	});
}
