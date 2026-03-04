#!/usr/bin/env node
// gh-issues-tracker — MCP server for GitHub issue tracking & pain point analysis

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'
import { searchIssues, getIssue } from './gh-runner.js'
import { categorize, categorizeAll } from './categorizer.js'
import { logIssuesAsComplaints, getComplaintsByPeriod, getComplaintDistribution } from './cache.js'
import type { GhIssue, Category, CategoryCount, AnalysisResult, ReportResult } from './types.js'

const server = new McpServer({
  name: 'gh-issues-tracker',
  version: '2026.3.4',
})

// Helper: normalize raw gh issue to our format
function normalizeIssue(raw: any): GhIssue {
  const labels = (raw.labels || []).map((l: any) => (typeof l === 'string' ? l : l.name))
  const commentCount = typeof raw.comments === 'number' ? raw.comments : raw.comments?.totalCount ?? 0
  return {
    number: raw.number,
    title: raw.title,
    body: raw.body || '',
    state: raw.state,
    labels,
    createdAt: raw.createdAt,
    updatedAt: raw.updatedAt,
    comments: commentCount,
    url: raw.url,
    category: categorize(raw.title, raw.body),
  }
}

// ─── Tool 1: issues_search ───

server.tool(
  'issues_search',
  'Search openclaw/openclaw issues by keyword. Returns categorized results with pain point classification.',
  {
    query: z.string().describe('Search query (e.g. "install error", "telegram bot")'),
    labels: z.array(z.string()).optional().describe('Filter by labels'),
    state: z.enum(['open', 'closed', 'all']).optional().default('open').describe('Issue state filter'),
    limit: z.number().optional().default(30).describe('Max results (default 30)'),
  },
  async ({ query, labels, state, limit }) => {
    const result = await searchIssues(query, { state, labels, limit })

    if (!result.ok || !result.data) {
      return { content: [{ type: 'text' as const, text: `Error: ${result.error || 'Failed to search issues'}` }] }
    }

    const issues = result.data.map(normalizeIssue)

    // Log to complaint store for trend tracking
    logIssuesAsComplaints(
      issues.map((i) => ({
        number: i.number,
        title: i.title,
        category: i.category!,
        labels: i.labels,
      }))
    )

    const summary = issues.map((i) =>
      `#${i.number} [${i.category}] ${i.title} (${i.comments} comments, ${i.labels.join(', ') || 'no labels'})`
    ).join('\n')

    const catCounts = categorizeAll(issues)
    const catSummary = [...catCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([cat, count]) => `  ${cat}: ${count}`)
      .join('\n')

    return {
      content: [{
        type: 'text' as const,
        text: `Found ${issues.length} issues for "${query}":\n\n${summary}\n\nCategory breakdown:\n${catSummary}`,
      }],
    }
  }
)

// ─── Tool 2: issues_analyze ───

server.tool(
  'issues_analyze',
  'Analyze pain points in openclaw/openclaw issues. Returns category distribution, top issues, and trend analysis.',
  {
    category: z.enum(['installation', 'config', 'channels', 'daemon', 'security', 'performance']).optional()
      .describe('Focus on a specific category (default: all)'),
    days: z.number().optional().default(90).describe('Analysis period in days (default 90)'),
  },
  async ({ category, days }) => {
    // Search for issues across common pain point queries
    const queries = category
      ? [getCategoryQuery(category)]
      : ['install error', 'config', 'telegram discord', 'gateway crash', 'security', 'slow performance']

    const allIssues: GhIssue[] = []
    const seen = new Set<number>()

    for (const q of queries) {
      const result = await searchIssues(q, { state: 'all', limit: 50 })
      if (result.ok && result.data) {
        for (const raw of result.data) {
          const issue = normalizeIssue(raw)
          if (!seen.has(issue.number)) {
            seen.add(issue.number)
            allIssues.push(issue)
          }
        }
      }
    }

    // Filter by date
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
    const filtered = allIssues.filter((i) => new Date(i.createdAt).getTime() > cutoff)

    // Filter by category if specified
    const targetIssues = category
      ? filtered.filter((i) => i.category === category)
      : filtered

    // Category distribution
    const catCounts = new Map<Category, number>()
    for (const issue of filtered) {
      const cat = issue.category || 'other'
      catCounts.set(cat, (catCounts.get(cat) || 0) + 1)
    }

    const total = filtered.length
    const categoryCounts: CategoryCount[] = [...catCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([cat, count]) => ({
        category: cat,
        count,
        percentage: total > 0 ? Math.round((count / total) * 100) : 0,
      }))

    // Top issues by comment count (engagement = pain)
    const topIssues = [...targetIssues]
      .sort((a, b) => b.comments - a.comments)
      .slice(0, 10)

    // Trend: compare first half vs second half
    const midpoint = cutoff + (Date.now() - cutoff) / 2
    const firstHalf = targetIssues.filter((i) => new Date(i.createdAt).getTime() < midpoint).length
    const secondHalf = targetIssues.filter((i) => new Date(i.createdAt).getTime() >= midpoint).length
    const trend = secondHalf > firstHalf * 1.2 ? 'increasing' : secondHalf < firstHalf * 0.8 ? 'decreasing' : 'stable'

    // Pain score: frequency × recency weight
    const painScore = targetIssues.reduce((sum, issue) => {
      const ageMs = Date.now() - new Date(issue.createdAt).getTime()
      const ageDays = ageMs / (24 * 60 * 60 * 1000)
      const recencyWeight = Math.exp(-ageDays / 90)
      return sum + (1 + issue.comments * 0.5) * recencyWeight
    }, 0)

    // Log for trend tracking
    logIssuesAsComplaints(
      targetIssues.map((i) => ({
        number: i.number,
        title: i.title,
        category: i.category!,
        labels: i.labels,
      }))
    )

    const report = [
      `Pain Point Analysis (last ${days} days)`,
      `${'─'.repeat(40)}`,
      `Total issues analyzed: ${total}`,
      category ? `Focused category: ${category} (${targetIssues.length} issues)` : '',
      '',
      'Category Distribution:',
      ...categoryCounts.map((c) => `  ${c.category}: ${c.count} (${c.percentage}%)`),
      '',
      `Trend: ${trend}`,
      `Pain Score: ${painScore.toFixed(1)}`,
      '',
      'Top Issues (by engagement):',
      ...topIssues.map((i) =>
        `  #${i.number} [${i.comments} comments] ${i.title}`
      ),
    ].filter(Boolean).join('\n')

    return { content: [{ type: 'text' as const, text: report }] }
  }
)

// ─── Tool 3: issues_read ───

server.tool(
  'issues_read',
  'Read a single openclaw/openclaw issue with full details and comments.',
  {
    number: z.number().describe('Issue number'),
  },
  async ({ number }) => {
    const result = await getIssue(number)

    if (!result.ok || !result.data) {
      return { content: [{ type: 'text' as const, text: `Error: ${result.error || 'Issue not found'}` }] }
    }

    const raw = result.data as any
    const issue = normalizeIssue(raw)
    const comments = raw.comments?.nodes || raw.comments || []

    const commentText = Array.isArray(comments)
      ? comments.map((c: any) => {
          const author = c.author?.login || c.author || 'unknown'
          return `  @${author} (${c.createdAt}):\n  ${(c.body || '').slice(0, 500)}`
        }).join('\n\n')
      : '  No comments'

    const text = [
      `Issue #${issue.number}: ${issue.title}`,
      `State: ${issue.state} | Category: ${issue.category}`,
      `Labels: ${issue.labels.join(', ') || 'none'}`,
      `Created: ${issue.createdAt} | Updated: ${issue.updatedAt}`,
      `URL: ${issue.url}`,
      '',
      'Body:',
      (issue.body || '').slice(0, 2000),
      '',
      `Comments (${typeof raw.comments === 'number' ? raw.comments : comments.length}):`,
      commentText,
    ].join('\n')

    return { content: [{ type: 'text' as const, text }] }
  }
)

// ─── Tool 4: issues_report ───

server.tool(
  'issues_report',
  'Generate a pain point report for ClawInstaller prioritization. Analyzes openclaw/openclaw issues and produces actionable recommendations.',
  {
    format: z.enum(['summary', 'detailed']).optional().default('summary').describe('Report format'),
    period: z.enum(['week', 'month', 'quarter']).optional().default('month').describe('Analysis period'),
  },
  async ({ format, period }) => {
    // Gather data from multiple angles
    const installResult = await searchIssues('install error node', { state: 'all', limit: 50 })
    const configResult = await searchIssues('config setup', { state: 'all', limit: 50 })
    const channelResult = await searchIssues('telegram discord whatsapp', { state: 'all', limit: 50 })
    const daemonResult = await searchIssues('gateway daemon crash', { state: 'all', limit: 50 })

    const allRaw = [
      ...(installResult.data || []),
      ...(configResult.data || []),
      ...(channelResult.data || []),
      ...(daemonResult.data || []),
    ]

    // Deduplicate
    const seen = new Set<number>()
    const allIssues: GhIssue[] = []
    for (const raw of allRaw) {
      const issue = normalizeIssue(raw)
      if (!seen.has(issue.number)) {
        seen.add(issue.number)
        allIssues.push(issue)
      }
    }

    // Filter by period
    const periodDays = { week: 7, month: 30, quarter: 90 }[period]
    const cutoff = Date.now() - periodDays * 24 * 60 * 60 * 1000
    const filtered = allIssues.filter((i) => new Date(i.createdAt).getTime() > cutoff)

    // Category counts
    const catCounts = new Map<Category, number>()
    for (const issue of filtered) {
      const cat = issue.category || 'other'
      catCounts.set(cat, (catCounts.get(cat) || 0) + 1)
    }

    const total = filtered.length
    const sorted = [...catCounts.entries()].sort((a, b) => b[1] - a[1])

    // Historical comparison from complaint store
    const historicalComplaints = getComplaintsByPeriod(period === 'week' ? 'month' : 'quarter')
    const historicalDist = getComplaintDistribution(historicalComplaints)

    // Generate recommendations
    const recommendations: string[] = []
    const topCategory = sorted[0]?.[0]

    if (topCategory === 'installation') {
      recommendations.push('PRIORITY: Installation issues dominate — ClawInstaller Module 2 (one-click install) should be top priority')
      recommendations.push('Focus on Node.js version detection and auto-upgrade flow')
      recommendations.push('Add Sharp/native module pre-build check to Preflight')
    } else if (topCategory === 'config') {
      recommendations.push('PRIORITY: Configuration complexity is the top pain — visual config editor is high value')
      recommendations.push('Module 3 (Channel Setup) addresses this — validate and ship quickly')
    } else if (topCategory === 'channels') {
      recommendations.push('PRIORITY: Channel setup is the main pain point — Module 3 is well-positioned')
      recommendations.push('Add step-by-step token validation with live preview')
    } else if (topCategory === 'daemon') {
      recommendations.push('PRIORITY: Gateway/daemon issues are top — Module 4 (Health Monitor) should ship early')
      recommendations.push('Add auto-restart and log viewer to Health Monitor')
    }

    recommendations.push(
      `Data point: ${total} issues in last ${periodDays} days across ${sorted.length} categories`,
      `Historical complaints tracked: ${historicalComplaints.length} entries`
    )

    // Format report
    const catReport = sorted
      .map(([cat, count]) => {
        const pct = total > 0 ? Math.round((count / total) * 100) : 0
        const historical = historicalDist.get(cat) || 0
        const delta = historical > 0 ? ` (historical: ${historical})` : ''
        return `  ${cat}: ${count} (${pct}%)${delta}`
      })
      .join('\n')

    // Top 5 most-commented issues
    const hotIssues = [...filtered]
      .sort((a, b) => b.comments - a.comments)
      .slice(0, 5)
      .map((i) => `  #${i.number} [${i.category}] ${i.title} (${i.comments} comments)`)
      .join('\n')

    const reportLines = [
      `╔══════════════════════════════════════════╗`,
      `║  ClawInstaller Pain Point Report         ║`,
      `║  Period: last ${periodDays} days                    ║`,
      `╚══════════════════════════════════════════╝`,
      '',
      `Total issues analyzed: ${total}`,
      '',
      'Category Distribution:',
      catReport,
      '',
      'Hottest Issues:',
      hotIssues || '  No issues found in this period',
      '',
      'Recommendations:',
      ...recommendations.map((r) => `  → ${r}`),
    ]

    if (format === 'detailed') {
      reportLines.push(
        '',
        'All Issues by Category:',
        ...sorted.flatMap(([cat]) => {
          const catIssues = filtered.filter((i) => i.category === cat)
          return [
            `\n  [${cat.toUpperCase()}]`,
            ...catIssues.slice(0, 10).map((i) =>
              `    #${i.number} ${i.title} (${i.state}, ${i.comments} comments)`
            ),
          ]
        })
      )
    }

    return { content: [{ type: 'text' as const, text: reportLines.join('\n') }] }
  }
)

// ─── Helpers ───

function getCategoryQuery(category: Category): string {
  const queryMap: Record<string, string> = {
    installation: 'install npm node build error',
    config: 'config configuration setup env',
    channels: 'telegram discord whatsapp slack channel',
    daemon: 'gateway daemon process crash service',
    security: 'auth token permission security vulnerability',
    performance: 'slow memory CPU performance timeout',
  }
  return queryMap[category] || category
}

// ─── Start ───

async function main() {
  const transport = new StdioServerTransport()
  await server.connect(transport)
  console.error('gh-issues-tracker MCP server running on stdio')
}

main().catch((err) => {
  console.error('Fatal error:', err)
  process.exit(1)
})
