import type { Register } from 'claude-code'

type Segment = { kind: 'md'; text: string } | { kind: 'mermaid'; source: string }
type Graph = {
  nodes: Map<string, { label: string; group: string }>
  edges: { from: string; to: string; label: string }[]
  groups: string[]
}

const MAX_MARKDOWN = 9000
const PALETTE = ['cyan', 'magenta', 'yellow', 'green', 'blue', 'red']

// ---- HTML -> markdown -------------------------------------------------------

const HTML_TAG = /<\/?(ul|ol|li|br|p|b|strong|i|em|code|h[1-6]|div|span|a|hr|table|tr|td|th|pre)\b[^>]*>/i

function htmlToMarkdown(input: string): string {
  const convertBlock = (s: string): string => {
    let out = s
    out = out.replace(/<ol\b[^>]*>([\s\S]*?)<\/ol>/gi, (_, body: string) => {
      let n = 0
      return '\n' + body.replace(/<li\b[^>]*>([\s\S]*?)<\/li>/gi, (_m, t: string) => `${++n}. ${t.trim()}\n`) + '\n'
    })
    out = out.replace(/<li\b[^>]*>/gi, '\n- ').replace(/<\/li>/gi, '')
    out = out.replace(/<\/?(ul|ol)\b[^>]*>/gi, '\n')
    out = out.replace(/<br\s*\/?>/gi, '  \n')
    out = out.replace(/<\/?(p|div)\b[^>]*>/gi, '\n\n')
    out = out.replace(/<h([1-6])\b[^>]*>([\s\S]*?)<\/h\1>/gi, (_, n: string, t: string) => `\n\n${'#'.repeat(+n)} ${t.trim()}\n\n`)
    out = out.replace(/<(b|strong)\b[^>]*>([\s\S]*?)<\/\1>/gi, '**$2**')
    out = out.replace(/<(i|em)\b[^>]*>([\s\S]*?)<\/\1>/gi, '*$2*')
    out = out.replace(/<code\b[^>]*>([\s\S]*?)<\/code>/gi, '`$1`')
    out = out.replace(/<a\b[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, '[$2]($1)')
    out = out.replace(/<hr\s*\/?>/gi, '\n\n---\n\n')
    out = out.replace(/<\/?(span|a|pre|table|tr|td|th)\b[^>]*>/gi, '')
    return out.replace(/\n{3,}/g, '\n\n')
  }

  const convertCell = (line: string): string =>
    line
      .replace(/<li\b[^>]*>/gi, '• ')
      .replace(/<\/li>/gi, ' ')
      .replace(/<br\s*\/?>/gi, ' · ')
      .replace(/<\/?(ul|ol|p|div|span)\b[^>]*>/gi, '')
      .replace(/<(b|strong)\b[^>]*>([\s\S]*?)<\/\1>/gi, '**$2**')
      .replace(/<(i|em)\b[^>]*>([\s\S]*?)<\/\1>/gi, '*$2*')
      .replace(/<code\b[^>]*>([\s\S]*?)<\/code>/gi, '`$1`')

  const out: string[] = []
  let buf: string[] = []
  const flush = () => {
    if (buf.length) out.push(convertBlock(buf.join('\n')))
    buf = []
  }
  for (const line of input.split('\n')) {
    if (/^\s*\|/.test(line)) {
      flush()
      out.push(convertCell(line))
    } else {
      buf.push(line)
    }
  }
  flush()
  return out.join('\n')
}

// ---- Mermaid ----------------------------------------------------------------

const ARROW = /\s*(?:-->|---|-\.->|-\.-|==>|--[ox]|<-->)\s*(?:\|([^|]*)\|)?\s*/
const NODE = /^([\w.-]+)\s*(?:\[\[?\(?"?([^\]"]*?)"?\)?\]?\]|\(\(?"?([^)"]*?)"?\)?\)|\{\{?"?([^}"]*?)"?\}?\}|>"?([^\]"]*?)"?\])?$/

function parseMermaid(source: string): Graph | null {
  const lines = source.split('\n').map(l => l.replace(/%%.*$/, '').trim()).filter(Boolean)
  if (!lines.length || !/^(flowchart|graph)\b/i.test(lines[0])) return null

  const g: Graph = { nodes: new Map(), edges: [], groups: [] }
  const stack: string[] = []

  const touch = (tok: string): string | null => {
    const m = NODE.exec(tok.trim().replace(/:::\w+$/, ''))
    if (!m) return null
    const id = m[1]
    const label = (m[2] ?? m[3] ?? m[4] ?? m[5] ?? '').replace(/<br\s*\/?>/gi, ' ').trim()
    const prev = g.nodes.get(id)
    g.nodes.set(id, {
      label: label || prev?.label || id,
      group: prev?.group ?? stack[stack.length - 1] ?? '',
    })
    return id
  }

  for (const line of lines.slice(1)) {
    const sub = /^subgraph\s+(.+)$/i.exec(line)
    if (sub) {
      const name = sub[1].replace(/^[\w.-]+\s*\[(.*)\]$/, '$1').replace(/^"|"$/g, '')
      stack.push(name)
      if (!g.groups.includes(name)) g.groups.push(name)
      continue
    }
    if (/^end$/i.test(line)) {
      stack.pop()
      continue
    }
    if (/^(direction|style|classDef|class|linkStyle|click)\b/i.test(line)) continue

    const parts: string[] = []
    const labels: string[] = []
    let rest = line.replace(/;$/, '')
    for (;;) {
      const m = ARROW.exec(rest)
      if (!m) break
      parts.push(rest.slice(0, m.index))
      labels.push(m[1] ?? '')
      rest = rest.slice(m.index + m[0].length)
    }
    parts.push(rest)
    const ids = parts.map(touch)
    for (let i = 0; i + 1 < ids.length; i++) {
      const from = ids[i]
      const to = ids[i + 1]
      if (from && to) g.edges.push({ from, to, label: labels[i].trim() })
    }
  }
  return g.nodes.size ? g : null
}

function layerOf(g: Graph): Map<string, number> {
  const layer = new Map<string, number>()
  for (const id of g.nodes.keys()) layer.set(id, 0)
  for (let pass = 0; pass < g.nodes.size; pass++) {
    let changed = false
    for (const e of g.edges) {
      const want = (layer.get(e.from) ?? 0) + 1
      if (want > (layer.get(e.to) ?? 0) && want <= g.nodes.size) {
        layer.set(e.to, want)
        changed = true
      }
    }
    if (!changed) break
  }
  return layer
}

// ---- Splitting --------------------------------------------------------------

function split(text: string): Segment[] {
  const out: Segment[] = []
  const fence = /(^|\n)(```|~~~)[ \t]*([\w-]*)[^\n]*\n([\s\S]*?)\n\2[ \t]*(?=\n|$)/g
  let last = 0
  const pushMd = (s: string) => {
    if (s.trim()) out.push({ kind: 'md', text: s })
  }
  for (let m = fence.exec(text); m; m = fence.exec(text)) {
    pushMd(htmlToMarkdown(text.slice(last, m.index)))
    if (m[3].toLowerCase() === 'mermaid') {
      out.push({ kind: 'mermaid', source: m[4] })
    } else {
      // other fences are code: keep verbatim
      pushMd(text.slice(m.index, fence.lastIndex).replace(/^\n/, ''))
    }
    last = fence.lastIndex
  }
  pushMd(htmlToMarkdown(text.slice(last)))
  return out
}

function chunk(text: string): string[] {
  if (text.length <= MAX_MARKDOWN) return [text]
  const parts: string[] = []
  let cur = ''
  for (const para of text.split(/\n\n/)) {
    if (cur && cur.length + para.length + 2 > MAX_MARKDOWN) {
      parts.push(cur)
      cur = ''
    }
    cur = cur ? cur + '\n\n' + para : para
  }
  if (cur) parts.push(cur)
  return parts.map(p => p.slice(0, MAX_MARKDOWN))
}

// ---- Hook -------------------------------------------------------------------

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    const text = e.props.text
    if (!HTML_TAG.test(text) && !/```mermaid/i.test(text)) return next(e)

    const { Box, Text, Markdown, Code } = $.ui.resolve(e)

    const drawGraph = (g: Graph, key: string) => {
      const layer = layerOf(g)
      const depth = Math.max(0, ...layer.values())
      const colorOf = (grp: string) => PALETTE[Math.max(0, g.groups.indexOf(grp)) % PALETTE.length]
      const rows = []
      for (let d = 0; d <= depth; d++) {
        const ids = [...g.nodes.keys()].filter(id => layer.get(id) === d)
        if (!ids.length) continue
        const out = g.edges.filter(ed => layer.get(ed.from) === d)
        rows.push(
          <Box key={`${key}-l${d}`} flexDirection="column" alignItems="center">
            <Box flexDirection="row" flexWrap="wrap" gap={1} justifyContent="center">
              {ids.map(id => {
                const n = g.nodes.get(id)!
                return (
                  <Box key={`${key}-${id}`} borderStyle="round" borderColor={n.group ? colorOf(n.group) : 'white'} paddingX={1}>
                    <Text bold>{n.label}</Text>
                  </Box>
                )
              })}
            </Box>
            {out.length > 0 && (
              <Box flexDirection="column" alignItems="center">
                <Text dimColor>│</Text>
                {out.map((ed, i) => (
                  <Text key={`${key}-e${d}-${i}`} dimColor>
                    {`${g.nodes.get(ed.from)!.label} ──▶ ${g.nodes.get(ed.to)!.label}${ed.label ? ` (${ed.label})` : ''}`}
                  </Text>
                ))}
                <Text dimColor>▼</Text>
              </Box>
            )}
          </Box>,
        )
      }
      return (
        <Box key={key} flexDirection="column" borderStyle="round" borderDimColor paddingX={1} marginY={1}>
          {g.groups.length > 0 && (
            <Box flexDirection="row" gap={2}>
              {g.groups.map(grp => (
                <Text key={`${key}-g-${grp}`} color={colorOf(grp)}>
                  {`■ ${grp}`}
                </Text>
              ))}
            </Box>
          )}
          {rows}
        </Box>
      )
    }

    const blocks = split(text).flatMap((seg, i) => {
      if (seg.kind === 'mermaid') {
        const g = parseMermaid(seg.source)
        return [g ? drawGraph(g, `m${i}`) : <Code key={`m${i}`} source={seg.source} language="mermaid" />]
      }
      return chunk(seg.text).map((t, j) => <Markdown key={`t${i}-${j}`} text={t} />)
    })

    return (
      <Box flexDirection="row">
        <Box width={2}>
          <Text>{e.props.isFirstOfReply ? '● ' : '  '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1}>
          {blocks}
        </Box>
      </Box>
    )
  })
}
