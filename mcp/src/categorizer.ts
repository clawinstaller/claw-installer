// Issue categorizer — regex-based classification into 6 categories

import type { Category } from './types.js'

interface CategoryRule {
  category: Category
  patterns: RegExp[]
  weight: number
}

const RULES: CategoryRule[] = [
  {
    category: 'installation',
    weight: 1,
    patterns: [
      /\b(install|uninstall|reinstall)\b/i,
      /\bnpm\s+(install|i|ci)\b/i,
      /\b(npx|pnpm|yarn|bun)\b/i,
      /\bnode(\.?js)?\s*(version|v?\d)/i,
      /\b(build|compile)\s*(fail|error)/i,
      /\bsharp\b/i,
      /\bnative\s*module/i,
      /\bENOENT\b/,
      /\bgyp\s*(ERR|error)/i,
      /\bnode-pre-gyp\b/i,
      /\bdependenc(y|ies)\b/i,
      /\bpackage\.json\b/i,
      /\bsetup\s*(wizard|guide|fail)/i,
      /\bhomebrew|brew\s+install/i,
    ],
  },
  {
    category: 'config',
    weight: 1,
    patterns: [
      /\bconfig(uration)?\b/i,
      /\bopenclaw\.json\b/i,
      /\benvironment\s*var/i,
      /\b\.env\b/,
      /\bAPI\s*key/i,
      /\bsecret\b/i,
      /\bsettings?\b/i,
      /\bYAML|TOML|JSON\s*config/i,
      /\binvalid\s*config/i,
    ],
  },
  {
    category: 'channels',
    weight: 1,
    patterns: [
      /\btelegram\b/i,
      /\bdiscord\b/i,
      /\bwhatsapp\b/i,
      /\bslack\b/i,
      /\bchannel\b/i,
      /\bbot\s*token\b/i,
      /\bwebhook\b/i,
      /\bmessaging\b/i,
      /\bbridge\b/i,
    ],
  },
  {
    category: 'daemon',
    weight: 1,
    patterns: [
      /\bgateway\b/i,
      /\bdaemon\b/i,
      /\bprocess\b/i,
      /\bport\s*\d+/i,
      /\bsystemd\b/i,
      /\blaunchd\b/i,
      /\bcrash(es|ed|ing)?\b/i,
      /\bservice\s*(start|stop|restart)/i,
      /\bpid\s*file\b/i,
      /\bsocket\b/i,
      /\bwebsocket\b/i,
    ],
  },
  {
    category: 'security',
    weight: 1,
    patterns: [
      /\bauth(entication|orization)?\b/i,
      /\btoken\s*(expir|invalid|revok)/i,
      /\bpermission\s*(denied|error)/i,
      /\bscope\b/i,
      /\bvulnerabilit(y|ies)\b/i,
      /\bCVE-\d/i,
      /\bencrypt/i,
      /\bSSL|TLS\b/i,
    ],
  },
  {
    category: 'performance',
    weight: 1,
    patterns: [
      /\bslow\b/i,
      /\bmemory\s*(leak|usage|high)/i,
      /\bCPU\s*(usage|high|100)/i,
      /\bleak\b/i,
      /\btimeout\b/i,
      /\blatency\b/i,
      /\bperformance\b/i,
      /\bhang(s|ing)?\b/i,
      /\bfreeze\b/i,
    ],
  },
]

/** Classify an issue by title + body text */
export function categorize(title: string, body: string = ''): Category {
  const text = `${title} ${body}`
  const scores = new Map<Category, number>()

  for (const rule of RULES) {
    let matchCount = 0
    for (const pattern of rule.patterns) {
      if (pattern.test(text)) {
        matchCount++
      }
    }
    if (matchCount > 0) {
      scores.set(rule.category, (scores.get(rule.category) || 0) + matchCount * rule.weight)
    }
  }

  if (scores.size === 0) return 'other'

  // Return category with highest score
  let best: Category = 'other'
  let bestScore = 0
  for (const [cat, score] of scores) {
    if (score > bestScore) {
      bestScore = score
      best = cat
    }
  }
  return best
}

/** Categorize multiple issues */
export function categorizeAll(
  issues: { title: string; body?: string }[]
): Map<Category, number> {
  const counts = new Map<Category, number>()
  for (const issue of issues) {
    const cat = categorize(issue.title, issue.body)
    counts.set(cat, (counts.get(cat) || 0) + 1)
  }
  return counts
}
