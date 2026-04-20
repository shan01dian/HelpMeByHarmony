import { router } from '@kit.ArkUI';           // 1. 导入路由：用来跳转页面
import { promptAction } from '@kit.ArkUI';     // 2. 导入提示：用来弹出“请先登录”

@Entry
@Component
struct Publish {
  // 3. 定义一个登录状态变量（用AppStorage可以实现多页面共享状态）
  @StorageProp('isLogin') isLogin: boolean = false;

  // 4. 写一个拦截方法（完全对应你前端原来的 requireLogin）
  private checkLogin(): boolean {
    if (this.isLogin) {
      return true; // 已经登录了，放行
    }

    // 没登录：先弹个提示
    promptAction.showToast({
      message: '请先登录后再发布',
      duration: 2000
    });

    // 没登录：跳转到登录页
    router.pushUrl({ url: 'pages/LoginPage' });

    return false; // 拦截下来，不执行后面的发布逻辑
  }

  build() {
    Column() {

      // ===== 你原来的发布按钮代码大概是这样的 =====
      Button('发布需求')
        .width('80%')
        .margin({ top: 20 })
        .onClick(() => {
          // 5. 在点击事件里，先调用拦截方法
          if (this.checkLogin()) {
            // 如果 checkLogin 返回 true，说明有登录，才执行真正的业务逻辑
            console.info('执行发布需求的逻辑')
            // this.showRequestModal = true; (你原来的代码写在这里)
          }
        })

      Button('提供帮助')
        .width('80%')
        .margin({ top: 20 })
        .onClick(() => {
          // 同理，其他需要登录的按钮也包一层 checkLogin()
          if (this.checkLogin()) {
            console.info('执行提供帮助的逻辑')
          }
        })

      // ===== 其他UI代码 =====

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}