import { router } from '@kit.ArkUI'; // 导入路由

@Entry
@Component
struct Myself {
  // 你原有的状态变量...

  // 重点：页面即将显示时触发的生命周期
  aboutToAppear() {
    // 1. 检查全局的登录状态
    const isLogin = AppStorage.get('isLogin') as boolean;

    // 2. 如果没有登录，直接跳走
    if (!isLogin) {
      // 使用 replaceUrl 而不是 pushUrl
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  build() {
    Column() {
      // ===== 你自己写的个人中心UI代码 =====
      // 比如：头像、昵称、设置列表等
      Text('个人中心页面')
      // ================================
    }
    .width('100%')
    .height('100%')
  }
}