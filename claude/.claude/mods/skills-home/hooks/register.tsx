import { atom, read, update } from 'claude-code'
import type { EngineInterface, FsEntry, Register } from 'claude-code'

import type { Skill, SkillLists } from '../types'

const skills = atom({ plugin: 'skills-home', key: 'skills' } as const, null)
const isHidden = atom({ plugin: 'skills-home', key: 'isHidden' } as const, false)

const MAX_DESCRIPTION = 110

const slashes = (path: string) => path.split('\\').join('/')

// Reads `name` and `description` from a SKILL.md frontmatter, including
// quoted values and `>` / `|` block scalars.
function parseFrontmatter(text: string): Skill | null {
  const match = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text)
  if (!match) return null

  const lines = match[1].split(/\r?\n/)
  const fields: Record<string, string> = {}

  for (let i = 0; i < lines.length; i++) {
    const kv = /^([A-Za-z_-]+):\s*(.*)$/.exec(lines[i])
    if (!kv) continue

    let value = kv[2].trim()
    if (/^[>|][+-]?$/.test(value) || value === '') {
      const parts: string[] = []
      while (i + 1 < lines.length && /^\s+\S/.test(lines[i + 1])) {
        parts.push(lines[++i].trim())
      }
      value = parts.join(' ')
    }
    fields[kv[1]] = value.replace(/^(["'])([\s\S]*)\1$/, '$2')
  }

  return fields.name ? { name: fields.name, description: fields.description ?? '' } : null
}

async function load($: EngineInterface, dir: string): Promise<Skill[]> {
  const found: Skill[] = []
  let entries: FsEntry[] = []

  try {
    entries = await $.fs.list(dir)
  } catch {
    return found
  }

  for (const entry of entries) {
    if (entry.kind === 'file') continue
    try {
      const skill = parseFrontmatter(await $.fs.read(`${dir}/${entry.name}/SKILL.md`))
      if (skill) found.push(skill)
    } catch {
      // not a skill folder
    }
  }

  return found.sort((a, b) => a.name.localeCompare(b.name))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const home = slashes((await $.env.get('USERPROFILE')) ?? (await $.env.get('HOME')) ?? '')
    const root = slashes(await $.session.root())

    const lists: SkillLists = {
      global: home ? await load($, `${home}/.claude/skills`) : [],
      project: await load($, `${root}/.claude/skills`),
    }
    // A project skill with the same name as a global one is shown once, under project.
    const projectNames = new Set(lists.project.map(s => s.name))
    lists.global = lists.global.filter(s => !projectNames.has(s.name))

    await update($, skills, () => lists)

    return next(e)
  })

  // The chat has started: the list is a start screen only.
  on('prompt.submit', async ($, e, next) => {
    await update($, isHidden, () => true)

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const lists = await read($, skills)
    const isQuiet = e.props.hasSurvey || e.props.isWorking || lists === null || (await read($, isHidden))

    if (isQuiet || (lists.global.length === 0 && lists.project.length === 0)) {
      return next(e)
    }

    // Resumed or cleared-into-existing sessions already have messages.
    if ((await $.session.messages()).length > 0) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const bullet = (s: Skill) => {
      const d = s.description.length > MAX_DESCRIPTION ? `${s.description.slice(0, MAX_DESCRIPTION - 1)}…` : s.description
      return (
        <Text key={s.name} wrap="truncate-end">
          {'  • '}
          <Text bold>{s.name}</Text>
          {d ? <Text dimColor>{` — ${d}`}</Text> : null}
        </Text>
      )
    }

    return (
      <Box flexDirection="column">
        {lists.global.length > 0 ? <Text bold>Global skills ({lists.global.length})</Text> : null}
        {lists.global.map(bullet)}
        {lists.project.length > 0 ? <Text bold>Project skills ({lists.project.length})</Text> : null}
        {lists.project.map(bullet)}
      </Box>
    )
  })
}
