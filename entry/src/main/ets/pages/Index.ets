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

  // 跳转到搜索页面
  private navigateToSearch(): void {
    router.pushUrl({
      url: 'pages/Search'
    });
  }

  build() {
    Column() {
      // 顶部搜索框区域
      Row() {
        // 模仿咸鱼的假搜索框
        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor([Color.Gray])
            .margin({ right: 8 })
          
          Text('搜索你想要的帮助')
            .fontSize(16)
            .fontColor('#999999')
            .textAlign(TextAlign.Start)
        }
        .width('90%')
        .height(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.navigateToSearch();
        })
      }
      .width('100%')
      .padding({ top: 12, left: 16, right: 16, bottom: 12 })
      .backgroundColor('#F5F5F5')

      // 主内容区域
      Column() {
        Text('热门帮助')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 16 })
        
        // 热门帮助列表示例
        Column({ space: 12 }) {
          this.buildHelpItem('电脑维修', '专业电脑维修服务，快速上门')
          this.buildHelpItem('学习辅导', '各科目学习辅导，一对一教学')
          this.buildHelpItem('搬家服务', '专业搬家团队，安全可靠')
          this.buildHelpItem('宠物寄养', '爱心宠物寄养，细心照料')
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)

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

  @Builder
  private buildHelpItem(title: string, description: string) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Text(description)
          .fontSize(14)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('查看详情')
        .fontSize(14)
        .fontColor(Color.Blue)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      // 点击帮助项也可以跳转到搜索页面
      this.navigateToSearch();
    })
  }
}