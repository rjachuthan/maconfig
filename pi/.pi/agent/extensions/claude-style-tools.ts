// @ts-nocheck
// Restyles the built-in bash/read/write/grep/ls/find tool calls to look like
// Claude Code's chat rendering: a leading "●" bullet, `Tool(args)` header,
// and an "⎿" connector under it for the result, collapsed to one line by
// default and expandable to a short preview. Pi's own default rendering
// uses a boxed/colored shell per tool; this replaces it entirely (edit is
// intentionally left alone — it already has its own diff-view extension).
import {
	createBashTool,
	createFindTool,
	createGrepTool,
	createLsTool,
	createReadTool,
	createWriteTool,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const BULLET = "●";
const CONNECTOR = "⎿";
const MAX_EXPANDED_LINES = 20;

function safeFg(theme, role: string, text: string) {
	try {
		return theme.fg(role, text);
	} catch {
		return text;
	}
}

function header(theme, label: string, argsText: string) {
	const bullet = safeFg(theme, "accent", BULLET);
	const name = theme.bold(safeFg(theme, "toolTitle", label));
	const args = argsText ? safeFg(theme, "dim", "(") + safeFg(theme, "accent", argsText) + safeFg(theme, "dim", ")") : "";
	return `${bullet} ${name}${args}`;
}

function textOf(result): string {
	const c = result?.content?.find((c) => c.type === "text");
	return c?.text ?? "";
}

/** Shared "⎿ ..." result renderer for tools whose result is just text output. */
function renderTextResult(result, { expanded, isPartial }, theme, context, oneLine?: (first: string, count: number) => string) {
	const raw = textOf(result).replace(/\n+$/, "");
	const lines = raw.length ? raw.split("\n") : [];
	const isError = context.isError;
	const connectorColor = isError ? "error" : "borderMuted";
	const textColor = isError ? "error" : "toolOutput";
	const connector = safeFg(theme, connectorColor, CONNECTOR);

	return {
		render(width: number): string[] {
			if (lines.length === 0) {
				const empty = isPartial ? safeFg(theme, "dim", "Running…") : safeFg(theme, "dim", "(no output)");
				return [`  ${connector}  ${empty}`];
			}

			if (!expanded) {
				const summary = oneLine ? oneLine(lines[0], lines.length) : lines[0];
				const more = lines.length > 1 ? safeFg(theme, "dim", `  (+${lines.length - 1} more)`) : "";
				const running = isPartial ? safeFg(theme, "dim", " …") : "";
				return [truncateToWidth(`  ${connector}  ${safeFg(theme, textColor, summary)}${more}${running}`, width)];
			}

			const shown = lines.slice(0, MAX_EXPANDED_LINES);
			const out = shown.map((l, i) => {
				const prefix = i === 0 ? `  ${connector}  ` : "     ";
				return truncateToWidth(prefix + safeFg(theme, textColor, l), width);
			});
			if (lines.length > MAX_EXPANDED_LINES) {
				out.push(`     ${safeFg(theme, "dim", `… +${lines.length - MAX_EXPANDED_LINES} more lines`)}`);
			}
			if (isPartial) out.push(`     ${safeFg(theme, "dim", "Running…")}`);
			return out;
		},
		invalidate() {},
	};
}

function callComponent(theme, label: string, argsText: string) {
	return { render: () => [header(theme, label, argsText)], invalidate() {} };
}

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();

	const bash = createBashTool(cwd);
	pi.registerTool({
		name: "bash",
		label: "bash",
		description: bash.description,
		parameters: bash.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return bash.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			return callComponent(theme, "Bash", args?.command ?? "");
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context);
		},
	});

	const read = createReadTool(cwd);
	pi.registerTool({
		name: "read",
		label: "read",
		description: read.description,
		parameters: read.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return read.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			const range = args?.offset || args?.limit ? `:${args.offset ?? 0}${args.limit ? `,+${args.limit}` : ""}` : "";
			return callComponent(theme, "Read", `${args?.path ?? ""}${range}`);
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context, (_first, count) => `Read ${count} line${count === 1 ? "" : "s"}`);
		},
	});

	const write = createWriteTool(cwd);
	pi.registerTool({
		name: "write",
		label: "write",
		description: write.description,
		parameters: write.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return write.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			return callComponent(theme, "Write", args?.path ?? "");
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context);
		},
	});

	const grep = createGrepTool(cwd);
	pi.registerTool({
		name: "grep",
		label: "grep",
		description: grep.description,
		parameters: grep.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return grep.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			const where = args?.path ? ` in ${args.path}` : "";
			return callComponent(theme, "Grep", `${args?.pattern ?? ""}${where}`);
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context, (_first, count) => `${count} match${count === 1 ? "" : "es"}`);
		},
	});

	const ls = createLsTool(cwd);
	pi.registerTool({
		name: "ls",
		label: "ls",
		description: ls.description,
		parameters: ls.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return ls.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			return callComponent(theme, "List", args?.path ?? ".");
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context, (_first, count) => `${count} entr${count === 1 ? "y" : "ies"}`);
		},
	});

	const find = createFindTool(cwd);
	pi.registerTool({
		name: "find",
		label: "find",
		description: find.description,
		parameters: find.parameters,
		renderShell: "self",
		async execute(toolCallId, params, signal, onUpdate) {
			return find.execute(toolCallId, params, signal, onUpdate);
		},
		renderCall(args, theme) {
			const where = args?.path ? ` in ${args.path}` : "";
			return callComponent(theme, "Find", `${args?.pattern ?? ""}${where}`);
		},
		renderResult(result, options, theme, context) {
			return renderTextResult(result, options, theme, context, (_first, count) => `${count} result${count === 1 ? "" : "s"}`);
		},
	});
}
