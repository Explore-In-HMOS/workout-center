import { TimerService } from '../core/services/TimerService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct DetailPage {
  private timerService = TimerService.getInstance()
  navPathStack: NavPathStack = new NavPathStack()

  private getMotivationMessage(): string {
    const completed = this.timerService.repCount
    const target = this.timerService.targetRepCount

    if (completed >= target) {
      return `🔥 Awesome! You've completed your goal!`
    } else if (completed >= target * 0.75) {
      return `💪 You're so close! Just a little more effort!`
    } else if (completed >= target * 0.5) {
      return `🚀 Great! You're halfway there, keep going!`
    } else if (completed > 0) {
      return `👣 Nice start! Keep it up!`
    } else {
      return `🛑 No squats yet. Want to give it another try?`
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: ConstantUI.SIZE_20 }) {
          Text($r('app.string.text_motivation'))
            .fontSize(ConstantUI.SIZE_22)
            .fontWeight(FontWeight.Bold)

          Text(`🎯 Target Squats: ${this.timerService.targetRepCount}`)
            .fontSize(ConstantUI.SIZE_20)

          Text(`✅ Completed Squats: ${this.timerService.repCount}`)
            .fontSize(ConstantUI.SIZE_20)

          Text(this.getMotivationMessage())
            .fontSize(ConstantUI.SIZE_18)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Medium)
            .margin({ top: ConstantUI.SIZE_10 })

          Button('🔁 Restart')
            .onClick(() => {
              this.timerService.reset()
              this.navPathStack.clear()
              this.navPathStack.pushPath({ name: 'Index' })
            })
        }
        .padding(ConstantUI.SIZE_24)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack
    })
  }
}