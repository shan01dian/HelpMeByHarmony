// pages/LoginPage.ets
import { router } from '@kit.ArkUI';

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  build() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(78)
        .height(78)
        .margin({ top:150,bottom: 20 })
      Text('登录页面'){
        Span('输入手机号进行登录操作')
          .decoration({ type: TextDecorationType.Underline })
          .margin({ top: 70, bottom: 20 })
      }
      TextInput({placeholder:'手机号'})
        .maxLength(11)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.account =value;
          })
      TextInput({placeholder:"密码"})
        .maxLength(8)
        .type(InputType.Password)
        .onChange((value: string) => {
          this.account =value;
        })
      Row({ space: 20 })
      {
        Text('短信验证码登录')
          .decoration({ type: TextDecorationType.Underline })
        Text('忘记密码')
          .decoration({ type: TextDecorationType.Underline })
      }
      .width('100%') // <--- 加上这一行，撑满宽度
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 20, bottom: 20 }) // 顺便加个上下边距更好看一点

      Button('登录',{type:ButtonType.Capsule})
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor('#007DDF')
        .margin({top:48,bottom:12})
        .onClick(() => {
          AppStorage.setOrCreate('isLogin', true);
          router.back();
        })
      Text(){
        Span('注册账号')
          .fontColor('#007DFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
          router.pushUrl({ url: 'pages/RegisterPage' });
        })
      }
    }
  }
}