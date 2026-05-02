export enum TimerStatus {
  STOPPED,
  RUNNING,
  PAUSED
}

@ObservedV2
export class TimerService {
  @Trace totalSeconds: number = 0
  @Trace remainingSeconds: number = 0
  @Trace repCount: number = 0
  @Trace targetRepCount: number = 0

  private intervalId: number | undefined
  private _status: TimerStatus = TimerStatus.STOPPED
  static _instance: TimerService

  private onTimerFinishCallback?: () => void
  private onRepsCompleteCallback?: () => void
  private onTickCallback?: (remainingSeconds: number) => void

  static getInstance() {
    if (!TimerService._instance) {
      TimerService._instance = new TimerService()
    }
    return TimerService._instance
  }

  constructor(defaultTime: number = 1500) {
    this.totalSeconds = defaultTime
    this.remainingSeconds = defaultTime
  }

  setTime(totalSeconds: number) {
    this.totalSeconds = totalSeconds
    this.remainingSeconds = totalSeconds
    this.repCount = 0
  }

  setTarget(target: number) {
    this.targetRepCount = target
  }

  setOnTimerFinish(callback: () => void) {
    this.onTimerFinishCallback = callback
  }

  setOnRepsComplete(callback: () => void) {
    this.onRepsCompleteCallback = callback
  }

  setOnTick(callback: (remainingSeconds: number) => void) {
    this.onTickCallback = callback
  }

  incrementRep(): boolean {
    let changed = false
    if (this.repCount < this.targetRepCount) {
      this.repCount++
      changed = true
    }

    if (this.repCount >= this.targetRepCount) {
      this.stop()
      if (this.onRepsCompleteCallback) {
        this.onRepsCompleteCallback()
      }
    }
    return changed
  }

  get status(): TimerStatus {
    return this._status
  }

  start() {
    if (this._status === TimerStatus.RUNNING) {return}

    this._status = TimerStatus.RUNNING
    this.intervalId = setInterval(() => {
      if (this.remainingSeconds > 0) {
        this.remainingSeconds--
        if (this.onTickCallback) {
          this.onTickCallback(this.remainingSeconds)
        }
      }

      if (this.remainingSeconds <= 0) {
        this.stop()
        if (this.onTimerFinishCallback) {
          this.onTimerFinishCallback()
        }
      }
    }, 1000)
  }

  pause() {
    if (this._status === TimerStatus.RUNNING) {
      clearInterval(this.intervalId)
      this._status = TimerStatus.PAUSED
    }
  }

  resume() {
    if (this._status === TimerStatus.PAUSED) {
      this.start()
    }
  }

  reset() {
    this.stop()
    this.remainingSeconds = this.totalSeconds
    this.repCount = 0
  }

  stop() {
    clearInterval(this.intervalId)
    this.intervalId = undefined
    this._status = TimerStatus.STOPPED
  }
}
