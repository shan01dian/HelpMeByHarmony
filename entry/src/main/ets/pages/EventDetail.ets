import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { HttpService } from '../services/HttpService'
import { EventCardData } from '../model/EventModel'

@Entry
@Component
struct EventDetail {
  @State eventData: EventCardData | null = null
  @State isLoading: boolean = true
  @State errorMessage: string = ''
  
  private eventId: string = ''
  private httpService: HttpService = new HttpService()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params['id']) {
      this.eventId = params['id'] as string
      this.loadEventDetail()
    } else {
      this.errorMessage = '事件ID不存在'
      this.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.httpService.destroy()
  }

  async loadEventDetail(): Promise<void> {
    if (!this.eventId) {
      this.errorMessage = '无效的事件ID'
      this.isLoading = false
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    try {
      const eventDetail = await this.httpService.getEventDetail(this.eventId)
      if (eventDetail) {
        this.eventData = eventDetail
      } else {
        this.errorMessage = '事件不存在或已删除'
      }
    } catch (err) {
      console.error('Load event detail error:', err)
      this.errorMessage = '加载失败，请检查网络连接'
    } finally {
      this.isLoading = false
    }
  }

  private navigateBack(): void {
    router.back()
  }

  private contactProvider(): void {
    if (this.eventData) {
      promptAction.showToast({ 
        message: `联系 ${this.eventData.name}：${this.eventData.price}元`, 
        duration: 2000 
      })
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
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

        Text('事件详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位，保持对称
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([Color.Transparent])
        }
        .backgroundColor(Color.Transparent)
        .padding(8)
        .enabled(false)
      }
      .width('100%')
      .padding({ top: 12, left: 8, right: 8, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 内容区域
      if (this.isLoading) {
        this.buildLoadingState()
      } else if (this.errorMessage) {
        this.buildErrorState()
      } else if (this.eventData) {
        this.buildEventDetail()
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  buildErrorState() {
    Column() {
      SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
        .fontSize(48)
        .fontColor([Color.Red])
        .margin({ bottom: 16 })
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 12 })
      Button('重新加载')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(Color.Blue)
        .borderRadius(20)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .onClick(() => {
          this.loadEventDetail()
        })
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  buildEventDetail() {
    Scroll() {
      Column({ space: 16 }) {
        // 图片区域
        if (this.eventData!.cardImage) {
          Image(this.eventData!.cardImage)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.folder'))
              .fontSize(48)
              .fontColor([Color.Gray])
            Text('暂无图片')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(200)
          .backgroundColor('#F0F0F0')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
        }

        // 基本信息卡片
        Column({ space: 12 }) {
          Text(this.eventData!.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Row() {
            Text(this.eventData!.price + '元')
              .fontSize(24)
              .fontColor('#FF6600')
              .fontWeight(FontWeight.Bold)

            Blank()

            Text(this.eventData!.createTime ? 
              `发布于 ${this.formatDate(this.eventData!.createTime)}` : 
              '发布时间未知')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')

          // 位置信息
          Row() {
            SymbolGlyph($r('sys.symbol.pin'))
              .fontSize(14)
              .fontColor([Color.Gray])
            Text(this.eventData!.address)
              .fontSize(14)
              .fontColor('#666666')
              .layoutWeight(1)
              .margin({ left: 6 })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)

        // 详细信息卡片
        Column({ space: 12 }) {
          Text('详细信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)

          Text(this.eventData!.demand)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(20)
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)

        // 发布者信息卡片
        Column({ space: 12 }) {
          Text('发布者信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)

          Row() {
            if (this.eventData!.avatar) {
              Image(this.eventData!.avatar)
                .width(40)
                .height(40)
                .borderRadius(20)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                SymbolGlyph($r('sys.symbol.person_fill'))
                  .fontSize(24)
                  .fontColor([Color.Gray])
              }
              .width(40)
              .height(40)
              .backgroundColor('#F0F0F0')
              .borderRadius(20)
              .justifyContent(FlexAlign.Center)
            }

            Column() {
              Text(this.eventData!.name)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
              Text('个人发布者')
                .fontSize(12)
                .fontColor('#999999')
            }
            .layoutWeight(1)
            .margin({ left: 12 })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)

        // 底部空白区域
        Blank()
          .height(80)
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)

    // 底部操作栏
    Row() {
      Button('联系发布者')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(Color.Blue)
        .borderRadius(25)
        .height(50)
        .layoutWeight(1)
        .onClick(() => {
          this.contactProvider()
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
  }

  private formatDate(dateString: string): string {
    try {
      const date = new Date(dateString)
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, '0')
      const day = date.getDate().toString().padStart(2, '0')
      return `${year}-${month}-${day}`
    } catch {
      return dateString
    }
  }
}