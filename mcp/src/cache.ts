// JSONL complaint store — append-only log for trend analysis

import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import type { ComplaintEntry, Category } from './types.js'

const STORE_DIR = path.join(os.homedir(), '.claw-installer')
const STORE_FILE = path.join(STORE_DIR, 'complaints.jsonl')

function ensureDir(): void {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true })
  }
}

/** Append a complaint entry to the JSONL store */
export function logComplaint(entry: ComplaintEntry): void {
  ensureDir()
  const line = JSON.stringify(entry) + '\n'
  fs.appendFileSync(STORE_FILE, line, 'utf-8')
}

/** Log multiple issues as complaints */
export function logIssuesAsComplaints(
  issues: { number: number; title: string; category: Category; labels: string[] }[]
): void {
  ensureDir()
  const timestamp = new Date().toISOString()
  const lines = issues.map((issue) =>
    JSON.stringify({
      timestamp,
      issueNumber: issue.number,
      title: issue.title,
      category: issue.category,
      labels: issue.labels,
    } satisfies ComplaintEntry)
  )
  if (lines.length > 0) {
    fs.appendFileSync(STORE_FILE, lines.join('\n') + '\n', 'utf-8')
  }
}

/** Read all complaints from the store */
export function readComplaints(): ComplaintEntry[] {
  if (!fs.existsSync(STORE_FILE)) return []

  const content = fs.readFileSync(STORE_FILE, 'utf-8')
  return content
    .split('\n')
    .filter((line) => line.trim())
    .map((line) => {
      try {
        return JSON.parse(line) as ComplaintEntry
      } catch {
        return null
      }
    })
    .filter((entry): entry is ComplaintEntry => entry !== null)
}

/** Get complaints filtered by period */
export function getComplaintsByPeriod(
  period: 'week' | 'month' | 'quarter' | 'all' = 'month'
): ComplaintEntry[] {
  const all = readComplaints()
  if (period === 'all') return all

  const now = Date.now()
  const msMap = {
    week: 7 * 24 * 60 * 60 * 1000,
    month: 30 * 24 * 60 * 60 * 1000,
    quarter: 90 * 24 * 60 * 60 * 1000,
  }
  const cutoff = now - msMap[period]

  return all.filter((entry) => new Date(entry.timestamp).getTime() > cutoff)
}

/** Get category distribution from complaints */
export function getComplaintDistribution(
  complaints: ComplaintEntry[]
): Map<Category, number> {
  const counts = new Map<Category, number>()
  for (const entry of complaints) {
    counts.set(entry.category, (counts.get(entry.category) || 0) + 1)
  }
  return counts
}
