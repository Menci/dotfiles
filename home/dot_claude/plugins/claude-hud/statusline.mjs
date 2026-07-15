// Derived from the Claude-HUD cross-platform launcher:
// https://github.com/jarrodwatts/claude-hud/blob/5555a1ddb5784f4cfaaf71acf7c8b386f6868bc7/commands/setup.md#L229-L293
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

const envColumns = Number.parseInt(process.env.COLUMNS ?? '', 10)
const width = Number.isFinite(envColumns) && envColumns > 0 ? envColumns : 120
process.env.COLUMNS = String(Math.max(1, width - 4))

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude')
const cacheDir = path.join(claudeDir, 'plugins', 'cache')
const versionPattern = /^(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$/
const candidates = []

for (const marketplace of fs.readdirSync(cacheDir, { withFileTypes: true })) {
  if (!marketplace.isDirectory())
    continue

  const pluginRoot = path.join(cacheDir, marketplace.name, 'claude-hud')
  if (!fs.existsSync(pluginRoot))
    continue

  for (const version of fs.readdirSync(pluginRoot, { withFileTypes: true })) {
    const match = version.isDirectory() && versionPattern.exec(version.name)
    if (!match)
      continue

    const entry = path.join(pluginRoot, version.name, 'dist', 'index.js')
    if (fs.existsSync(entry))
      candidates.push({ entry, version: match.slice(1, 4).map(Number) })
  }
}

candidates.sort((a, b) => {
  for (let index = 0; index < 3; index += 1) {
    if (a.version[index] !== b.version[index])
      return a.version[index] - b.version[index]
  }
  return 0
})

const latest = candidates.at(-1)
if (latest) {
  const hud = await import(pathToFileURL(latest.entry).href)
  if (typeof hud.main === 'function')
    await hud.main()
}
