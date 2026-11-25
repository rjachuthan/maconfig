// Save chord: Command+S on macOS, Ctrl+S elsewhere. `platform` is the Windows key outside macOS, so it must not count there.
export const isSaveKey = (e, platform) => e.key === "s" && !e.modifiers.alt && !e.modifiers.shift
  && (platform === "macos" ? e.modifiers.platform && !e.modifiers.control : e.modifiers.control && !e.modifiers.platform);

export const saveHint = platform => platform === "macos" ? "\u2318 S" : "Ctrl S";
