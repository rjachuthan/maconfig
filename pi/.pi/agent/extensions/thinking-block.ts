// @ts-nocheck
// Customizes pi's thinking block: collapses it by default and shows an
// animated brain icon + short status in its place, instead of the plain
// "Pondering..." label. Expand/collapse still works via Ctrl+T.
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const BRAIN = ""; // cod-lightbulb_sparkle (Nerd Font)
const FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

export default function (pi: ExtensionAPI) {
	let frame = 0;
	let timer: ReturnType<typeof setInterval> | undefined;
	let ctxRef: ExtensionContext | undefined;

	const label = (spinning: boolean) => `${BRAIN} ${spinning ? FRAMES[frame] : "·"} thinking`;

	const stop = () => {
		if (timer) clearInterval(timer);
		timer = undefined;
	};

	pi.on("session_start", (_event, ctx) => {
		ctxRef = ctx;
		ctx.ui.setHiddenThinkingLabel(label(false));
		if (!ctx.settings?.hideThinkingBlock) {
			// Minimize thinking blocks by default; Ctrl+T still expands them.
			ctx.ui.notify("Thinking blocks collapsed by default (Ctrl+T to expand)", "info");
		}
	});

	// A single agent run can contain several thinking blocks (thinking → tool
	// call → thinking → ... → final answer). agent_start/agent_settled only
	// bracket the whole run, so the spinner kept animating through tool calls
	// and past the end of each individual block. Drive it from the
	// thinking_start/thinking_end deltas inside message_update instead, which
	// fire once per block.
	pi.on("message_update", (event) => {
		const kind = event.assistantMessageEvent?.type;
		if (kind === "thinking_start") {
			stop();
			timer = setInterval(() => {
				frame = (frame + 1) % FRAMES.length;
				ctxRef?.ui.setHiddenThinkingLabel(label(true));
			}, 80);
		} else if (kind === "thinking_end") {
			stop();
			ctxRef?.ui.setHiddenThinkingLabel(label(false));
		}
	});

	// Safety net: make sure the spinner never survives past the run itself
	// (e.g. if a block is aborted mid-stream).
	pi.on("agent_settled", () => {
		stop();
		ctxRef?.ui.setHiddenThinkingLabel(label(false));
	});

	pi.on("session_shutdown", () => {
		stop();
		ctxRef = undefined;
	});

	pi.registerCommand("brain-label", {
		description: "Preview the custom hidden-thinking label text",
		handler: async (_args, ctx) => {
			ctx.ui.notify(`Label: ${label(false)}`, "info");
		},
	});
}
