export type Skill = { name: string; description: string }
export type SkillLists = { global: Skill[]; project: Skill[] }

declare module 'claude-code' {
  interface PluginState {
    'skills-home': { skills: SkillLists | null; isHidden: boolean }
  }
}
