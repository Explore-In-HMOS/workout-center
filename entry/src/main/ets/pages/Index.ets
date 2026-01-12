import { TimerService } from '../core/services/TimerService'
import { ConstantUI } from '../util/ConstantUI'

@Component
export struct IndexPage {
  @State workDuration: number = 15
  @State squatTarget: number = 15
  navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text('HIIT')
            .fontSize(ConstantUI.SIZE_20)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .width(ConstantUI.FULL_WIDTH_90)
            .margin({ bottom: ConstantUI.SIZE_6 })

          Text($r('app.string.squat_trainer'))
            .fontSize(ConstantUI.SIZE_20)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .width(ConstantUI.FULL_WIDTH_90)
            .margin({ bottom: ConstantUI.SIZE_6 })

          Text($r('app.string.index_subtitle'))
            .fontSize(ConstantUI.SIZE_14)
            .fontColor('#666666')
            .margin({ bottom: ConstantUI.SIZE_16 })

          Text($r('app.string.index_duration_label'))
            .fontSize(ConstantUI.SIZE_14)
            .fontWeight(FontWeight.Medium)

          TextInput({
            text: this.workDuration.toString(),
            placeholder: $r('app.string.index_duration_placeholder')
          })
            .type(InputType.Number)
            .margin({ bottom: ConstantUI.SIZE_16 })
            .onChange((val: string) => {
              this.workDuration = parseInt(val) || ConstantUI.CONST_0
            })

          Text($r('app.string.index_target_label'))
            .fontSize(ConstantUI.SIZE_14)
            .fontWeight(FontWeight.Medium)

          TextInput({
            text: this.squatTarget.toString(),
            placeholder: $r('app.string.index_target_placeholder')
          })
            .type(InputType.Number)
            .margin({ bottom: ConstantUI.SIZE_20 })
            .onChange((val: string) => {
              this.squatTarget = parseInt(val) || ConstantUI.CONST_0
            })

          Button($r('app.string.start_workout'))
            .fontSize(ConstantUI.SIZE_14)
            .fontWeight(FontWeight.Bold)
            .width(ConstantUI.FULL_WIDTH)
            .height(ConstantUI.SIZE_36)
            .borderRadius(ConstantUI.SIZE_10)
            .backgroundColor('#fe8627')
            .fontColor($r('sys.color.white'))
            .onClick(() => {
              if (this.workDuration > 0 && this.squatTarget > 0) {
                const timer = TimerService.getInstance()
                timer.setTime(this.workDuration)
                timer.setTarget(this.squatTarget)
                this.navPathStack.pushPath({ name: 'MainPage' })
              }
            })
        }
        .padding(ConstantUI.SIZE_16)
        .width(ConstantUI.FULL_WIDTH)
        .alignItems(HorizontalAlign.Center)
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