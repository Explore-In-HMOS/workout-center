import { sensor } from '@kit.SensorServiceKit'
import { SquatDetector } from '../core/motion/SquatDetector'
import { HapticCue, HapticService } from '../core/services/HapticService'
import { TimerService, TimerStatus } from '../core/services/TimerService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct MainPage {
  @State status: TimerStatus = TimerStatus.STOPPED
  private timerService = TimerService.getInstance()
  private detector: SquatDetector = new SquatDetector()
  private haptics: HapticService = HapticService.getInstance()
  private lastCountdownPulse: number = -1
  navPathStack: NavPathStack = new NavPathStack()

  aboutToDisappear() {
    this.stopSensor()
  }

  build() {
    NavDestination() {
      Gauge({
        value: this.timerService.remainingSeconds,
        min: 0,
        max: this.timerService.totalSeconds
      }) {
        Column({ space: ConstantUI.SIZE_8 }) {
          Text(this.statusText())
            .fontSize(ConstantUI.SIZE_12)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              this.status === TimerStatus.RUNNING ? ConstantUI.WATCH_TEAL : ConstantUI.WATCH_MUTED
            )

          Text(this.formatTime(this.timerService.remainingSeconds))
            .fontSize(ConstantUI.SIZE_40)
            .fontWeight(FontWeight.Bold)
            .fontColor(ConstantUI.WATCH_TEXT)

          Column({ space: ConstantUI.SIZE_2 }) {
            Text(`${this.timerService.repCount}`)
              .fontSize(ConstantUI.SIZE_36)
              .fontWeight(FontWeight.Bold)
              .fontColor(ConstantUI.WATCH_ORANGE)
            Text($r('app.string.main_target_reps', this.timerService.targetRepCount))
              .fontSize(ConstantUI.SIZE_12)
              .fontColor(ConstantUI.WATCH_MUTED)
          }

          Row({ space: ConstantUI.SIZE_6 }) {
            Button(
              this.status === TimerStatus.RUNNING ? $r('app.string.main_pause') : $r('app.string.main_start')
            )
              .fontSize(ConstantUI.SIZE_12)
              .fontWeight(FontWeight.Bold)
              .width(ConstantUI.SIZE_72)
              .height(ConstantUI.SIZE_36)
              .borderRadius(ConstantUI.SIZE_18)
              .backgroundColor(
                this.status === TimerStatus.RUNNING ? ConstantUI.WATCH_PANEL_ALT : ConstantUI.WATCH_TEAL
              )
              .fontColor(ConstantUI.TEXT_WHITE)
              .onClick(() => {
                if (this.status === TimerStatus.RUNNING) {
                  this.timerService.pause()
                  this.status = TimerStatus.PAUSED
                  this.stopSensor()
                  this.haptics.pulse(HapticCue.PAUSE)
                } else {
                  this.prepareWorkoutCallbacks()
                  this.timerService.start()
                  this.status = TimerStatus.RUNNING
                  this.haptics.pulse(HapticCue.START)
                  this.startSensor()
                }
              })

            Button($r('app.string.main_reset'))
              .fontSize(ConstantUI.SIZE_10)
              .fontWeight(FontWeight.Medium)
              .width(ConstantUI.SIZE_58)
              .height(ConstantUI.SIZE_36)
              .borderRadius(ConstantUI.SIZE_18)
              .backgroundColor(ConstantUI.WATCH_PANEL_ALT)
              .fontColor(ConstantUI.WATCH_TEXT)
              .onClick(() => {
                this.timerService.reset()
                this.status = TimerStatus.STOPPED
                this.stopSensor()
                this.detector.reset()
                this.haptics.pulse(HapticCue.RESET)
              })
          }
        }
        .padding(ConstantUI.SIZE_16)
        .width(ConstantUI.FULL_WIDTH)
        .height(ConstantUI.FULL_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [ConstantUI.WATCH_BG_TOP, 0.0],
            [ConstantUI.WATCH_BG_BOTTOM, 1.0]
          ]
        })
      }
      .colors(ConstantUI.WATCH_TEAL)
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
      .indicator(null)
      .strokeWidth(ConstantUI.SIZE_12)
      .trackShadow({ radius: 1, offsetX: 0, offsetY: 0 })
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack
    })
  }

  private prepareWorkoutCallbacks(): void {
    this.lastCountdownPulse = -1
    this.timerService.setOnTimerFinish(() => {
      this.status = TimerStatus.STOPPED
      this.stopSensor()
      this.haptics.pulse(HapticCue.COMPLETE)
      this.navPathStack.pushPath({ name: 'DetailPage' })
    })

    this.timerService.setOnRepsComplete(() => {
      this.status = TimerStatus.STOPPED
      this.stopSensor()
      this.haptics.pulse(HapticCue.COMPLETE)
      this.navPathStack.pushPath({ name: 'DetailPage' })
    })

    this.timerService.setOnTick((remainingSeconds: number) => {
      if (
        remainingSeconds > 0 &&
        remainingSeconds <= 5 &&
        remainingSeconds !== this.lastCountdownPulse
      ) {
        this.lastCountdownPulse = remainingSeconds
        this.haptics.pulse(HapticCue.MILESTONE)
      }
    })
  }

  startSensor() {
    try {
      this.detector.reset()
      sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
        const now = Date.now()
        if (this.timerService.status === TimerStatus.RUNNING && this.detector.accept(data.z, now)) {
          const changed = this.timerService.incrementRep()
          if (changed) {
            const halfway = Math.ceil(this.timerService.targetRepCount / 2)
            if (
              this.timerService.repCount === halfway ||
              this.timerService.repCount === this.timerService.targetRepCount
            ) {
              this.haptics.pulse(HapticCue.MILESTONE)
            } else {
              this.haptics.pulse(HapticCue.REP)
            }
          }
        }
      })
    } catch (err) {
      console.error('[SENSOR ERROR]', JSON.stringify(err))
    }
  }

  stopSensor() {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER)
    } catch (err) {
      console.error('[SENSOR OFF ERROR]', JSON.stringify(err))
    }
  }

  private statusText() {
    if (this.status === TimerStatus.RUNNING) {
      return $r('app.string.main_status_active')
    }
    if (this.status === TimerStatus.PAUSED) {
      return $r('app.string.main_status_paused')
    }
    return $r('app.string.main_status_ready')
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / ConstantUI.CONST_60).toString().padStart(2, '0')
    const secs = (seconds % ConstantUI.CONST_60).toString().padStart(2, '0')
    return `${mins}:${secs}`
  }
}
