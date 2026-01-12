import LottieAnimation from '../animation/LottieAnimation'
import { ConstantUI } from '../util/ConstantUI'
import { DetailPage } from './DetailPage'
import { IndexPage } from './Index'
import { MainPage } from './MainPage'

@Entry
@Component
export struct SplashPage {
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear() {
    setTimeout(() => {
      this.navPathStack.replacePath({ name: 'Index' })
    }, 5000)
  }

  @Builder
  PageMap(name: string) {
    if (name === 'Index') {
      IndexPage()
    } else if (name === 'MainPage') {
      MainPage()
    } else if (name === 'DetailPage') {
      DetailPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        LottieAnimation({ politeChickyPath: 'resources/rawfile/splash.json' })
          .width(ConstantUI.FULL_WIDTH)
          .height(ConstantUI.FULL_HEIGHT)
      }
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .mode(NavigationMode.Stack)
    .hideNavBar(true)
    .navDestination(this.PageMap)
  }
}