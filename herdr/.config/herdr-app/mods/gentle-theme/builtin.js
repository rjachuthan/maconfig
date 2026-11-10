// Pi's built-in `dark` and `light` themes (pi-coding-agent 1.4.0), trimmed to what derive.js reads.
// Pi ships them inside its package, not as files, so they are embedded here. Colors are okhsl() or var names.

export const BUILTIN = {
  dark: {
    "vars": {
      "text": "okhsl(234 3% 89%)",
      "muted": "okhsl(229 6% 67%)",
      "violet": "okhsl(295 50% 67%)",
      "blue": "okhsl(232 54% 67%)",
      "green": "okhsl(159 59% 67%)",
      "red": "okhsl(20 72% 67%)",
      "yellow": "okhsl(83 88% 67%)",
      "blueBg": "okhsl(233 41% 24%)"
    },
    "colors": {
      "accent": "violet",
      "border": "okhsl(231 57% 65%)",
      "borderMuted": "okhsl(229 8% 53%)",
      "success": "green",
      "error": "red",
      "warning": "yellow",
      "muted": "muted",
      "dim": "okhsl(229 8% 56%)",
      "text": "text",
      "selectedBg": "blueBg",
      "userMessageBg": "blueBg",
      "mdLink": "blue",
      "syntaxVariable": "okhsl(202 58% 67%)"
    },
    "export": {
      "pageBg": "okhsl(262 14% 16%)",
      "cardBg": "okhsl(264 13% 19%)",
      "infoBg": "okhsl(53 51% 24%)"
    }
  },
  light: {
    "vars": {
      "text": "okhsl(225 5% 27%)",
      "muted": "okhsl(229 8% 47%)",
      "violet": "okhsl(295 60% 46%)",
      "blue": "okhsl(231 68% 47%)",
      "green": "okhsl(159 75% 46%)",
      "red": "okhsl(20 91% 47%)",
      "yellow": "okhsl(83 99% 47%)",
      "blueBg": "okhsl(235 19% 91%)"
    },
    "colors": {
      "accent": "violet",
      "border": "okhsl(231 67% 55%)",
      "borderMuted": "okhsl(235 7% 66%)",
      "success": "green",
      "error": "red",
      "warning": "yellow",
      "muted": "muted",
      "dim": "okhsl(229 7% 59%)",
      "text": "text",
      "selectedBg": "blueBg",
      "userMessageBg": "blueBg",
      "mdLink": "blue",
      "syntaxVariable": "okhsl(203 73% 46%)"
    },
    "export": {
      "pageBg": "okhsl(17 3% 94%)",
      "cardBg": "okhsl(17 5% 97%)",
      "infoBg": "okhsl(56 22% 91%)"
    }
  },
};
