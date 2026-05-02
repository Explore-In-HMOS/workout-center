import { preferences } from '@kit.ArkData'
import {
  EMPTY_WORKOUT_STATS,
  WorkoutPreset,
  WorkoutSession,
  WorkoutStats
} from '../models/WorkoutModels'

const STORE_NAME = 'workout_center_store'
const KEY_HISTORY = 'history'
const KEY_PRESET_DURATION = 'preset_duration'
const KEY_PRESET_TARGET = 'preset_target'
const KEY_REMINDER_ID = 'reminder_id'
const MAX_HISTORY_ITEMS = 40

export class WorkoutStorageService {
  private static instance: WorkoutStorageService
  private readonly dayKeyDate: Date = new Date(0)

  static getInstance(): WorkoutStorageService {
    if (!WorkoutStorageService.instance) {
      WorkoutStorageService.instance = new WorkoutStorageService()
    }
    return WorkoutStorageService.instance
  }

  async loadPreset(context: Context): Promise<WorkoutPreset> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    const duration = Number(await store.get(KEY_PRESET_DURATION, 15))
    const target = Number(await store.get(KEY_PRESET_TARGET, 15))
    return {
      durationSeconds: duration > 0 ? duration : 15,
      targetReps: target > 0 ? target : 15
    }
  }

  async savePreset(context: Context, preset: WorkoutPreset): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    await store.put(KEY_PRESET_DURATION, preset.durationSeconds)
    await store.put(KEY_PRESET_TARGET, preset.targetReps)
    await store.flush()
  }

  async loadHistory(context: Context): Promise<WorkoutSession[]> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    const raw = String(await store.get(KEY_HISTORY, '[]'))
    try {
      const parsed = JSON.parse(raw) as WorkoutSession[]
      return parsed.sort((left: WorkoutSession, right: WorkoutSession) => right.completedAt - left.completedAt)
    } catch (err) {
      console.error('[WORKOUT HISTORY PARSE ERROR]', JSON.stringify(err))
      return []
    }
  }

  async saveSession(context: Context, session: WorkoutSession): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    const history = await this.loadHistory(context)
    const nextHistory = [session, ...history]
      .sort((left: WorkoutSession, right: WorkoutSession) => right.completedAt - left.completedAt)
      .slice(0, MAX_HISTORY_ITEMS)

    await store.put(KEY_HISTORY, JSON.stringify(nextHistory))
    await store.flush()
  }

  async clearHistory(context: Context): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    await store.put(KEY_HISTORY, '[]')
    await store.flush()
  }

  async loadStats(context: Context): Promise<WorkoutStats> {
    const history = await this.loadHistory(context)
    return this.calculateStats(history)
  }

  calculateStats(history: WorkoutSession[]): WorkoutStats {
    if (history.length === 0) {
      return EMPTY_WORKOUT_STATS
    }

    const now = Date.now()
    const weekStart = now - 7 * 24 * 60 * 60 * 1000
    let totalReps = 0
    let bestReps = 0
    let bestCompletionRate = 0
    let weeklyReps = 0

    history.forEach((session: WorkoutSession) => {
      totalReps += session.completedReps
      bestReps = Math.max(bestReps, session.completedReps)
      if (session.targetReps > 0) {
        bestCompletionRate = Math.max(bestCompletionRate, session.completedReps / session.targetReps)
      }
      if (session.completedAt >= weekStart) {
        weeklyReps += session.completedReps
      }
    })

    return {
      totalSessions: history.length,
      totalReps: totalReps,
      bestReps: bestReps,
      bestCompletionRate: Math.min(100, Math.round(bestCompletionRate * 100)),
      currentStreak: this.calculateCurrentStreak(history),
      weeklyReps: weeklyReps,
      lastSessionReps: history[0].completedReps
    }
  }

  async saveReminderId(context: Context, reminderId: number): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    await store.put(KEY_REMINDER_ID, reminderId)
    await store.flush()
  }

  async loadReminderId(context: Context): Promise<number> {
    const store = await preferences.getPreferences(context, STORE_NAME)
    return Number(await store.get(KEY_REMINDER_ID, -1))
  }

  private calculateCurrentStreak(history: WorkoutSession[]): number {
    const completedDays: string[] = []
    history.forEach((session: WorkoutSession) => {
      const key = this.getDayKey(session.completedAt)
      if (completedDays.indexOf(key) < 0) {
        completedDays.push(key)
      }
    })

    let streak = 0
    const cursor = new Date()
    for (let i = 0; i < 365; i++) {
      const key = this.getDayKey(cursor.getTime())
      if (completedDays.indexOf(key) < 0) {
        break
      }
      streak++
      cursor.setDate(cursor.getDate() - 1)
    }
    return streak
  }

  private getDayKey(time: number): string {
    this.dayKeyDate.setTime(time)
    const date = this.dayKeyDate
    return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
  }
}
