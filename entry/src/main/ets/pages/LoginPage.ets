import { router, promptAction } from '@kit.ArkUI';
import { login, sendCode } from '../services/AuthService';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State countdown: number = 0;         // 发送验证码倒计时
  @State isLoading: boolean = false;     // 登录中加载态

  private timerId: number = -1;

  aboutToDisappear() {
    clearInterval(this.timerId);
  }

  // 手机号校验：11位数字
  isPhoneValid(): boolean {
    return /^1\d{10}$/.test(this.phone);
  }

  // 发送验证码
  async onSendCode() {
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }
    try {
      await sendCode(this.phone, '');
      promptAction.showToast({ message: '验证码已发送（固定为 1234）', duration: 2000 });
      // 启动 60s 倒计时
      this.countdown = 60;
      this.timerId = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.timerId);
        }
      }, 1000);
    } catch (e) {
      promptAction.showToast({ message: '发送失败，请重试', duration: 2000 });
    }
  }

  // 登录
  async handleLogin() {
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }
    if (this.code.length === 0) {
      promptAction.showToast({ message: '请输入验证码', duration: 2000 });
      return;
    }

    this.isLoading = true;
    try {
      await login(this.phone, this.code);
      promptAction.showToast({ message: '登录成功', duration: 1500 });
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {
      const msg = (e as Error).message || '登录失败';
      if (msg.includes('未注册')) {
        promptAction.showToast({ message: '该手机号未注册，请先注册账号', duration: 2000 });
      } else if (msg.includes('验证码错误')) {
        promptAction.showToast({ message: '验证码错误（测试固定为 1234）', duration: 2000 });
      } else {
        promptAction.showToast({ message: msg, duration: 2000 });
      }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部图标
      Image($r('app.media.startIcon'))
        .width(78)
        .height(78)
        .margin({ top: 120, bottom: 16 })

      Text('手机号登录')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      // 手机号输入框
      TextInput({ placeholder: '请输入手机号', text: this.phone })
        .maxLength(11)
        .type(InputType.Number)
        .onChange((v: string) => { this.phone = v; })
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 16 })

      Blank().height(16)

      // 验证码输入 + 发送按钮
      Row() {
        TextInput({ placeholder: '请输入验证码', text: this.code })
          .maxLength(4)
          .type(InputType.Number)
          .onChange((v: string) => { this.code = v; })
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16 })
          .layoutWeight(1)

        Blank().width(12)

        Button(this.countdown > 0 ? `${this.countdown}s` : '发送验证码')
          .type(ButtonType.Capsule)
          .height(48)
          .fontSize(14)
          .backgroundColor(this.countdown > 0 ? '#CCC' : '#007DDF')
          .enabled(this.countdown <= 0)
          .onClick(() => this.onSendCode())
      }

      Blank().height(32)

      // 登录按钮
      Button('登录')
        .type(ButtonType.Capsule)
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor('#007DDF')
        .enabled(!this.isLoading)
        .onClick(() => this.handleLogin())

      Blank().height(20)

      // 注册入口
      Text('还没有账号？立即注册')
        .fontColor('#007DFF')
        .fontSize(15)
        .onClick(() => {
          router.pushUrl({ url: 'pages/RegisterPage' });
        })
    }
    .padding({ left: 32, right: 32 })
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
