export interface WorkoutPreset {
  durationSeconds: number
  targetReps: number
}

export interface WorkoutSession {
  id: string
  completedAt: number
  durationSeconds: number
  elapsedSeconds: number
  targetReps: number
  completedReps: number
  completedGoal: boolean
}

export interface WorkoutStats {
  totalSessions: number
  totalReps: number
  bestReps: number
  bestCompletionRate: number
  currentStreak: number
  weeklyReps: number
  lastSessionReps: number
}

export const EMPTY_WORKOUT_STATS: WorkoutStats = {
  totalSessions: 0,
  totalReps: 0,
  bestReps: 0,
  bestCompletionRate: 0,
  currentStreak: 0,
  weeklyReps: 0,
  lastSessionReps: 0
}
