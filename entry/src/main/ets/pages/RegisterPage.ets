import { router, promptAction } from '@kit.ArkUI';
import { register, sendCode, checkPhone, verifyCode, RegisterRequest } from '../services/AuthService';
import { httpUpload } from '../services/HttpUtil';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';

interface UploadResult {
  success: boolean
  path: string
}

@Entry
@Component
struct RegisterPage {
  // === 步骤控制 ===
  @State formStep: number = 1

  // === 第一步：手机号验证 ===
  @State phone: string = ''
  @State code: string = ''
  @State countdown: number = 0

  // === 第二步：个人信息 ===
  @State avatarUri: string = ''
  @State avatarServerPath: string = ''
  @State userName: string = ''
  @State realName: string = ''
  @State idCard: string = ''
  @State selectedBirthDate: string = ''
  @State introduction: string = ''

  // === 选择器状态 ===
  @State showDatePicker: boolean = false
  @State selectedDate: Date = new Date(1990, 0, 1)

  // === 日期选择器数据 ===
  @State years: string[] = []
  @State months: string[] = []
  @State days: string[] = []
  @State selectedYearIdx: number = 0
  @State selectedMonthIdx: number = 0
  @State selectedDayIdx: number = 0

  // === 提交状态 ===
  @State isSubmitting: boolean = false

  private timerId: number = -1

  aboutToAppear(): void {
    // 初始化日期选择器数据
    const currentYear = new Date().getFullYear()
    const yearArr: string[] = []
    for (let y = 1900; y <= currentYear; y++) {
      yearArr.push(String(y))
    }
    this.years = yearArr

    const monthArr: string[] = []
    for (let m = 1; m <= 12; m++) {
      monthArr.push(String(m))
    }
    this.months = monthArr

    const dayArr: string[] = []
    for (let d = 1; d <= 31; d++) {
      dayArr.push(String(d))
    }
    this.days = dayArr
  }

  aboutToDisappear(): void {
    clearInterval(this.timerId)
  }

  // ==================== 表单校验 ====================

  isPhoneValid(): boolean {
    return /^1[3-9]\d{9}$/.test(this.phone)
  }

  isIdCardValid(): boolean {
    return /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[0-9Xx]$/.test(this.idCard)
  }

  // ==================== 第一步：发送验证码 ====================

  async onSendCode(): Promise<void> {
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 })
      return
    }
    try {
      await sendCode(this.phone, '')
      promptAction.showToast({ message: '验证码已发送（测试固定为 1234）', duration: 2000 })
      this.countdown = 60
      this.timerId = setInterval(() => {
        this.countdown--
        if (this.countdown <= 0) {
          clearInterval(this.timerId)
        }
      }, 1000)
    } catch (e) {
      promptAction.showToast({ message: '发送失败，请重试', duration: 2000 })
    }
  }

  // ==================== 第一步：下一步 ====================

  async onNextStep(): Promise<void> {
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 })
      return
    }
    if (this.code.length === 0) {
      promptAction.showToast({ message: '请输入验证码', duration: 2000 })
      return
    }
    try {
      // 检查手机号是否已注册
      const registered = await checkPhone(this.phone)
      if (registered) {
        promptAction.showToast({ message: '该手机号已注册，请直接登录', duration: 2000 })
        return
      }
      // 验证验证码
      const ok = await verifyCode(this.phone, this.code)
      if (ok) {
        this.formStep = 2
      } else {
        promptAction.showToast({ message: '验证码错误（测试固定为 1234）', duration: 2000 })
      }
    } catch (e) {
      const msg = (e as Error).message || '验证失败'
      promptAction.showToast({ message: msg, duration: 2000 })
    }
  }

  // ==================== 头像选择 ====================

  async onPickAvatar(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })
      if (result.photoUris && result.photoUris.length > 0) {
        const uri = result.photoUris[0]
        const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
        try {
          const stat = fs.statSync(file.fd)
          if (stat.size > 5 * 1024 * 1024) {
            promptAction.showToast({ message: '头像不能超过5MB', duration: 2000 })
            return
          }
          this.avatarUri = uri
        } finally {
          fs.closeSync(file)
        }
      }
    } catch (e) {
      // 用户取消选择，忽略
    }
  }

  // ==================== 选择器确认 ====================

  onConfirmDate(): void {
    const y = this.years[this.selectedYearIdx] || '1990'
    const m = this.months[this.selectedMonthIdx] || '1'
    const d = this.days[this.selectedDayIdx] || '1'
    this.selectedBirthDate = `${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`
    this.showDatePicker = false
  }

  // ==================== 提交注册 ====================

  async handleSubmit(): Promise<void> {
    if (this.userName.length < 2 || this.userName.length > 20) {
      promptAction.showToast({ message: '用户名需要2-20个字符', duration: 2000 })
      return
    }
    if (this.realName.length < 2 || this.realName.length > 20) {
      promptAction.showToast({ message: '真实姓名需要2-20个字符', duration: 2000 })
      return
    }
    if (!this.isIdCardValid()) {
      promptAction.showToast({ message: '请输入正确的18位身份证号', duration: 2000 })
      return
    }

    this.isSubmitting = true
    try {
      // 先上传头像（如果有）
      let avatarPath = ''
      if (this.avatarUri) {
        avatarPath = await this.uploadAvatar()
      }

      // 注册
      const formData: RegisterRequest = {
        phone: this.phone,
        code: this.code,
        userName: this.userName,
        realName: this.realName,
        idCardNumber: this.idCard,
        birthDate: this.selectedBirthDate,
        avatar: avatarPath,
        introduction: this.introduction || undefined
      }
      await register(formData)
      promptAction.showToast({ message: '注册成功', duration: 1500 })
      router.replaceUrl({ url: 'pages/Index' })
    } catch (e) {
      const msg = (e as Error).message || '注册失败'
      promptAction.showToast({ message: msg, duration: 2000 })
    } finally {
      this.isSubmitting = false
    }
  }

  async uploadAvatar(): Promise<string> {
    try {
      const uriParts = this.avatarUri.split('/')
      const fileName = uriParts[uriParts.length - 1] || `avatar_${Date.now()}.jpg`
      const result = await httpUpload<UploadResult>(
        '/upload/register-avatar', 'avatar', this.avatarUri, fileName
      )
      return result.path
    } catch (e) {
      console.error('头像上传失败:', (e as Error).message)
      throw new Error('头像上传失败，请重试')
    }
  }

  // ==================== 构建函数 ====================

  @Builder
  buildStepIndicator() {
    Row() {
      // 步骤1
      Row() {
        Text('1')
          .fontSize(14)
          .fontColor(this.formStep >= 1 ? Color.White : '#999')
          .fontWeight(FontWeight.Bold)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(this.formStep >= 1 ? '#007DDF' : '#E0E0E0')
      .justifyContent(FlexAlign.Center)

      Text('验证手机号')
        .fontSize(13)
        .fontColor(this.formStep >= 1 ? '#333' : '#999')
        .margin({ left: 6 })

      Blank()
        .width(32)
        .height(2)
        .backgroundColor(this.formStep >= 2 ? '#007DDF' : '#E0E0E0')

      // 步骤2
      Row() {
        Text('2')
          .fontSize(14)
          .fontColor(this.formStep >= 2 ? Color.White : '#999')
          .fontWeight(FontWeight.Bold)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(this.formStep >= 2 ? '#007DDF' : '#E0E0E0')
      .justifyContent(FlexAlign.Center)

      Text('填写信息')
        .fontSize(13)
        .fontColor(this.formStep >= 2 ? '#333' : '#999')
        .margin({ left: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 20, bottom: 16 })
  }

  @Builder
  buildInputField(label: string, placeholder: string, value: string,
    inputType: InputType, maxLen: number, onChange: (v: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 6 })

      TextInput({ placeholder: placeholder, text: value })
        .type(inputType)
        .maxLength(maxLen)
        .onChange(onChange)
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12 })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  buildPickerField(label: string, displayText: string, placeholder: string, onTap: () => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 6 })

      Row() {
        Text(displayText || placeholder)
          .fontSize(15)
          .fontColor(displayText ? '#333' : '#C0C0C0')
          .layoutWeight(1)

        Text('>')
          .fontSize(14)
          .fontColor('#CCC')
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .padding({ left: 12, right: 12 })
      .onClick(onTap)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部返回栏
        Row() {
          Text('<')
            .fontSize(22)
            .fontColor('#333')
            .onClick(() => {
              if (this.formStep === 2) {
                this.formStep = 1
              } else {
                router.back()
              }
            })
          Blank().width(8)
          Text(this.formStep === 1 ? '验证手机号' : '填写个人信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height(48)
        .padding({ left: 16 })
        .alignItems(VerticalAlign.Center)

        // 步骤指示器
        this.buildStepIndicator()

        Divider().color('#F0F0F0')

        // 表单内容
        Scroll() {
          if (this.formStep === 1) {
            this.buildStep1()
          } else {
            this.buildStep2()
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)

      // 底部按钮
      Column() {
        Divider().color('#F0F0F0')

        if (this.formStep === 1) {
          Button('下一步')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(48)
            .fontSize(18)
            .fontColor(Color.White)
            .backgroundColor('#007DDF')
            .margin({ left: 20, right: 20, top: 12, bottom: 20 })
            .onClick(() => this.onNextStep())
        } else {
          Row() {
            Button('上一步')
              .type(ButtonType.Capsule)
              .layoutWeight(1)
              .height(48)
              .fontSize(16)
              .fontColor('#007DDF')
              .backgroundColor(Color.White)
              .borderWidth(1)
              .borderColor('#007DDF')
              .onClick(() => {
                this.formStep = 1
              })

            Blank().width(12)

            Button(this.isSubmitting ? '注册中...' : '完成注册')
              .type(ButtonType.Capsule)
              .layoutWeight(2)
              .height(48)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor('#007DDF')
              .enabled(!this.isSubmitting)
              .onClick(() => this.handleSubmit())
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 20 })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)

      // 日期选择器覆盖层（在Stack顶层，覆盖整个页面）
      if (this.showDatePicker) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0,0,0,0.3)')
            .onClick(() => { this.showDatePicker = false })

          Column() {
            Row() {
              Text('取消')
                .fontSize(16)
                .fontColor('#999')
                .onClick(() => { this.showDatePicker = false })
              Blank().layoutWeight(1)
              Text('确定')
                .fontSize(16)
                .fontColor('#007DDF')
                .fontWeight(FontWeight.Bold)
                .onClick(() => this.onConfirmDate())
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })

            TextPicker({
              range: [this.years, this.months, this.days],
              selected: [this.selectedYearIdx, this.selectedMonthIdx, this.selectedDayIdx]
            })
              .onChange((_value: string | string[], index: number | number[]) => {
                const idx = index as number[]
                this.selectedYearIdx = idx[0]
                this.selectedMonthIdx = idx[1]
                this.selectedDayIdx = idx[2]
              })
              .height(220)
              .width('100%')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 12, topRight: 12 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildStep1() {
    Column() {
      Blank().height(24)

      Text('请输入手机号，完成验证后继续注册')
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 32 })

      // 手机号输入框
      Text('手机号')
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 6 })

      TextInput({ placeholder: '请输入11位手机号', text: this.phone })
        .maxLength(11)
        .type(InputType.Number)
        .onChange((v: string) => { this.phone = v })
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 16 })

      Blank().height(20)

      // 验证码输入 + 发送按钮
      Text('验证码')
        .fontSize(14)
        .fontColor('#333')
        .margin({ bottom: 6 })

      Row() {
        TextInput({ placeholder: '请输入验证码', text: this.code })
          .maxLength(4)
          .type(InputType.Number)
          .onChange((v: string) => { this.code = v })
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
    }
    .padding({ left: 20, right: 20 })
  }

  @Builder
  buildStep2() {
    Column() {
      // 头像选择
      Column() {
        Stack({ alignContent: Alignment.BottomEnd }) {
          if (this.avatarUri) {
            Image(this.avatarUri)
              .width(80)
              .height(80)
              .borderRadius(40)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text('+')
                .fontSize(32)
                .fontColor('#CCC')
            }
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor('#F0F0F0')
            .border({ width: 2, color: '#E0E0E0', style: BorderStyle.Dashed })
            .justifyContent(FlexAlign.Center)
          }

          // 相机图标
          Row() {
            Text('📷')
              .fontSize(12)
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor('#007DDF')
          .justifyContent(FlexAlign.Center)
        }
        .onClick(() => this.onPickAvatar())

        Text('选择头像（选填，≤5MB）')
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20, bottom: 24 })

      // 基本信息表单
      this.buildInputField('用户名', '请输入用户名（2-20字符）', this.userName,
        InputType.Normal, 20, (v: string) => { this.userName = v })

      this.buildInputField('真实姓名', '请输入真实姓名（2-20字符）', this.realName,
        InputType.Normal, 20, (v: string) => { this.realName = v })

      this.buildInputField('身份证号', '请输入18位身份证号', this.idCard,
        InputType.Normal, 18, (v: string) => { this.idCard = v })

      this.buildPickerField('出生日期（选填）', this.selectedBirthDate, '请选择出生日期',
        () => { this.showDatePicker = true })

      // 个人简介
      Column() {
        Text('个人简介（选填）')
          .fontSize(14)
          .fontColor('#333')
          .margin({ bottom: 6 })

        TextArea({ placeholder: '介绍一下自己吧（不超过200字）', text: this.introduction })
          .maxLength(200)
          .onChange((v: string) => { this.introduction = v })
          .height(100)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12, top: 8 })
          .width('100%')
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 底部留白
      Blank().height(80)
    }
    .padding({ left: 20, right: 20 })
  }
}
