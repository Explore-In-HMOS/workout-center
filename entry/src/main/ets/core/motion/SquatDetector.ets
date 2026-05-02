export class SquatDetector {
  private baselineZ: number = 0
  private smoothedZ: number = 0
  private sampleCount: number = 0
  private isDown: boolean = false
  private lastRepAt: number = 0
  private lastSampleAt: number = 0
  private readonly downThreshold: number = -1.45
  private readonly upThreshold: number = 1.3
  private readonly minRepIntervalMs: number = 650
  private readonly maxSampleGapMs: number = 2200

  reset(): void {
    this.baselineZ = 0
    this.smoothedZ = 0
    this.sampleCount = 0
    this.isDown = false
    this.lastRepAt = 0
    this.lastSampleAt = 0
  }

  accept(z: number, timestamp: number): boolean {
    if (this.lastSampleAt > 0 && timestamp - this.lastSampleAt > this.maxSampleGapMs) {
      this.reset()
    }
    this.lastSampleAt = timestamp

    if (this.sampleCount < 8) {
      this.sampleCount++
      this.baselineZ = this.baselineZ + (z - this.baselineZ) / this.sampleCount
      this.smoothedZ = this.baselineZ
      return false
    }

    this.smoothedZ = this.smoothedZ * 0.72 + z * 0.28
    this.baselineZ = this.baselineZ * 0.985 + this.smoothedZ * 0.015
    const offset = this.smoothedZ - this.baselineZ

    if (!this.isDown && offset < this.downThreshold) {
      this.isDown = true
      return false
    }

    if (this.isDown && offset > this.upThreshold && timestamp - this.lastRepAt > this.minRepIntervalMs) {
      this.isDown = false
      this.lastRepAt = timestamp
      return true
    }

    if (this.isDown && offset > -0.25) {
      this.isDown = false
    }
    return false
  }
}
