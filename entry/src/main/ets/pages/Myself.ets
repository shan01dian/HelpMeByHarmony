import { router } from '@kit.ArkUI'
import { httpGet } from '../services/HttpUtil'
import { getCurrentSession, logout, Session } from '../services/AuthService'

// 用户资料接口
interface UserProfile {
  userId: number
  userName: string
  userAvatar: string
  realName: string
  phoneNumber: string
  location: string
  birthDate: string
  introduction: string
  followerCount: number
  providerRole: number
  serviceRanking: number
  orderCount: number
  buyerRanking: number
}

@Entry
@Component
struct Myself {
  @State session: Session | null = null
  @State profile: UserProfile | null = null
  @State isLoggedIn: boolean = false
  @State favoriteCount: number = 0
  @State followCount: number = 0
  @State followerCount: number = 0
  @State isLoading: boolean = true

  aboutToAppear() {
    this.checkLogin()
  }

  async checkLogin() {
    this.session = await getCurrentSession()
    this.isLoggedIn = this.session !== null

    if (this.isLoggedIn && this.session) {
      await this.loadProfile()
    }
    this.isLoading = false
  }

  async loadProfile() {
    try {
      const userId = this.session?.id
      if (userId) {
        this.profile = await httpGet<UserProfile>(`/users/${userId}/profile`)
        this.followerCount = this.profile?.followerCount || 0
      }
    } catch (e) {
      console.error('加载个人资料失败:', e)
    }
  }

  async onLogout() {
    await logout()
    this.isLoggedIn = false
    this.session = null
    this.profile = null
    router.replaceUrl({ url: 'pages/LoginPage' })
  }

  getRoleName(role: number): string {
    if (role === 1) return '热心群众'
    if (role === 2) return '专业人士'
    if (role === 3) return '商家'
    return '普通用户'
  }

  build() {
    Column() {
      if (this.isLoading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.isLoggedIn) {
        // 未登录状态
        this.NotLoggedInView()
      } else {
        // 已登录状态
        this.LoggedInView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NotLoggedInView() {
    Column() {
      // 顶部装饰背景
      Column() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor('#FFFFFF')
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 2 })

          Text('登录后查看更多')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ top: 16 })

          Button('去登录')
            .type(ButtonType.Capsule)
            .width(120)
            .height(40)
            .fontSize(16)
            .backgroundColor('#FFFFFF')
            .fontColor('#FF6B6B')
            .margin({ top: 16 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' })
            })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      .height(280)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#FF6B6B', 0.0], ['#FF8E8E', 1.0]]
      })

      // 功能预览
      Column() {
        Text('登录后可使用')
          .fontSize(14)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 8 })

        this.MenuItem($r('app.media.startIcon'), '我的事件', '管理发布的事件')
        this.MenuItem($r('app.media.startIcon'), '我的订单', '查看订单记录')
        this.MenuItem($r('app.media.startIcon'), '我的收藏', '收藏的事件')
        this.MenuItem($r('app.media.startIcon'), '认证管理', '成为专业服务者')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .margin({ top: -16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  LoggedInView() {
    Column() {
      // 用户信息卡片
      Column() {
        // 头像和基本信息
        Row() {
          Image(this.profile?.userAvatar || '')
            .width(64)
            .height(64)
            .borderRadius(32)
            .backgroundColor('#F0F0F0')

          Column() {
            Text(this.profile?.userName || '未设置昵称')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            if (this.profile?.introduction) {
              Text(this.profile.introduction)
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }

            if (this.profile?.providerRole) {
              Row() {
                Text(this.getRoleName(this.profile.providerRole))
                  .fontSize(12)
                  .fontColor('#FFD700')
                  .backgroundColor('rgba(255,215,0,0.2)')
                  .borderRadius(4)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              }
              .margin({ top: 6 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })

        // 统计栏
        Row() {
          this.StatItem(this.favoriteCount.toString(), '收藏')
          this.StatItem(this.followCount.toString(), '关注')
          this.StatItem(this.followerCount.toString(), '粉丝')
          this.StatItem(this.profile?.orderCount?.toString() || '0', '订单')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ top: 16, bottom: 16 })
        .backgroundColor('rgba(255,255,255,0.15)')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
      }
      .width('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#FF6B6B', 0.0], ['#FF8E8E', 1.0]]
      })

      // 功能菜单
      Column() {
        Text('常用功能')
          .fontSize(14)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 8 })

        this.MenuItem($r('app.media.startIcon'), '我的事件', '管理发布的事件')
        this.MenuItem($r('app.media.startIcon'), '我的订单', '查看订单记录')
        this.MenuItem($r('app.media.startIcon'), '我的收藏', '收藏的事件')
        this.MenuItem($r('app.media.startIcon'), '认证管理', '成为专业服务者')

        Divider()
          .color('#F0F0F0')
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })

        Text('其他设置')
          .fontSize(14)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 16, bottom: 8 })

        this.MenuItem($r('app.media.startIcon'), '设置', '账号与安全')
        this.MenuItem($r('app.media.startIcon'), '关于我们', '版本信息')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .margin({ top: -16 })

      // 退出登录按钮
      Button('退出登录')
        .type(ButtonType.Capsule)
        .width('90%')
        .height(44)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .fontColor('#FF3B30')
        .margin({ top: 16, bottom: 24 })
        .border({ width: 1, color: '#FF3B30' })
        .onClick(() => this.onLogout())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(label)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.8)')
        .margin({ top: 4 })
    }
  }

  @Builder
  MenuItem(icon: Resource, title: string, subtitle: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor('#666')

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#333')
        Text(subtitle)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      Image($r('app.media.startIcon'))
        .width(16)
        .height(16)
        .fillColor('#CCC')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      // TODO: 跳转到对应页面
    })
  }
}
