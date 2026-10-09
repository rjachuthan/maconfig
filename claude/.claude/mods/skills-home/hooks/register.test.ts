import { expect, mock, test } from 'claude-code/testing'

const SKILL = (name: string, description: string) =>
  `---\nname: ${name}\ndescription: >\n  ${description}\n---\nbody`
const dir = (name: string) => ({ name, kind: 'dir' as const, size: 0, mtimeMs: 0, isLink: false })

const props = { hasSurvey: false, isWorking: false, maxRows: 20, bodyColumns: 100, scroll: { offset: 0, bodyRows: 20 }, view: {} }

test('lists global and project skills on a fresh chat, then hides after the first prompt', async ($, on) => {
  mock.env(on, { USERPROFILE: 'C:/Users/me' })
  on('session.root', () => ({ value: 'C:/proj' }))
  on('session.start', () => ({ cwd: 'C:/proj' }))
  on('prompt.submit', (_$, e) => e as never)
  on('session.messages', () => ({ value: [] }) as never)
  on('ui.render', ($$, e) => ({ type: 'Text', props: {}, children: ['ENGINE'] }) as never)
  const norm = (path: string) => path.split('\\').join('/')
  on('fs.list', (_$, e) => ({
    value: norm(e.path).endsWith('/me/.claude/skills')
      ? [dir('g1')]
      : norm(e.path).endsWith('/proj/.claude/skills')
        ? [dir('p1')]
        : [],
  }))
  on('fs.read', (_$, e) => ({
    value: norm(e.path).includes('/g1/') ? SKILL('g1', 'Global thing') : SKILL('p1', 'Project thing'),
  }))

  await $.session.start({ cwd: 'C:/proj', surface: 'terminal', isInteractive: true })

  const draw = () =>
    $.ui.render({ surface: 'terminal', component: 'AbovePrompt', requestId: 'a', props } as never)

  const text = JSON.stringify(await draw())
  expect(text).toContain('Global skills')
  expect(text).toContain('g1')
  expect(text).toContain('Global thing')
  expect(text).toContain('Project skills')
  expect(text).toContain('p1')

  await $.prompt.submit({ text: 'hi' } as never)
  expect(JSON.stringify(await draw())).not.toContain('Global skills')
})
