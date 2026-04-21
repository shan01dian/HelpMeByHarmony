import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { HttpService } from '../services/HttpService'
import { EventCardData } from '../model/EventModel'

@Entry
@Component
struct SearchPage {
  @State searchText: string = ''
  @State searchHistory: string[] = ['电脑维修', '学习辅导', '搬家服务']
  @State hotSearchList: string[] = ['宠物寄养', '家政服务', '翻译帮助', '摄影服务', '健身教练']
  @State searchResults: EventCardData[] = []
  @State isLoading: boolean = false
  @State hasSearched: boolean = false
  @State showResults: boolean = false
  
  private httpService: HttpService = new HttpService()

  aboutToAppear(): void {
    console.log('[SearchPage] 页面加载完成')
  }

  aboutToDisappear(): void {
    console.log('[SearchPage] 页面即将消失，清理资源')
    this.httpService.destroy()
  }

  // 返回主页
  private navigateBack(): void {
    router.back()
  }

  // 执行搜索
  private async performSearch(): Promise<void> {
    if (this.searchText.trim() === '') {
      promptAction.showToast({ message: '请输入搜索关键词', duration: 2000 })
      return
    }

    console.log(`[SearchPage] 执行搜索: "${this.searchText}"`)

    // 添加到搜索历史（去重）
    const newHistory = [this.searchText.trim(), ...this.searchHistory.filter(item => item !== this.searchText.trim())]
    this.searchHistory = newHistory.slice(0, 5) // 最多保留5条记录

    this.isLoading = true
    this.hasSearched = true
    this.showResults = true

    try {
      console.log(`[SearchPage] 调用HttpService搜索...`)
      const results = await this.httpService.searchEvents(this.searchText.trim())
      console.log(`[SearchPage] 搜索完成，收到 ${results.length} 条结果`)
      
      this.searchResults = results
      
      if (results.length === 0) {
        console.log('[SearchPage] 未找到相关结果')
        promptAction.showToast({ message: '未找到相关结果', duration: 2000 })
      } else {
        console.log(`[SearchPage] 显示 ${results.length} 条搜索结果`)
      }
    } catch (err) {
      console.error('[SearchPage] 搜索错误:', err)
      promptAction.showToast({ message: '搜索失败，请检查网络连接', duration: 2000 })
      this.searchResults = []
    } finally {
      this.isLoading = false
      console.log(`[SearchPage] 搜索状态: isLoading=${this.isLoading}, results=${this.searchResults.length}`)
    }
  }

  // 清空搜索历史
  private clearSearchHistory(): void {
    this.searchHistory = []
    console.log('[SearchPage] 清空搜索历史')
  }

  // 点击历史记录搜索
  private searchFromHistory(item: string): void {
    console.log(`[SearchPage] 从历史记录搜索: "${item}"`)
    this.searchText = item
    this.performSearch()
  }

  // 点击热门搜索
  private searchFromHot(item: string): void {
    console.log(`[SearchPage] 从热门搜索搜索: "${item}"`)
    this.searchText = item
    this.performSearch()
  }

  // 跳转到事件详情
  private navigateToEventDetail(eventId: string): void {
    console.log(`[SearchPage] 跳转到事件详情: ${eventId}`)
    router.pushUrl({
      url: 'pages/EventDetail',
      params: { id: eventId }
    })
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
          this.navigateBack()
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
            this.searchText = value
          })
          .onSubmit(() => {
            this.performSearch()
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
            this.performSearch()
          })
      }
      .width('100%')
      .padding({ top: 12, left: 16, right: 16, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 搜索结果区域
      if (this.showResults) {
        this.buildSearchResults()
      } else {
        // 搜索内容区域（历史记录和热门搜索）
        this.buildSearchContent()
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildSearchResults() {
    Column() {
      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('搜索中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        // 搜索结果列表
        Text(`找到 ${this.searchResults.length} 个结果`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 16, top: 12, bottom: 8 })
          .alignSelf(ItemAlign.Start)

        List({ space: 8 }) {
          ForEach(this.searchResults, (item: EventCardData) => {
            ListItem() {
              this.EventCard(item)
            }
          }, (item: EventCardData) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.hasSearched) {
        // 无结果状态
        Column() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(48)
            .fontColor([Color.Gray])
            .margin({ bottom: 16 })
          Text('未找到相关结果')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 8 })
          Text('请尝试其他关键词')
            .fontSize(14)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildSearchContent() {
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
                  this.clearSearchHistory()
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
                    this.searchFromHistory(item)
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
                this.searchFromHot(item)
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
  }

  @Builder
  EventCard(item: EventCardData) {
    Row() {
      // 图片
      if (item.cardImage) {
        Image(item.cardImage)
          .width(80)
          .height(80)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.folder'))
            .fontSize(24)
            .fontColor([Color.Gray])
          Text('暂无图片')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width(80)
        .height(80)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
      }

      // 信息
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          SymbolGlyph($r('sys.symbol.pin'))
            .fontSize(12)
            .fontColor([Color.Gray])
          Text(item.address)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ top: 4 })

        Text(item.demand)
          .fontSize(14)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        Row() {
          Text(item.price + '元')
            .fontSize(16)
            .fontColor('#FF6600')
            .fontWeight(FontWeight.Bold)

          Blank()

          Text(item.name)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .padding({ left: 10 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 8 })
    .onClick(() => {
      this.navigateToEventDetail(item.id)
    })
  }
}