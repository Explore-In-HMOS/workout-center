import lottie from '@ohos/lottie'
import type { AnimationItem } from '@ohos/lottie'

type LottieRenderer = 'canvas'
interface LottieOptions {
  container: CanvasRenderingContext2D
  renderer: LottieRenderer
  loop: boolean
  autoplay: boolean
  name: string
  contentMode: string
  path: string
  initialSegment?: [number, number]
}

@Component
export default struct LottieAnimation {
  @Prop politeChickyPath: string
  @Prop to: string = ''

  private readonly renderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private readonly canvasController: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.renderingSettings)
  private readonly animationName: string = 'politeChicky'
  private animateItem: AnimationItem | null = null

  build() {
    Canvas(this.canvasController)
      .onReady(() => {
        if (this.animateItem) {
          this.animateItem.resize()
          return
        }

        this.canvasController.imageSmoothingEnabled = true
        this.canvasController.imageSmoothingQuality = 'medium'
        lottie.destroy(this.animationName)

        const options: LottieOptions = {
          container: this.canvasController,
          renderer: 'canvas',
          loop: true,
          autoplay: true,
          name: this.animationName,
          contentMode: 'Contain',
          path: this.politeChickyPath
        }
        const item: AnimationItem = lottie.loadAnimation(options)
        this.animateItem = item

        if (this.to !== '') {
          const onAnimationComplete: () => void = () => {
            if (this.animateItem) {
              this.animateItem.removeEventListener('complete', onAnimationComplete)
              this.animateItem.destroy()
              this.animateItem = null
            }
          }
          this.animateItem.addEventListener('complete', onAnimationComplete)
        }
      })
      .onDisAppear(() => {
        if (this.animateItem) {
          lottie.destroy(this.animationName)
          this.animateItem = null
        }
      })
  }
  aboutToDisappear(): void {
    if (this.animateItem) {
      lottie.destroy(this.animationName)
      this.animateItem = null
    }
  }
}
