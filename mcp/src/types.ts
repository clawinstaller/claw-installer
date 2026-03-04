// Shared interfaces for gh-issues-tracker MCP

export type Category =
  | 'installation'
  | 'config'
  | 'channels'
  | 'daemon'
  | 'security'
  | 'performance'
  | 'other'

export interface GhIssue {
  number: number
  title: string
  body: string
  state: string
  labels: string[]
  createdAt: string
  updatedAt: string
  comments: number
  url: string
  category?: Category
}

export interface GhIssueDetail extends GhIssue {
  bodyText: string
  commentsList: GhComment[]
}

export interface GhComment {
  author: string
  body: string
  createdAt: string
}

export interface GhResult<T = unknown> {
  ok: boolean
  data: T | null
  error?: string
}

export interface CacheEntry<T = unknown> {
  data: T
  timestamp: number
  ttl: number
}

export interface CategoryCount {
  category: Category
  count: number
  percentage: number
}

export interface PainScore {
  category: Category
  score: number
  topIssues: { number: number; title: string; comments: number }[]
  trend: 'increasing' | 'stable' | 'decreasing'
}

export interface ComplaintEntry {
  timestamp: string
  issueNumber: number
  title: string
  category: Category
  labels: string[]
}

export interface AnalysisResult {
  categoryCounts: CategoryCount[]
  topIssues: GhIssue[]
  trend: 'increasing' | 'stable' | 'decreasing'
  painScore: number
  totalAnalyzed: number
  period: string
}

export interface ReportResult {
  reportText: string
  categories: CategoryCount[]
  recommendations: string[]
  dataPoints: number
}
