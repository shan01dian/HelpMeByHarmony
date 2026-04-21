import router from '@ohos.router';

@Entry
@Component
struct SearchPage {
  @State searchText: string = '';
  @State searchHistory: string[] = ['电脑维修', '学习辅导', '搬家服务'];
  @State hotSearchList: string[] = ['宠物寄养', '家政服务', '翻译帮助', '摄影服务', '健身教练'];

  // 返回主页
  private navigateBack(): void {
    router.back();
  }

  // 执行搜索
  private performSearch(): void {
    if (this.searchText.trim() === '') {
      return;
    }

    // 添加到搜索历史（去重）
    const newHistory = [this.searchText.trim(), ...this.searchHistory.filter(item => item !== this.searchText.trim())];
    this.searchHistory = newHistory.slice(0, 5); // 最多保留5条记录

    // 这里可以执行实际的搜索逻辑
    console.log('执行搜索:', this.searchText);
    
    // 清空搜索框
    this.searchText = '';
  }

  // 清空搜索历史
  private clearSearchHistory(): void {
    this.searchHistory = [];
  }

  // 点击历史记录搜索
  private searchFromHistory(item: string): void {
    this.searchText = item;
    this.performSearch();
  }

  // 点击热门搜索
  private searchFromHot(item: string): void {
    this.searchText = item;
    this.performSearch();
  }

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        // 返回按钮
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([Color.Black])
        }
        .backgroundColor(Color.Transparent)
        .padding(8)
        .onClick(() => {
          this.navigateBack();
        })

        // 真正的搜索框
        TextInput({ placeholder: '请输入搜索内容' })
          .placeholderColor('#999999')
          .textAlign(TextAlign.Start)
          .caretColor(Color.Blue)
          .fontSize(16)
          .fontColor('#333333')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value;
          })
          .onSubmit(() => {
            this.performSearch();
          })

        // 搜索按钮
        Button('搜索')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(Color.Blue)
          .borderRadius(20)
          .height(40)
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => {
            this.performSearch();
          })
      }
      .width('100%')
      .padding({ top: 12, left: 16, right: 16, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 搜索内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 搜索历史
          if (this.searchHistory.length > 0) {
            Column({ space: 12 }) {
              Row() {
                Text('搜索历史')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .layoutWeight(1)

                Button('清空')
                  .fontSize(14)
                  .fontColor('#999999')
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.clearSearchHistory();
                  })
              }
              .width('100%')

              // 搜索历史标签 - 使用Flex布局替代Wrap
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.searchHistory, (item: string) => {
                  Text(item)
                    .fontSize(14)
                    .fontColor('#666666')
                    .backgroundColor('#F5F5F5')
                    .borderRadius(16)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => {
                      this.searchFromHistory(item);
                    })
                })
              }
              .width('100%')
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }

          // 热门搜索
          Column({ space: 12 }) {
            Text('热门搜索')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            // 热门搜索列表
            Column({ space: 8 }) {
              ForEach(this.hotSearchList, (item: string, index: number) => {
                Row() {
                  Text((index + 1).toString())
                    .fontSize(14)
                    .fontColor(index < 3 ? Color.Red : '#666666')
                    .fontWeight(FontWeight.Medium)
                    .width(24)

                  Text(item)
                    .fontSize(16)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .margin({ left: 12 })

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(16)
                    .fontColor([Color.Gray])
                }
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .onClick(() => {
                  this.searchFromHot(item);
                })
              })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}