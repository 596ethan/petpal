import { PetPalRepository } from '../repository/PetPalRepository';
import { PetPalTheme } from '../ui/PetPalTheme';

@Builder
function LoginChip(label: string) {
  Text(label)
    .fontSize(11)
    .fontColor('#F5E7D8')
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor('rgba(255, 248, 243, 0.09)')
    .borderRadius(PetPalTheme.radiusChip)
}

@Entry
@Component
struct Login {
  @State phone: string = ''
  @State password: string = ''
  @State loading: boolean = false
  @State errorMessage: string = ''

  private async submitLogin(): Promise<void> {
    if (this.loading) {
      return;
    }
    const phone = this.phone.trim();
    const password = this.password.trim();
    if (phone.length === 0 || password.length === 0) {
      this.errorMessage = '请输入手机号和密码';
      return;
    }
    this.loading = true;
    this.errorMessage = '';
    try {
      const session = await PetPalRepository.login(phone, password);
      PetPalRepository.storeSession(session);
      await this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
    } catch (error) {
      const rawMessage = error instanceof Error ? error.message : String(error);
      const normalizedMessage = rawMessage.toLowerCase();
      if (normalizedMessage.includes('invalid phone or password') || normalizedMessage.includes('invalid_credentials') || normalizedMessage.includes('401')) {
        this.errorMessage = '手机号或密码错误';
      } else {
        this.errorMessage = `登录失败：${rawMessage}`;
      }
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 16 }) {
          LoginChip('宠物日记')
          Text('欢迎回到\n你和宠物共同生活的笔记本')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text('登录页不再像一张冷表单，而是像进入一本一直在更新的宠物居所，温暖、松弛，也足够清楚。')
            .fontSize(14)
            .lineHeight(22)
            .fontColor('#F7E8DB')
          Row({ space: 10 }) {
            LoginChip('预约提醒')
            LoginChip('社区记录')
          }
        }
        .width('100%')
        .padding({ left: 22, right: 26, top: 30, bottom: 28 })
        .borderRadius(PetPalTheme.radiusHero)
        .linearGradient({
          angle: 145,
          colors: [[PetPalTheme.primaryStrong, 0.0], [PetPalTheme.primary, 0.52], [PetPalTheme.primaryGlow, 1.0]]
        })
        .alignItems(HorizontalAlign.Start)

        Column({ space: 16 }) {
          Text('手机号登录')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text('把预约状态、宠物档案和社区近况继续接回你的日常。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(PetPalTheme.textMuted)

          Column({ space: 10 }) {
            Text('手机号')
              .fontSize(12)
              .fontColor(PetPalTheme.textSubtle)
            TextInput({ text: this.phone, placeholder: '请输入手机号' })
              .height(54)
              .backgroundColor(PetPalTheme.surface)
              .borderRadius(20)
              .padding({ left: 10, right: 10 })
              .onChange((value: string) => {
                this.phone = value
              })
          }
          .alignItems(HorizontalAlign.Start)

          Column({ space: 10 }) {
            Text('密码')
              .fontSize(12)
              .fontColor(PetPalTheme.textSubtle)
            TextInput({ text: this.password, placeholder: '请输入密码' })
              .height(54)
              .backgroundColor(PetPalTheme.surface)
              .borderRadius(20)
              .type(InputType.Password)
              .padding({ left: 10, right: 10 })
              .onChange((value: string) => {
                this.password = value
              })
          }
          .alignItems(HorizontalAlign.Start)

          if (this.loading) {
            Row({ space: 8 }) {
              Text('正在验证手机号和密码...')
                .fontSize(12)
                .fontColor(PetPalTheme.textMuted)
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor('rgba(255, 248, 243, 0.08)')
            .borderRadius(16)
            .justifyContent(FlexAlign.Start)
          }

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#C94F4F')
              .width('100%')
              .padding({ left: 14, right: 14, top: 12, bottom: 12 })
              .backgroundColor('rgba(201, 79, 79, 0.08)')
              .borderRadius(16)
          }

          Button(this.loading ? '登录中...' : '登录进入')
            .width('100%')
            .height(52)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(PetPalTheme.primary)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              void this.submitLogin()
            })

          Button('返回首页')
            .width('100%')
            .height(48)
            .fontSize(13)
            .fontColor(PetPalTheme.text)
            .backgroundColor(PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.getUIContext().getRouter().back()
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(PetPalTheme.surfaceWarm)
        .borderRadius(PetPalTheme.radiusPanel)
        .alignItems(HorizontalAlign.Start)
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 20, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PetPalTheme.background)
  }
}



