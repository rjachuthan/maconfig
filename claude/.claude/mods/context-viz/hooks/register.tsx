import type { Register } from 'claude-code'

const PANE = 'context-viz'
const BAR = 48
const PALETTE = ['cyan', 'magenta', 'yellow', 'green', 'blue', 'red', 'white'] as const

const fmt = (n: number) => (n >= 1000 ? `${(n / 1000).toFixed(n >= 10000 ? 0 : 1)}k` : String(Math.round(n)))
const pct = (n: number, of: number) => (of > 0 ? `${((n / of) * 100).toFixed(1)}%` : '0%')
const cut = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1)}…` : s)
const tail = (p: string) => p.split(/[\/]/).slice(-2).join('/')

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'context-viz',
      description: 'Visualize the context window: system prompt, MCPs, skills, memory, messages',
    })

    return next(e)
  })

  on('command.run', { command: 'context-viz' }, async $ => {
    await $.ui.open({ id: PANE, title: 'Context' })

    return { text: 'Context pane opened.' }
  })

  // Keep the pane live: the breakdown is a free local estimate in `summary` mode.
  on('prompt.submit', async ($, e, next) => {
    $.ui.invalidate('ui.render')

    return next(e)
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const usage = await $.session.usage({ breakdown: 'summary', columns: 80 })
    const b = usage.context.breakdown

    if (!b) {
      return <Text dimColor>No context breakdown available yet. Send a message first.</Text>
    }

    const max = b.rawMaxTokens
    const shown = b.categories.filter(c => c.kind !== 'deferred' && c.tokens > 0)
    const color = new Map(shown.map((c, i) => [c.name, PALETTE[i % PALETTE.length] as string]))
    const colorOf = (n: string) => (n === 'Free space' ? 'gray' : color.get(n) ?? 'gray')

    // Stacked bar: one cell per slice of the window, largest remainder not needed at this resolution.
    const cells = shown.map(c => ({ c, n: Math.round((c.tokens / max) * BAR) }))
    const used = b.totalTokens

    const mcp = new Map<string, { tokens: number; count: number }>()
    for (const t of b.mcpTools) {
      const m = mcp.get(t.serverName) ?? { tokens: 0, count: 0 }
      m.tokens += t.tokens
      m.count += 1
      mcp.set(t.serverName, m)
    }
    const mcpRows = [...mcp.entries()].sort((a, z) => z[1].tokens - a[1].tokens)
    const skills = [...(b.skills?.skillFrontmatter ?? [])].sort((a, z) => z.tokens - a.tokens)

    const head = (t: string, right?: string) => (
      <Box marginTop={1}>
        <Text bold>{t}</Text>
        {right ? <Text dimColor>{`  ${right}`}</Text> : null}
      </Box>
    )

    return (
      <Box flexDirection="column">
        <Text>
          <Text bold>{fmt(used)}</Text>
          <Text dimColor>{` / ${fmt(max)} tokens  `}</Text>
          <Text bold>{`${Math.round(b.percentage)}%`}</Text>
          <Text dimColor>{`  ${b.model}`}</Text>
        </Text>
        <Text>
          {cells.map(({ c, n }) => (
            <Text key={c.name} color={colorOf(c.name)}>
              {(c.kind === 'free' ? '░' : '█').repeat(n)}
            </Text>
          ))}
        </Text>
        <Text dimColor>
          {`model window ${fmt(usage.context.window)} · compaction window ${fmt(max)} (${b.autocompactSource})`}
          {b.isAutoCompactEnabled && b.autoCompactThreshold ? ` · auto-compact at ${fmt(b.autoCompactThreshold)}` : ' · auto-compact off'}
        </Text>

        {head('Breakdown')}
        {shown.map(c => (
          <Text key={c.name}>
            <Text color={colorOf(c.name)}>{c.kind === 'free' ? '░ ' : '█ '}</Text>
            {cut(c.name, 26).padEnd(27)}
            <Text bold>{fmt(c.tokens).padStart(7)}</Text>
            <Text dimColor>{`  ${pct(c.tokens, max).padStart(6)}`}</Text>
          </Text>
        ))}
        {b.categories
          .filter(c => c.kind === 'deferred')
          .map(c => (
            <Text key={c.name} dimColor>{`  ${cut(c.name, 26).padEnd(27)}${fmt(c.tokens).padStart(7)}  (on demand, not counted)`}</Text>
          ))}

        {head('MCP servers', `${b.mcpTools.length} tools · ${fmt(b.mcpTools.reduce((s, t) => s + t.tokens, 0))}`)}
        {mcpRows.length === 0 && <Text dimColor>none</Text>}
        {mcpRows.slice(0, 8).map(([name, m]) => (
          <Text key={name}>{`  ${cut(name, 28).padEnd(29)}${fmt(m.tokens).padStart(7)}  `}<Text dimColor>{`${m.count} tools`}</Text></Text>
        ))}

        {head('Skills', b.skills ? `${b.skills.includedSkills}/${b.skills.totalSkills} listed · ${fmt(b.skills.tokens)}` : undefined)}
        {skills.length === 0 && <Text dimColor>none</Text>}
        {skills.slice(0, 8).map(s => (
          <Text key={s.name}>{`  ${cut(s.name, 40).padEnd(41)}${fmt(s.tokens).padStart(6)}`}</Text>
        ))}
        {skills.length > 8 && <Text dimColor>{`  … ${skills.length - 8} more`}</Text>}

        {b.slashCommands ? head('Slash commands', `${b.slashCommands.includedCommands}/${b.slashCommands.totalCommands} · ${fmt(b.slashCommands.tokens)}`) : null}

        {head('Memory files', fmt(b.memoryFiles.reduce((s, f) => s + f.tokens, 0)))}
        {b.memoryFiles.length === 0 && <Text dimColor>none</Text>}
        {b.memoryFiles.slice(0, 8).map(f => (
          <Text key={f.path}>{`  ${cut(`${f.type}: ${tail(f.path)}`, 40).padEnd(41)}${fmt(f.tokens).padStart(6)}`}</Text>
        ))}

        {b.agents.length > 0 && head('Custom agents', fmt(b.agents.reduce((s, a) => s + a.tokens, 0)))}
        {b.agents.slice(0, 6).map(a => (
          <Text key={a.agentType}>{`  ${cut(a.agentType, 40).padEnd(41)}${fmt(a.tokens).padStart(6)}`}</Text>
        ))}

        {usage.cost ? <Text dimColor>{`\nsession cost $${usage.cost.usd.toFixed(2)} · estimates, /context-viz to reopen`}</Text> : null}
      </Box>
    )
  })
}
