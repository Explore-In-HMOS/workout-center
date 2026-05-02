import { common } from '@kit.AbilityKit'
import { EMPTY_WORKOUT_STATS, WorkoutStats } from '../core/models/WorkoutModels'
import { TimerService } from '../core/services/TimerService'
import { WorkoutStorageService } from '../core/services/WorkoutStorageService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct IndexPage {
  @State workDuration: number = 15
  @State squatTarget: number = 15
  @State stats: WorkoutStats = EMPTY_WORKOUT_STATS
  @State hasHistory: boolean = false
  navPathStack: NavPathStack = new NavPathStack()
  private storage = WorkoutStorageService.getInstance()

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    this.storage.loadPreset(context).then((preset) => {
      this.workDuration = preset.durationSeconds
      this.squatTarget = preset.targetReps
    })
    this.storage.loadStats(context).then((stats) => {
      this.stats = stats
      this.hasHistory = stats.totalSessions > 0
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: ConstantUI.SIZE_12 }) {
          Column({ space: ConstantUI.SIZE_2 }) {
            Text($r('app.string.index_short_title'))
              .fontSize(ConstantUI.SIZE_28)
              .fontWeight(FontWeight.Bold)
              .fontColor(ConstantUI.WATCH_TEXT)
              .textAlign(TextAlign.Center)

            Text($r('app.string.squat_trainer'))
              .fontSize(ConstantUI.SIZE_16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ConstantUI.WATCH_MUTED)
              .textAlign(TextAlign.Center)
          }
          .margin({ top: ConstantUI.SIZE_6, bottom: ConstantUI.SIZE_4 })

          if (this.hasHistory) {
            Row({ space: ConstantUI.SIZE_8 }) {
              this.MiniStat(
                $r('app.string.progress_streak'),
                $r('app.string.progress_streak_days', this.stats.currentStreak)
              )
              this.MiniStat($r('app.string.progress_week'), `${this.stats.weeklyReps}`)
            }
          }

          this.DurationStepper()

          this.SquatStepper()

          Button($r('app.string.main_start'))
            .fontSize(ConstantUI.SIZE_16)
            .fontWeight(FontWeight.Bold)
            .width(ConstantUI.BUTTON_WIDTH)
            .height(ConstantUI.SIZE_42)
            .borderRadius(ConstantUI.SIZE_24)
            .backgroundColor(ConstantUI.WATCH_ORANGE)
            .fontColor(ConstantUI.TEXT_WHITE)
            .margin({ top: ConstantUI.SIZE_4 })
            .onClick(() => {
              if (this.workDuration > 0 && this.squatTarget > 0) {
                const timer = TimerService.getInstance()
                timer.setTime(this.workDuration)
                timer.setTarget(this.squatTarget)
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext
                this.storage.savePreset(context, {
                  durationSeconds: this.workDuration,
                  targetReps: this.squatTarget
                })
                this.navPathStack.pushPath({ name: 'MainPage' })
              }
            })

          Button($r('app.string.index_progress'))
            .fontSize(ConstantUI.SIZE_14)
            .fontWeight(FontWeight.Medium)
            .width(ConstantUI.BUTTON_WIDTH)
            .height(ConstantUI.SIZE_36)
            .borderRadius(ConstantUI.SIZE_20)
            .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
            .fontColor(ConstantUI.WATCH_TEXT)
            .onClick(() => {
              this.navPathStack.pushPath({ name: 'ProgressPage' })
            })
        }
        .padding({
          left: ConstantUI.SIZE_20,
          right: ConstantUI.SIZE_20,
          top: ConstantUI.SIZE_20,
          bottom: ConstantUI.SIZE_24
        })
        .width(ConstantUI.FULL_WIDTH)
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
  DurationStepper() {
    Column({ space: ConstantUI.SIZE_8 }) {
      Text($r('app.string.index_seconds_label'))
        .fontSize(ConstantUI.SIZE_12)
        .fontColor(ConstantUI.WATCH_MUTED)
        .fontWeight(FontWeight.Medium)

      Row({ space: ConstantUI.SIZE_10 }) {
        Button($r('app.string.control_minus'))
          .fontSize(ConstantUI.SIZE_20)
          .fontWeight(FontWeight.Bold)
          .width(ConstantUI.SIZE_40)
          .height(ConstantUI.SIZE_40)
          .borderRadius(ConstantUI.SIZE_20)
          .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
          .fontColor(ConstantUI.WATCH_TEXT)
          .onClick(() => {
            this.workDuration = Math.max(5, this.workDuration - 5)
          })

        Text(`${this.workDuration}`)
          .fontSize(ConstantUI.SIZE_32)
          .fontWeight(FontWeight.Bold)
          .fontColor(ConstantUI.WATCH_TEXT)
          .textAlign(TextAlign.Center)
          .width(ConstantUI.SIZE_72)

        Button($r('app.string.control_plus'))
          .fontSize(ConstantUI.SIZE_20)
          .fontWeight(FontWeight.Bold)
          .width(ConstantUI.SIZE_40)
          .height(ConstantUI.SIZE_40)
          .borderRadius(ConstantUI.SIZE_20)
          .backgroundColor(ConstantUI.WATCH_TEAL)
          .fontColor(ConstantUI.TEXT_WHITE)
          .onClick(() => {
            this.workDuration = Math.min(600, this.workDuration + 5)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width(ConstantUI.FULL_WIDTH_90)
    .padding({ top: ConstantUI.SIZE_10, bottom: ConstantUI.SIZE_10 })
    .borderRadius(ConstantUI.SIZE_24)
    .backgroundColor(ConstantUI.WATCH_PANEL)
  }

  @Builder
  SquatStepper() {
    Column({ space: ConstantUI.SIZE_8 }) {
      Text($r('app.string.index_squats_label'))
        .fontSize(ConstantUI.SIZE_12)
        .fontColor(ConstantUI.WATCH_MUTED)
        .fontWeight(FontWeight.Medium)

      Row({ space: ConstantUI.SIZE_10 }) {
        Button($r('app.string.control_minus'))
          .fontSize(ConstantUI.SIZE_20)
          .fontWeight(FontWeight.Bold)
          .width(ConstantUI.SIZE_40)
          .height(ConstantUI.SIZE_40)
          .borderRadius(ConstantUI.SIZE_20)
          .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
          .fontColor(ConstantUI.WATCH_TEXT)
          .onClick(() => {
            this.squatTarget = Math.max(1, this.squatTarget - 1)
          })

        Text(`${this.squatTarget}`)
          .fontSize(ConstantUI.SIZE_32)
          .fontWeight(FontWeight.Bold)
          .fontColor(ConstantUI.WATCH_TEXT)
          .textAlign(TextAlign.Center)
          .width(ConstantUI.SIZE_72)

        Button($r('app.string.control_plus'))
          .fontSize(ConstantUI.SIZE_20)
          .fontWeight(FontWeight.Bold)
          .width(ConstantUI.SIZE_40)
          .height(ConstantUI.SIZE_40)
          .borderRadius(ConstantUI.SIZE_20)
          .backgroundColor(ConstantUI.WATCH_TEAL)
          .fontColor(ConstantUI.TEXT_WHITE)
          .onClick(() => {
            this.squatTarget = Math.min(300, this.squatTarget + 1)
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width(ConstantUI.FULL_WIDTH_90)
    .padding({ top: ConstantUI.SIZE_10, bottom: ConstantUI.SIZE_10 })
    .borderRadius(ConstantUI.SIZE_24)
    .backgroundColor(ConstantUI.WATCH_PANEL)
  }

  @Builder
  MiniStat(label: ResourceStr, value: ResourceStr) {
    Column({ space: ConstantUI.SIZE_2 }) {
      Text(value)
        .fontSize(ConstantUI.SIZE_16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ConstantUI.WATCH_TEXT)
      Text(label)
        .fontSize(ConstantUI.SIZE_10)
        .fontColor(ConstantUI.WATCH_MUTED)
    }
    .width(ConstantUI.SIZE_72)
    .height(ConstantUI.SIZE_48)
    .justifyContent(FlexAlign.Center)
    .borderRadius(ConstantUI.SIZE_24)
    .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
  }
}
