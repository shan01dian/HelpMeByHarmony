import router from '@ohos.router';


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State currentTabIndex: number = 0;
  
  @Builder
  private buildIconButton(iconResource: Resource, index: number) {
    Row() {
      SymbolGlyph(iconResource)
        .fontSize(30)
        .margin({ right: 10 })
        .fontColor([this.currentTabIndex === index ? Color.Blue : Color.Gray])
    }
    .onClick(() => {
      this.navigateToPage(index);
    })
  }

  // 页面导航方法
  private navigateToPage(index: number): void {
    const pages = [
      'pages/Index',
      'pages/Search', 
      'pages/Publish',
      'pages/Chat',
      'pages/Myself'
    ];
    
    if (index >= 0 && index < pages.length) {
      if (pages[index] === 'pages/Index') {
        // 如果是当前页面，不进行跳转
        return;
      }
      
      console.log('跳转到页面:', pages[index]);
      router.pushUrl({
        url: pages[index]
      });
    }
  }

  build() {
    Column() {
      // 主内容区域 - 显示当前页面名称
      Column() {
        Text('主页')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Text('欢迎使用HelpMe应用')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 10 })
      }
      .height('90%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 底部导航栏
      Row({ space: 20 }) {
        Button() {
          this.buildIconButton($r('sys.symbol.house'), 0)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(8)

        Button() {
          this.buildIconButton($r('sys.symbol.magnifyingglass'), 1)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(8)

        Button() {
          this.buildIconButton($r('sys.symbol.plus'), 2)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(8)

        Button() {
          this.buildIconButton($r('sys.symbol.message_on_message'), 3)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(8)

        Button() {
          this.buildIconButton($r('sys.symbol.person'), 4)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}