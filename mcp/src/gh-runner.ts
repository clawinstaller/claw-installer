// gh CLI bridge — spawn gh commands and parse JSON output

import { spawn } from 'node:child_process'
import path from 'node:path'
import os from 'node:os'
import type { GhResult, CacheEntry } from './types.js'

const GH_BIN = '/opt/homebrew/bin/gh'
const DEFAULT_REPO = 'openclaw/openclaw'
const SPAWN_TIMEOUT = 30_000

// LRU cache: 5 min TTL, 100 max entries
const cache = new Map<string, CacheEntry>()
const CACHE_TTL = 5 * 60 * 1000
const CACHE_MAX = 100

function cacheKey(args: string[]): string {
  return args.join(' ')
}

function cacheGet<T>(key: string): T | null {
  const entry = cache.get(key)
  if (!entry) return null
  if (Date.now() - entry.timestamp > entry.ttl) {
    cache.delete(key)
    return null
  }
  return entry.data as T
}

function cacheSet<T>(key: string, data: T, ttl = CACHE_TTL): void {
  // Evict oldest if at capacity
  if (cache.size >= CACHE_MAX) {
    const oldest = cache.keys().next().value
    if (oldest) cache.delete(oldest)
  }
  cache.set(key, { data, timestamp: Date.now(), ttl })
}

function getSpawnEnv(): NodeJS.ProcessEnv {
  const env = { ...process.env }
  const extra = [
    path.join(os.homedir(), '.local', 'bin'),
    '/usr/local/bin',
    '/opt/homebrew/bin',
  ]
  env.PATH = extra.join(':') + ':' + (env.PATH || '')
  return env
}

/** Spawn gh CLI with given arguments, return parsed JSON or text */
export function spawnGh<T = unknown>(
  args: string[],
  options: { useCache?: boolean; timeout?: number } = {}
): Promise<GhResult<T>> {
  const { useCache = true, timeout = SPAWN_TIMEOUT } = options
  const key = cacheKey(args)

  if (useCache) {
    const cached = cacheGet<T>(key)
    if (cached !== null) {
      return Promise.resolve({ ok: true, data: cached })
    }
  }

  return new Promise((resolve) => {
    const proc = spawn(GH_BIN, args, {
      timeout,
      env: getSpawnEnv(),
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    let stdout = ''
    let stderr = ''

    proc.stdout.on('data', (chunk: Buffer) => {
      stdout += chunk.toString()
    })
    proc.stderr.on('data', (chunk: Buffer) => {
      stderr += chunk.toString()
    })

    proc.on('close', (code) => {
      if (code === 0) {
        try {
          const data = JSON.parse(stdout) as T
          if (useCache) cacheSet(key, data)
          resolve({ ok: true, data })
        } catch {
          // Not JSON — return as text wrapped in object
          resolve({ ok: true, data: { text: stdout.trim() } as T })
        }
      } else {
        resolve({
          ok: false,
          data: null,
          error: stderr.trim() || `gh exited with code ${code}`,
        })
      }
    })

    proc.on('error', (err) => {
      resolve({
        ok: false,
        data: null,
        error: `spawn error: ${err.message}`,
      })
    })
  })
}

// Convenience wrappers

interface GhIssueRaw {
  number: number
  title: string
  body: string
  state: string
  labels: { name: string }[]
  createdAt: string
  updatedAt: string
  comments: { totalCount: number }
  url: string
}

export async function searchIssues(
  query: string,
  options: { state?: string; labels?: string[]; limit?: number } = {}
): Promise<GhResult<GhIssueRaw[]>> {
  const { state = 'open', labels = [], limit = 30 } = options
  const args = [
    'issue', 'list',
    '--repo', DEFAULT_REPO,
    '--search', query,
    '--state', state,
    '--limit', String(limit),
    '--json', 'number,title,body,state,labels,createdAt,updatedAt,comments,url',
  ]
  if (labels.length > 0) {
    args.push('--label', labels.join(','))
  }
  return spawnGh<GhIssueRaw[]>(args)
}

export async function getIssue(
  number: number
): Promise<GhResult<GhIssueRaw & { comments: { nodes: { author: { login: string }; body: string; createdAt: string }[] } }>> {
  const args = [
    'issue', 'view', String(number),
    '--repo', DEFAULT_REPO,
    '--json', 'number,title,body,state,labels,createdAt,updatedAt,comments,url',
  ]
  return spawnGh(args)
}

export function clearCache(): void {
  cache.clear()
}
