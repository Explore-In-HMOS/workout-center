import { vibrator } from '@kit.SensorServiceKit'

export enum HapticCue {
  START,
  PAUSE,
  REP,
  MILESTONE,
  COMPLETE,
  RESET
}

export class HapticService {
  private static instance: HapticService
  private lastPulseAt: number = 0

  static getInstance(): HapticService {
    if (!HapticService.instance) {
      HapticService.instance = new HapticService()
    }
    return HapticService.instance
  }

  pulse(cue: HapticCue): void {
    const now = Date.now()
    if (now - this.lastPulseAt < 120) {
      return
    }
    this.lastPulseAt = now

    const duration = this.getDuration(cue)
    vibrator.startVibration({
      type: 'time',
      duration: duration
    }, {
      usage: cue === HapticCue.COMPLETE ? 'notification' : 'touch'
    }).catch((err: Error) => {
      console.error('[HAPTIC ERROR]', JSON.stringify(err))
    })
  }

  private getDuration(cue: HapticCue): number {
    if (cue === HapticCue.START || cue === HapticCue.REP) {
      return 35
    }
    if (cue === HapticCue.PAUSE || cue === HapticCue.RESET) {
      return 55
    }
    if (cue === HapticCue.MILESTONE) {
      return 85
    }
    return 140
  }
}
