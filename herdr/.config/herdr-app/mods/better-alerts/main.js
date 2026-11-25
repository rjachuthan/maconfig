// Adapted from munza/herdr-mods better-alerts (1.2.0); changes: macOS only (no Linux path),
// no settings plumbing, and it posts only while Herdr isn't the active window: in front,
// Herdr's own toasts (the notifications mod) already say it, so nothing doubles up.
//
// A macOS notification when an agent needs you, or finishes, while Herdr is behind another
// window, saying what it asked or how its reply began. Clicking one opens that agent and brings
// Herdr forward. It posts through helper/'s HerdrAlerts.app (built into bin/ by
// helper/build.sh), or osascript until that's built. The Dock badge counts blocked agents.
// It draws nothing: gentle-herdr runs it as an empty floating block.
import { View, div } from "gpui-kit";
import { agents, appHome, checking, exec, hc, setBadge, terminals, window } from "herdr";
import { alert } from "./words.js";

const BUSY = new Set(["working", "blocked"]);
const CHECK_MS = 500;
// How much of an agent's screen and history is read for its question or reply.
const SCREEN_LINES = 80;

// $1 HerdrAlerts.app, $2 the title, $3 the tab, $4 the message, $5 the agent.focus arguments.
// open returns once the app is launched, and macOS lets only an app it launched ask to post.
// Without the app, osascript posts the same words, with no icon and no click.
const SCRIPT = `
herdr=$(command -v herdr-app || true)
[ -d "$1" ] && exec open -g -n "$1" --args post "$2" "$3" "$4" "$5" "$herdr"
exec osascript -e 'on run argv' -e 'display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv)' -e 'end run' "$2" "$3" "$4"
`;

const subAgents = () => new Set(terminals().filter((t) => t?.parent).map((t) => t.address));

export default class BetterAlerts extends View {
  init(_props, cx) {
    if (checking() || window()?.platform !== "macos") return;
    this.warned = false;
    this.helper = `${appHome()}/mods/better-alerts/bin/HerdrAlerts.app`;
    const current = agents();
    this.seen = new Map(current.map((a) => [a.address, a.status]));
    this.updateBadge(current, subAgents());
    cx.timer.every(CHECK_MS, () => this.check());
  }

  // Posts for each agent whose status changed since the last look, including a new agent's
  // first one. Agents already there when it starts count as seen; a sub-agent posts nothing,
  // since its parent speaks for it.
  check() {
    const current = agents();
    const subs = subAgents();
    this.updateBadge(current, subs);
    const behind = !window()?.active;
    const live = new Set();
    for (const a of current) {
      live.add(a.address);
      const before = this.seen.get(a.address);
      this.seen.set(a.address, a.status);
      if (before === a.status || subs.has(a.address) || !behind) continue;
      if (a.status === "blocked" || (a.status === "done" && BUSY.has(before))) this.post(a);
    }
    for (const address of this.seen.keys()) if (!live.has(address)) this.seen.delete(address);
  }

  updateBadge(current, subs) {
    const blocked = current.filter((a) => a.status === "blocked" && !subs.has(a.address)).length;
    const badge = blocked ? String(blocked) : null;
    if (badge === this.badge) return;
    this.badge = badge;
    setBadge(badge);
  }

  // The agent's screen and recent history, or nothing when it can't be read.
  async screen(address) {
    try {
      const read = await hc(["read", address, "--lines", String(SCREEN_LINES)]);
      return read?.code === 0 ? read.stdout : "";
    } catch {
      return "";
    }
  }

  async post(agent) {
    const said = alert(agent, await this.screen(agent.address));
    const target = JSON.stringify({ terminal: agent.address });
    try {
      await exec("sh", ["-c", SCRIPT, "sh", this.helper, said.title, said.tab, said.message, target]);
    } catch (error) {
      if (this.warned) return;
      this.warned = true;
      console.warn(`better-alerts: couldn't post a notification: ${error}`);
    }
  }

  render() {
    return div();
  }
}
