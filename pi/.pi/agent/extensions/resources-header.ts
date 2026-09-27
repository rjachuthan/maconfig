// @ts-nocheck
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, extname, join } from "node:path";
import { VERSION, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const AGENT_DIR = join(homedir(), ".pi", "agent");
const ICON_SKILL = ""; // bolt
const ICON_EXT = ""; // puzzle piece
const ICON_PROMPT = "\uf075"; // comment
const ICON_CONTEXT = "\uf15c"; // file
const ICON_THEME = "\uf1fc"; // paint brush

const tilde = (p: string) => (p.startsWith(homedir()) ? `~${p.slice(homedir().length)}` : p);
const isFile = (p: string) => {
	try {
		return statSync(p).isFile();
	} catch {
		return false;
	}
};

// Mirrors pi's context-file discovery: agent dir, then every directory from cwd upwards.
function contextFiles(cwd: string): { name: string; note: string }[] {
	const names = ["AGENTS.override.md", "AGENTS.md", "AGENTS.MD", "CLAUDE.md", "CLAUDE.MD"];
	const found: { name: string; note: string }[] = [];
	const firstIn = (dir: string) => names.map((n) => join(dir, n)).find(isFile);

	const user = firstIn(AGENT_DIR);
	if (user) found.push({ name: basename(user), note: tilde(dirname(user)) + " (user)" });
	for (const f of ["SYSTEM.md", "APPEND_SYSTEM.md"]) {
		for (const dir of [join(cwd, ".pi"), AGENT_DIR]) {
			if (isFile(join(dir, f))) {
				found.push({ name: f, note: tilde(dir) });
				break;
			}
		}
	}
	const dirs: string[] = [];
	for (let d = cwd; ; d = dirname(d)) {
		dirs.push(d);
		if (dirname(d) === d) break;
	}
	for (const dir of dirs.reverse()) {
		const file = firstIn(dir);
		if (file && dir !== AGENT_DIR) found.push({ name: basename(file), note: tilde(dir) + (dir === cwd ? " (project)" : "") });
	}
	return found;
}

// Built-in themes plus custom ones from the agent dir; the active one is marked.
function themes(): { name: string; note: string }[] {
	let active = "dark";
	try {
		active = JSON.parse(readFileSync(join(AGENT_DIR, "settings.json"), "utf8")).theme ?? active;
	} catch {}
	const names = new Map<string, string>([
		["dark", "built-in"],
		["light", "built-in"],
	]);
	try {
		for (const f of readdirSync(join(AGENT_DIR, "themes"))) {
			if (f.endsWith(".json")) names.set(basename(f, ".json"), "custom");
		}
	} catch {}
	if (!names.has(active)) names.set(active, "");
	return [...names].map(([name, kind]) => ({
		name: name === active ? `${name} ●` : name,
		note: [kind, name === active ? "active" : ""].filter(Boolean).join(" · "),
	}));
}

// Extensions without slash commands never show up in pi.getCommands(), so also read
// the extensions directory and the packages listed in settings.json.
function localExtensions(): { name: string; note: string }[] {
	const found: { name: string; note: string }[] = [];
	try {
		for (const f of readdirSync(join(AGENT_DIR, "extensions"))) {
			if (/\.(ts|js|mjs)$/.test(f)) found.push({ name: basename(f, extname(f)), note: "local extension" });
			else if (!f.startsWith(".")) found.push({ name: f, note: "local extension" });
		}
	} catch {}
	try {
		const settings = JSON.parse(readFileSync(join(AGENT_DIR, "settings.json"), "utf8"));
		for (const p of settings.packages ?? []) found.push({ name: String(p).replace(/^npm:/, ""), note: "package" });
	} catch {}
	return found;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setHeader((_tui, theme) => {
			const c = (color: string, text: string) => {
				try {
					return theme.fg(color, text);
				} catch {
					return text;
				}
			};

			return {
				invalidate() {},
				render(width: number): string[] {
					const commands = pi.getCommands();
					const skills = commands
						.filter((cmd) => cmd.source === "skill")
						.map((cmd) => ({ name: cmd.name.replace(/^skill:/, ""), note: cmd.description ?? "" }));

					const extensions = localExtensions();
					for (const cmd of commands.filter((x) => x.source === "extension")) {
						const name = basename(cmd.sourceInfo?.path ?? "", extname(cmd.sourceInfo?.path ?? ""));
						if (name && !extensions.some((e) => e.name === name || cmd.sourceInfo.path.includes(e.name))) {
							extensions.push({ name, note: "extension" });
						}
					}

					const prompts = commands
						.filter((cmd) => cmd.source === "prompt")
						.map((cmd) => ({ name: `/${cmd.name}`, note: cmd.description ?? "" }));

					const row = (icon: string, color: string, name: string, note: string) => {
						const head = `   ${c(color, icon)} ${c("text", name)}`;
						const plain = `   ${icon} ${name}`;
						const room = width - plain.length - 3;
						const tail = note && room > 8 ? `  ${c("dim", truncateToWidth(note, room, "…"))}` : "";
						return truncateToWidth(head + tail, width);
					};
					const section = (title: string, count: number) =>
						` ${c("accent", title)} ${c("dim", `(${count})`)}`;

					const lines = ["", ` ${c("accent", "π")} ${c("text", "pi")} ${c("dim", `v${VERSION}`)}`, ""];

					lines.push(section("Skills", skills.length));
					for (const s of skills) lines.push(row(ICON_SKILL, "warning", s.name, s.note));
					if (!skills.length) lines.push(`   ${c("dim", "none loaded")}`);

					lines.push("", section("Extensions", extensions.length));
					for (const e of extensions) lines.push(row(ICON_EXT, "success", e.name, e.note));
					if (!extensions.length) lines.push(`   ${c("dim", "none loaded")}`);

					const extra: [string, string, string, { name: string; note: string }[]][] = [
						["Prompts", ICON_PROMPT, "accent", prompts],
						["Context", ICON_CONTEXT, "muted", contextFiles(ctx.cwd)],
						["Themes", ICON_THEME, "error", themes()],
					];
					for (const [title, icon, color, items] of extra) {
						if (!items.length) continue; // hide empty sections
						lines.push("", section(title, items.length));
						for (const it of items) lines.push(row(icon, color, it.name, it.note));
					}

					lines.push("");
					return lines;
				},
			};
		});
	});
}
