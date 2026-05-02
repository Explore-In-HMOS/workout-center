import { common } from '@kit.AbilityKit'
import { EMPTY_WORKOUT_STATS, WorkoutSession, WorkoutStats } from '../core/models/WorkoutModels'
import { HapticCue, HapticService } from '../core/services/HapticService'
import { ReminderService } from '../core/services/ReminderService'
import { WorkoutStorageService } from '../core/services/WorkoutStorageService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct ProgressPage {
  @State stats: WorkoutStats = EMPTY_WORKOUT_STATS
  @State history: WorkoutSession[] = []
  @State reminderStatus: number = 0
  navPathStack: NavPathStack = new NavPathStack()
  private storage = WorkoutStorageService.getInstance()
  private reminderService = ReminderService.getInstance()
  private haptics = HapticService.getInstance()

  aboutToAppear() {
    this.refresh()
  }

  private refresh(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    this.storage.loadHistory(context).then((history) => {
      this.history = history
      this.stats = this.storage.calculateStats(history)
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: ConstantUI.SIZE_10 }) {
          Text($r('app.string.progress_title'))
            .fontSize(ConstantUI.SIZE_24)
            .fontWeight(FontWeight.Bold)
            .fontColor(ConstantUI.WATCH_TEXT)

          Row({ space: ConstantUI.SIZE_8 }) {
            this.StatPill($r('app.string.progress_sessions'), `${this.stats.totalSessions}`)
            this.StatPill(
              $r('app.string.progress_streak'),
              $r('app.string.progress_streak_days', this.stats.currentStreak)
            )
          }

          Row({ space: ConstantUI.SIZE_8 }) {
            this.StatPill($r('app.string.progress_week'), `${this.stats.weeklyReps}`)
            this.StatPill($r('app.string.progress_best'), `${this.stats.bestReps}`)
          }

          Column({ space: ConstantUI.SIZE_2 }) {
            Text(`${this.stats.totalReps}`)
              .fontSize(ConstantUI.SIZE_32)
              .fontWeight(FontWeight.Bold)
              .fontColor(ConstantUI.WATCH_ORANGE)
            Text($r('app.string.progress_total_best', this.stats.bestCompletionRate))
              .fontSize(ConstantUI.SIZE_12)
              .fontColor(ConstantUI.WATCH_MUTED)
          }
          .width(ConstantUI.FULL_WIDTH_90)
          .padding({ top: ConstantUI.SIZE_10, bottom: ConstantUI.SIZE_10 })
          .borderRadius(ConstantUI.SIZE_24)
          .backgroundColor(ConstantUI.WATCH_PANEL)

          if (this.history.length > 0) {
            ForEach(this.history.slice(0, 4), (session: WorkoutSession) => {
              this.SessionRow(session)
            }, (session: WorkoutSession) => session.id)
          } else {
            Text($r('app.string.progress_no_sessions'))
              .fontSize(ConstantUI.SIZE_14)
              .fontColor(ConstantUI.WATCH_MUTED)
              .margin({ top: ConstantUI.SIZE_8, bottom: ConstantUI.SIZE_8 })
          }

          Button($r('app.string.remind_tomorrow'))
            .fontSize(ConstantUI.SIZE_12)
            .width(ConstantUI.BUTTON_WIDTH)
            .height(ConstantUI.SIZE_36)
            .borderRadius(ConstantUI.SIZE_18)
            .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
            .fontColor(ConstantUI.WATCH_TEXT)
            .onClick(() => {
              const context = this.getUIContext().getHostContext() as common.UIAbilityContext
              this.reminderStatus = 1
              this.reminderService.scheduleTomorrow(context).then(() => {
                this.reminderStatus = 2
                this.haptics.pulse(HapticCue.MILESTONE)
              }).catch((err: Error) => {
                this.reminderStatus = 3
                console.error('[REMINDER ERROR]', JSON.stringify(err))
              })
            })

          if (this.reminderStatus !== 0) {
            Text(this.reminderStatusText())
              .fontSize(ConstantUI.SIZE_12)
              .fontColor(ConstantUI.WATCH_TEAL)
          }

          Button($r('app.string.progress_back'))
            .fontSize(ConstantUI.SIZE_12)
            .width(ConstantUI.SIZE_88)
            .height(ConstantUI.SIZE_36)
            .borderRadius(ConstantUI.SIZE_18)
            .backgroundColor(ConstantUI.WATCH_ORANGE)
            .fontColor(ConstantUI.TEXT_WHITE)
            .onClick(() => {
              this.navPathStack.pop()
            })
        }
        .padding({
          left: ConstantUI.SIZE_18,
          right: ConstantUI.SIZE_18,
          top: ConstantUI.SIZE_18,
          bottom: ConstantUI.SIZE_24
        })
        .alignItems(HorizontalAlign.Center)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [ConstantUI.WATCH_BG_TOP, 0.0],
            [ConstantUI.WATCH_BG_BOTTOM, 1.0]
          ]
        })
      }
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
      .backgroundColor(ConstantUI.WATCH_BG_BOTTOM)
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack
    })
  }

  @Builder
  StatPill(label: ResourceStr, value: ResourceStr) {
    Column({ space: ConstantUI.SIZE_2 }) {
      Text(value)
        .fontSize(ConstantUI.SIZE_18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ConstantUI.WATCH_TEXT)
      Text(label)
        .fontSize(ConstantUI.SIZE_10)
        .fontColor(ConstantUI.WATCH_MUTED)
    }
    .width(ConstantUI.SIZE_88)
    .height(ConstantUI.SIZE_58)
    .justifyContent(FlexAlign.Center)
    .borderRadius(ConstantUI.SIZE_28)
    .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
  }

  @Builder
  SessionRow(session: WorkoutSession) {
    Row() {
      Column({ space: ConstantUI.SIZE_2 }) {
        Text(this.formatDate(session.completedAt))
          .fontSize(ConstantUI.SIZE_12)
          .fontColor(ConstantUI.WATCH_MUTED)
        Text($r('app.string.progress_rate_percent', this.completionRate(session)))
          .fontSize(ConstantUI.SIZE_10)
          .fontColor(session.completedGoal ? ConstantUI.WATCH_TEAL : ConstantUI.WATCH_ORANGE)
      }
      .width(ConstantUI.SIZE_48)

      Text($r('app.string.session_reps_summary', session.completedReps, session.targetReps))
        .fontSize(ConstantUI.SIZE_18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ConstantUI.WATCH_TEXT)
        .textAlign(TextAlign.Center)
        .width(ConstantUI.SIZE_72)

      Text($r('app.string.session_elapsed_seconds', session.elapsedSeconds))
        .fontSize(ConstantUI.SIZE_12)
        .fontColor(ConstantUI.WATCH_MUTED)
        .textAlign(TextAlign.End)
        .width(ConstantUI.SIZE_48)
    }
    .width(ConstantUI.FULL_WIDTH_90)
    .height(ConstantUI.SIZE_42)
    .padding({ left: ConstantUI.SIZE_12, right: ConstantUI.SIZE_12 })
    .borderRadius(ConstantUI.SIZE_20)
    .backgroundColor(ConstantUI.WATCH_PANEL)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private completionRate(session: WorkoutSession): number {
    if (session.targetReps <= 0) {
      return 0
    }
    return Math.min(100, Math.round((session.completedReps / session.targetReps) * 100))
  }

  private formatDate(time: number) {
    const date = new Date(time)
    return $r('app.string.session_date_short', date.getMonth() + 1, date.getDate())
  }

  private reminderStatusText() {
    if (this.reminderStatus === 1) {
      return $r('app.string.reminder_scheduling')
    }
    if (this.reminderStatus === 2) {
      return $r('app.string.reminder_set')
    }
    return $r('app.string.reminder_unavailable')
  }
}
