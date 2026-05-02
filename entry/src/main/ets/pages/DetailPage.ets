import { common } from '@kit.AbilityKit'
import { WorkoutSession } from '../core/models/WorkoutModels'
import { HapticCue, HapticService } from '../core/services/HapticService'
import { ReminderService } from '../core/services/ReminderService'
import { TimerService } from '../core/services/TimerService'
import { WorkoutStorageService } from '../core/services/WorkoutStorageService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct DetailPage {
  @State reminderStatus: number = 0
  private timerService = TimerService.getInstance()
  private storage = WorkoutStorageService.getInstance()
  private reminderService = ReminderService.getInstance()
  private haptics = HapticService.getInstance()
  private didSave: boolean = false
  navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear() {
    if (this.didSave) {
      return
    }
    this.didSave = true

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    const session: WorkoutSession = {
      id: `${Date.now()}`,
      completedAt: Date.now(),
      durationSeconds: this.timerService.totalSeconds,
      elapsedSeconds: Math.max(0, this.timerService.totalSeconds - this.timerService.remainingSeconds),
      targetReps: this.timerService.targetRepCount,
      completedReps: this.timerService.repCount,
      completedGoal: this.timerService.repCount >= this.timerService.targetRepCount
    }
    this.storage.saveSession(context, session)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: ConstantUI.SIZE_12 }) {
          Gauge({
            value: this.timerService.repCount,
            min: 0,
            max: Math.max(1, this.timerService.targetRepCount)
          }) {
            Column({ space: ConstantUI.SIZE_2 }) {
              Text($r('app.string.detail_completion_percent', this.completionRate()))
                .fontSize(ConstantUI.SIZE_32)
                .fontWeight(FontWeight.Bold)
                .fontColor(ConstantUI.WATCH_TEXT)
              Text($r('app.string.detail_complete_label'))
                .fontSize(ConstantUI.SIZE_12)
                .fontColor(ConstantUI.WATCH_MUTED)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
          .colors(
            this.timerService.repCount >= this.timerService.targetRepCount
              ? ConstantUI.WATCH_TEAL
              : ConstantUI.WATCH_ORANGE
          )
          .width(ConstantUI.SIZE_150)
          .height(ConstantUI.SIZE_110)
          .indicator(null)
          .strokeWidth(ConstantUI.SIZE_10)

          Text($r('app.string.detail_squats_summary', this.timerService.repCount, this.timerService.targetRepCount))
            .fontSize(ConstantUI.SIZE_20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ConstantUI.WATCH_TEXT)

          Text(this.getMotivationMessage())
            .fontSize(ConstantUI.SIZE_14)
            .fontColor(ConstantUI.WATCH_MUTED)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .width(ConstantUI.FULL_WIDTH_90)
            .maxLines(3)

          Row({ space: ConstantUI.SIZE_8 }) {
            Button($r('app.string.detail_restart'))
              .fontSize(ConstantUI.SIZE_12)
              .width(ConstantUI.SIZE_88)
              .height(ConstantUI.SIZE_40)
              .borderRadius(ConstantUI.SIZE_20)
              .backgroundColor(ConstantUI.WATCH_ORANGE)
              .fontColor(ConstantUI.TEXT_WHITE)
              .onClick(() => {
                this.timerService.reset()
                this.navPathStack.clear()
                this.navPathStack.pushPath({ name: 'Index' })
              })

            Button($r('app.string.detail_stats'))
              .fontSize(ConstantUI.SIZE_12)
              .width(ConstantUI.SIZE_64)
              .height(ConstantUI.SIZE_40)
              .borderRadius(ConstantUI.SIZE_20)
              .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
              .fontColor(ConstantUI.WATCH_TEXT)
              .onClick(() => {
                this.navPathStack.pushPath({ name: 'ProgressPage' })
              })
          }

          Button($r('app.string.remind_tomorrow'))
            .fontSize(ConstantUI.SIZE_12)
            .width(ConstantUI.BUTTON_WIDTH)
            .height(ConstantUI.SIZE_36)
            .borderRadius(ConstantUI.SIZE_18)
            .backgroundColor(ConstantUI.WATCH_PANEL)
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

  private completionRate(): number {
    if (this.timerService.targetRepCount <= 0) {
      return 0
    }
    return Math.min(100, Math.round((this.timerService.repCount / this.timerService.targetRepCount) * 100))
  }

  private getMotivationMessage() {
    const completed = this.timerService.repCount
    const target = this.timerService.targetRepCount

    if (completed >= target) {
      return $r('app.string.motivation_goal_complete')
    } else if (completed >= target * 0.75) {
      return $r('app.string.motivation_close')
    } else if (completed >= target * 0.5) {
      return $r('app.string.motivation_halfway')
    } else if (completed > 0) {
      return $r('app.string.motivation_started')
    }
    return $r('app.string.motivation_none')
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
