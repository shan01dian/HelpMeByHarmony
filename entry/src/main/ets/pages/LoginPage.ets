// pages/LoginPage.ets
import { router } from '@kit.ArkUI';

@Entry
@Component
struct LoginPage {
  build() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(78)
        .height(78)
      Button('登录')
        .onClick(() => {
          // 假设这里是你调用接口，接口返回登录成功了：
          // 1. 把全局的登录状态改成 true（和Publish.ets里的变量对应起来）
          AppStorage.setOrCreate('isLogin', true);

          // 2. 返回上一页（也就是自动退回 Publish.ets 页面）
          router.back();
        })
    }
  }
}