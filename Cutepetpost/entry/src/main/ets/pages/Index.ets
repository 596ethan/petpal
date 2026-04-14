import {
  Appointment,
  Pet,
  PetCreateInput,
  PetGender,
  PetSpecies,
  Post,
  ServiceProvider,
  UserProfile
} from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
import {
  PetPalTheme,
  genderText,
  providerSurface,
  providerTone,
  providerTypeText,
  speciesText,
  statusSurface,
  statusText,
  statusTone
} from '../ui/PetPalTheme';

@Builder
function SectionLead(eyebrow: string, title: string, subtitle: string) {
  Column({ space: 6 }) {
    Text(eyebrow)
      .fontSize(11)
      .fontColor(PetPalTheme.primary)
      .letterSpacing(1.2)
    Text(title)
      .fontSize(26)
      .fontWeight(FontWeight.Bold)
      .fontColor(PetPalTheme.text)
    Text(subtitle)
      .fontSize(13)
      .lineHeight(20)
      .fontColor(PetPalTheme.textMuted)
  }
  .width('100%')
  .alignItems(HorizontalAlign.Start)
}

@Builder
function CapsuleChip(label: string, backgroundColor: string, fontColor: string) {
  Text(label)
    .fontSize(11)
    .fontColor(fontColor)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusChip)
}

@Builder
function SoftAvatar(label: string, backgroundColor: string, fontColor: string, size: number = 44) {
  Text(label)
    .width(size)
    .height(size)
    .textAlign(TextAlign.Center)
    .fontSize(size > 40 ? 18 : 15)
    .fontWeight(FontWeight.Bold)
    .fontColor(fontColor)
    .backgroundColor(backgroundColor)
    .borderRadius(size / 2)
    .padding({ top: size > 40 ? 10 : 8 })
}

interface PetSpeciesOption {
  value: PetSpecies
  label: string
}

interface PetGenderOption {
  value: PetGender
  label: string
}

const PET_SPECIES_OPTIONS: PetSpeciesOption[] = [
  { value: PetSpecies.CAT, label: '猫咪' },
  { value: PetSpecies.DOG, label: '狗狗' },
  { value: PetSpecies.RABBIT, label: '兔兔' },
  { value: PetSpecies.BIRD, label: '鸟类' },
  { value: PetSpecies.OTHER, label: '其他' }
]

const PET_GENDER_OPTIONS: PetGenderOption[] = [
  { value: PetGender.FEMALE, label: '母' },
  { value: PetGender.MALE, label: '公' },
  { value: PetGender.UNKNOWN, label: '未知' }
]

const EMPTY_USER: UserProfile = {
  id: 0,
  nickname: '',
  bio: '',
  avatarUrl: '',
  followingCount: 0,
  followerCount: 0
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State user: UserProfile = EMPTY_USER
  @State pets: Pet[] = []
  @State posts: Post[] = PetPalRepository.getPosts()
  @State providers: ServiceProvider[] = []
  @State appointments: Appointment[] = []
  @State isAuthenticated: boolean = PetPalRepository.getSession() !== null
  @State refreshError: string = ''
  @State petArchiveMessage: string = ''
  @State petArchiveError: string = ''
  @State petCreateVisible: boolean = false
  @State creatingPet: boolean = false
  @State createPetName: string = ''
  @State createPetSpecies: PetSpecies = PetSpecies.CAT
  @State createPetBreed: string = ''
  @State createPetGender: PetGender = PetGender.UNKNOWN
  @State createPetBirthday: string = ''
  @State createPetWeight: string = ''
  @State createPetAvatarUrl: string = ''
  @State createPetNeutered: boolean = false

  aboutToAppear() {
    void this.refreshData()
  }

  onPageShow() {
    void this.refreshData()
  }

  private async refreshData() {
    try {
      this.refreshError = ''
      const remotePosts = await PetPalRepository.getPostsAsync()
      this.posts = remotePosts.length > 0 ? remotePosts : PetPalRepository.getPosts()
      this.providers = await PetPalRepository.getProvidersAsync()
      if (PetPalRepository.getSession() === null) {
        this.isAuthenticated = false
        this.user = EMPTY_USER
        this.pets = []
        this.appointments = []
        return
      }
      this.isAuthenticated = true
      const user = await PetPalRepository.getCurrentUserAsync()
      const remotePets = await PetPalRepository.getPetsAsync()
      const remoteAppointments = await PetPalRepository.getAppointmentsAsync()
      this.user = user
      this.pets = remotePets
      this.appointments = remoteAppointments
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.refreshError = `内容刷新失败：${message}`
    }
  }

  private async cancelAppointment(id: number): Promise<void> {
    try {
      await PetPalRepository.cancelAppointment(id)
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.refreshError = `取消预约失败：${message}`
    }
  }

  private optionalPositiveNumber(value: string, label: string): number | undefined {
    const trimmed = value.trim()
    if (trimmed.length === 0) {
      return undefined
    }
    const parsed = Number(trimmed)
    if (parsed !== parsed || parsed <= 0) {
      throw new Error(`${label}请输入大于 0 的数字`)
    }
    return parsed
  }

  private resetCreatePetForm(): void {
    this.createPetName = ''
    this.createPetSpecies = PetSpecies.CAT
    this.createPetBreed = ''
    this.createPetGender = PetGender.UNKNOWN
    this.createPetBirthday = ''
    this.createPetWeight = ''
    this.createPetAvatarUrl = ''
    this.createPetNeutered = false
  }

  private async submitCreatePet(): Promise<void> {
    if (this.creatingPet) {
      return
    }
    const name = this.createPetName.trim()
    if (name.length === 0) {
      this.petArchiveError = '请输入宠物名称'
      return
    }
    try {
      this.creatingPet = true
      this.petArchiveError = ''
      this.petArchiveMessage = ''
      const input: PetCreateInput = {
        name: name,
        species: this.createPetSpecies,
        gender: this.createPetGender,
        neutered: this.createPetNeutered
      }
      const breed = this.createPetBreed.trim()
      const birthday = this.createPetBirthday.trim()
      const avatarUrl = this.createPetAvatarUrl.trim()
      const weight = this.optionalPositiveNumber(this.createPetWeight, '体重')
      if (breed.length > 0) {
        input.breed = breed
      }
      if (birthday.length > 0) {
        input.birthday = birthday
      }
      if (weight !== undefined) {
        input.weight = weight
      }
      if (avatarUrl.length > 0) {
        input.avatarUrl = avatarUrl
      }
      await PetPalRepository.createPet(input)
      this.resetCreatePetForm()
      this.petCreateVisible = false
      this.petArchiveMessage = '宠物档案已创建'
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.petArchiveError = `创建宠物档案失败：${message}`
    } finally {
      this.creatingPet = false
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.currentTab === 0) {
          this.HomeTab()
        }
        if (this.currentTab === 1) {
          this.CommunityTab()
        }
        if (this.currentTab === 2) {
          this.BookingTab()
        }
        if (this.currentTab === 3) {
          this.MineTab()
        }
      }
      .width('100%')
      .height('100%')

      this.FloatingTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  FloatingTabBar() {
    Row({ space: 8 }) {
      this.NavPill('舍', '首页', 0)
      this.NavPill('圈', '社区', 1)
      this.NavPill('约', '预约', 2)
      this.NavPill('我', '我的', 3)
    }
    .padding({ left: 10, right: 10, top: 10, bottom: 10 })
    .margin({ left: 18, right: 18, bottom: 18 })
    .backgroundColor(PetPalTheme.overlay)
    .borderRadius(PetPalTheme.radiusPanel)
    .width('90%')
  }

  @Builder
  NavPill(symbol: string, label: string, index: number) {
    Column({ space: 4 }) {
      Text(symbol)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTab === index ? '#FFFFFF' : PetPalTheme.textMuted)
      Text(label)
        .fontSize(11)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === index ? '#FFFFFF' : PetPalTheme.textMuted)
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(this.currentTab === index ? PetPalTheme.primary : PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusChip)
    .layoutWeight(1)
    .onClick(() => {
      this.currentTab = index;
    })
  }

  @Builder
  HomeTab() {
    Scroll() {
      Column({ space: 26 }) {
        if (this.refreshError.length > 0) {
          Text(this.refreshError)
            .fontSize(12)
            .fontColor(PetPalTheme.warning)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(PetPalTheme.warningSoft)
            .borderRadius(PetPalTheme.radiusChip)
        }
        this.HomeHero()
        this.HomeMoodStrip()
        SectionLead('社群精选', '今天值得被记住的宠物片段', '首页第一屏先讲故事，再把护理和预约轻轻带出来。')
        if (this.posts.length > 0) {
          this.FeaturedPostCard(this.posts[0])
        }
        this.ServiceSection()
        SectionLead('收藏机构', '适合今天顺手预约的温柔去处', '把高频医疗、美容、寄养保留在第二层，不打断社区的入口感。')
        if (this.providers.length > 0) {
          ForEach(this.providers, (item: ServiceProvider, index: number) => {
            this.ProviderStoryCard(item, index === 0)
          })
        } else {
          this.EmptyStatePanel('暂无机构数据', '机构列表会在后端返回真实数据后显示。')
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
    }
  }

  @Builder
  CommunityTab() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 14 }) {
          SectionLead('宠友社区', '每一条近况都像被收藏的便签', '把护理经验、恢复过程和可爱的碎片放进同一条温柔内容流。')
          Row({ space: 8 }) {
            CapsuleChip('猫咪日常', PetPalTheme.primarySoft, PetPalTheme.primary)
            CapsuleChip('护理经验', PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
            CapsuleChip('预约心得', PetPalTheme.accentSoft, PetPalTheme.accent)
            Blank()
            Button('写一条')
              .height(38)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor(PetPalTheme.primary)
              .borderRadius(PetPalTheme.radiusChip)
          }
          .width('100%')
        }

        ForEach(this.posts, (item: Post, index: number) => {
          this.JournalPostCard(item, index === 0)
        })
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
    }
  }

  @Builder
  BookingTab() {
    Scroll() {
      Column({ space: 24 }) {
        SectionLead('预约与照护', '先看今天的安排，再挑下一程服务', '预约页保留效率，但视觉像一本生活方式目录，不像表单列表。')
        if (!this.isAuthenticated) {
          this.LoginRequiredPanel('登录后查看我的预约')
        } else if (this.appointments.length > 0) {
          Column({ space: 12 }) {
            ForEach(this.appointments, (item: Appointment) => {
              this.AppointmentStoryCard(item)
            })
          }
        } else {
          this.EmptyStatePanel('暂无预约', '创建第一条预约后会显示在这里。')
        }
        SectionLead('继续发现', '把机构做成像值得信任的店铺名片', '信息明确，动作直接，但层级和节奏仍然保持轻松。')
        if (this.providers.length > 0) {
          ForEach(this.providers, (item: ServiceProvider) => {
            this.ProviderBookingCard(item)
          })
        } else {
          this.EmptyStatePanel('暂无机构数据', '请确认后端服务可用后刷新。')
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
    }
  }

  @Builder
  MineTab() {
    Scroll() {
      Column({ space: 24 }) {
        if (!this.isAuthenticated) {
          this.LoginRequiredPanel('登录后查看我的资料和宠物档案')
        } else {
          this.ProfileHero()
          Row({ space: 12 }) {
            this.NotePanel('本周记录', `${this.posts.length} 条动态`, '继续把恢复、洗护和日常都写下来。', PetPalTheme.primarySoft, PetPalTheme.primary)
            this.NotePanel('下次提醒', this.appointments.length > 0 ? this.appointments[0].appointmentTime : '暂无预约', this.appointments.length > 0 ? '下一程照护已经排进日历。' : '创建第一条预约后会显示在这里。', PetPalTheme.accentSoft, PetPalTheme.accent)
          }
          .width('100%')
          SectionLead('我的宠物档案', '每一只都有独立的照护叙事', '把体重、生日、绝育与提醒汇总成更有身份感的档案卡。')
          if (this.petArchiveMessage.length > 0) {
            Text(this.petArchiveMessage)
              .fontSize(12)
              .fontColor(PetPalTheme.success)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(PetPalTheme.successSoft)
              .borderRadius(16)
          }
          if (this.petArchiveError.length > 0) {
            Text(this.petArchiveError)
              .fontSize(12)
              .fontColor(PetPalTheme.danger)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(PetPalTheme.dangerSoft)
              .borderRadius(16)
          }
          Button(this.petCreateVisible ? '收起新建档案' : '新建宠物档案')
            .height(42)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(PetPalTheme.primary)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.petCreateVisible = !this.petCreateVisible
              this.petArchiveError = ''
            })
          if (this.petCreateVisible) {
            this.PetCreateForm()
          }
          if (this.pets.length > 0) {
            ForEach(this.pets, (item: Pet) => {
              this.PetArchiveCard(item)
            })
          } else {
            this.EmptyStatePanel('暂无宠物档案', '当前账号还没有可显示的宠物数据。')
          }
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
    }
  }

  @Builder
  PetCreateForm() {
    Column({ space: 12 }) {
      Text('新建宠物档案')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      TextInput({ text: this.createPetName, placeholder: '宠物名称，必填' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.createPetName = value
        })
      TextInput({ text: this.createPetBreed, placeholder: '品种，可选' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.createPetBreed = value
        })
      Row({ space: 8 }) {
        ForEach(PET_SPECIES_OPTIONS, (option: PetSpeciesOption) => {
          Button(option.label)
            .height(34)
            .fontSize(12)
            .fontColor(this.createPetSpecies === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.createPetSpecies === option.value ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.createPetSpecies = option.value
            })
        })
      }
      Row({ space: 8 }) {
        ForEach(PET_GENDER_OPTIONS, (option: PetGenderOption) => {
          Button(option.label)
            .height(34)
            .fontSize(12)
            .fontColor(this.createPetGender === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.createPetGender === option.value ? PetPalTheme.accent : PetPalTheme.accentSoft)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.createPetGender = option.value
            })
        })
      }
      Row({ space: 10 }) {
        TextInput({ text: this.createPetBirthday, placeholder: '生日 yyyy-MM-dd，可选' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.createPetBirthday = value
          })
        TextInput({ text: this.createPetWeight, placeholder: '体重 kg，可选' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.createPetWeight = value
          })
      }
      TextInput({ text: this.createPetAvatarUrl, placeholder: '头像 URL，可选' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.createPetAvatarUrl = value
        })
      Button(this.createPetNeutered ? '已绝育' : '未绝育')
        .height(38)
        .fontSize(12)
        .fontColor(this.createPetNeutered ? '#FFFFFF' : PetPalTheme.text)
        .backgroundColor(this.createPetNeutered ? PetPalTheme.success : PetPalTheme.warningSoft)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          this.createPetNeutered = !this.createPetNeutered
        })
      Button(this.creatingPet ? '保存中...' : '保存宠物档案')
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.text)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.submitCreatePet()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EmptyStatePanel(title: string, subtitle: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text(subtitle)
        .fontSize(12)
        .lineHeight(19)
        .fontColor(PetPalTheme.textMuted)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  LoginRequiredPanel(message: string) {
    Column({ space: 12 }) {
      Text(message)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text('登录后会从后端加载当前账号的真实数据。')
        .fontSize(12)
        .lineHeight(19)
        .fontColor(PetPalTheme.textMuted)
      Button('去登录')
        .height(40)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.getUIContext().getRouter().pushUrl({ url: 'pages/Login' })
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HomeHero() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 16 }) {
        CapsuleChip('PetPal Chronicle', 'rgba(255, 248, 243, 0.14)', '#FFF7EF')
        Text('把每一次\n照护与陪伴慢慢写下来')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF8F3')
        Text('首页先展示宠物生活的情绪与故事，服务预约退到第二层，整个产品更像一个可以长期回看的宠物居所。')
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#FBEFE6')
        Row({ space: 10 }) {
          Button('进入社区')
            .height(46)
            .fontSize(14)
            .fontColor(PetPalTheme.primaryStrong)
            .backgroundColor('#FFF7F0')
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.currentTab = 1;
            })
          Button('登录 PetPal')
            .height(46)
            .fontSize(14)
            .fontColor('#FFF8F3')
            .backgroundColor('rgba(255, 248, 243, 0.14)')
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              void this.getUIContext().getRouter().pushUrl({ url: 'pages/Login' })
            })
        }
        Row({ space: 10 }) {
          CapsuleChip(`社群故事 ${this.posts.length * 14}`, 'rgba(255, 248, 243, 0.12)', '#FFF8F3')
          CapsuleChip(`照护机构 ${this.providers.length}`, 'rgba(255, 248, 243, 0.10)', '#FFF8F3')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text('今日心情')
          .fontSize(11)
          .fontColor('#FBE7DA')
        Text('安静晒太阳')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF8F3')
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor('rgba(255, 248, 243, 0.09)')
      .borderRadius(22)
      .margin({ top: 14, right: 14 })
    }
    .width('100%')
    .padding({ left: 22, right: 26, top: 26, bottom: 24 })
    .borderRadius(PetPalTheme.radiusHero)
    .linearGradient({
      angle: 145,
      colors: [[PetPalTheme.primaryStrong, 0.0], [PetPalTheme.primary, 0.55], [PetPalTheme.primaryGlow, 1.0]]
    })
  }

  @Builder
  HomeMoodStrip() {
    Row({ space: 12 }) {
      if (this.pets.length > 0) {
        this.NotePanel('今日主角', this.pets[0].name, `${speciesText(this.pets[0].species)} · ${this.pets[0].weight}`, PetPalTheme.surfaceRaised, PetPalTheme.text)
      } else {
        this.NotePanel('今日主角', '暂无宠物', '请稍后刷新', PetPalTheme.surfaceRaised, PetPalTheme.text)
      }
      if (this.appointments.length > 0) {
        this.NotePanel('最近预约', statusText(this.appointments[0].status), `${this.appointments[0].serviceName} · ${this.appointments[0].petName}`, PetPalTheme.surfaceWarm, statusTone(this.appointments[0].status))
      } else {
        this.NotePanel('最近预约', '暂无预约', '请稍后刷新', PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
      }
    }
    .width('100%')
  }

  @Builder
  NotePanel(title: string, value: string, subtitle: string, backgroundColor: string, accentColor: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(11)
        .fontColor(PetPalTheme.textSubtle)
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(accentColor)
        .maxLines(1)
      Text(subtitle)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(PetPalTheme.textMuted)
        .maxLines(2)
    }
    .padding(16)
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusCard)
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  ServiceSection() {
    Column({ space: 14 }) {
      SectionLead('生活服务', '服务入口保留，但退后半步', '三类入口继续存在，不过以轻量目录的方式出现，而不是首页的主视觉。')
      Row({ space: 12 }) {
        this.ServiceCard('医疗', '问诊、疫苗、体检', '照护', PetPalTheme.primarySoft, PetPalTheme.primary)
        this.ServiceCard('美容', '洗护、修剪、护理', '清洁', PetPalTheme.accentSoft, PetPalTheme.accent)
      }
      .width('100%')
      this.ServiceCard('寄养', '短住、长住、陪伴观察', '停留', PetPalTheme.tertiarySoft, '#9C7623')
    }
    .width('100%')
  }

  @Builder
  ServiceCard(title: string, subtitle: string, marker: string, backgroundColor: string, accentColor: string) {
    Row({ space: 14 }) {
      SoftAvatar(marker.substring(0, 1), '#FFFFFF', accentColor, 40)
      Column({ space: 5 }) {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(PetPalTheme.text)
        Text(subtitle)
          .fontSize(12)
          .lineHeight(18)
          .fontColor(PetPalTheme.textMuted)
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Text(marker)
        .fontSize(11)
        .fontColor(accentColor)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusCard)
  }

  @Builder
  FeaturedPostCard(item: Post) {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Image(item.authorAvatarUrl)
          .width(44)
          .height(44)
          .objectFit(ImageFit.Cover)
          .borderRadius(22)
        Column({ space: 4 }) {
          Text(item.authorName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(`${item.petName} · ${item.createdAt}`)
            .fontSize(12)
            .fontColor(PetPalTheme.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Text(item.content)
        .fontSize(16)
        .lineHeight(25)
        .fontColor(PetPalTheme.text)

      Row({ space: 8 }) {
        CapsuleChip(`#${item.topics[0]}`, PetPalTheme.primarySoft, PetPalTheme.primary)
        CapsuleChip(`喜欢 ${item.likeCount}`, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
      }

      Row({ space: 12 }) {
        if (item.imageUrls.length > 0) {
          Image(item.imageUrls[0])
            .width(118)
            .height(120)
            .objectFit(ImageFit.Cover)
            .borderRadius(PetPalTheme.radiusCard)
        } else {
          this.StoryImageBlock('正在恢复', `${item.imageUrls.length} 张照片`)
        }
        Column({ space: 10 }) {
          Text('社区会把一条记录留得更久一点')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text('把治疗、护理和心情写进同一条动态，回看时会更完整。')
            .fontSize(12)
            .lineHeight(20)
            .fontColor(PetPalTheme.textMuted)
          Button('读完整动态')
            .height(40)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(PetPalTheme.primary)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              void this.getUIContext().getRouter().pushUrl({ url: 'pages/PostDetail', params: { postId: `${item.id}` } })
            })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  StoryImageBlock(title: string, subtitle: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFF8F3')
      Text(subtitle)
        .fontSize(12)
        .fontColor('#F5E5D7')
    }
    .width(118)
    .height(120)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.End)
    .borderRadius(PetPalTheme.radiusCard)
    .linearGradient({
      angle: 145,
      colors: [[PetPalTheme.primary, 0.0], [PetPalTheme.primaryGlow, 1.0]]
    })
  }

  @Builder
  JournalPostCard(item: Post, featured: boolean) {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Image(item.authorAvatarUrl)
          .width(44)
          .height(44)
          .objectFit(ImageFit.Cover)
          .borderRadius(22)
        Column({ space: 4 }) {
          Text(item.authorName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(`${item.petName} · ${item.createdAt}`)
            .fontSize(12)
            .fontColor(PetPalTheme.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        CapsuleChip(`${item.commentCount} 评论`, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
      }
      .width('100%')

      Text(item.content)
        .fontSize(featured ? 16 : 14)
        .lineHeight(featured ? 25 : 22)
        .fontColor(PetPalTheme.text)
        .maxLines(featured ? 5 : 4)

      Row({ space: 10 }) {
        Column({ space: 0 }) {
          if (item.imageUrls.length > 0) {
            Image(item.imageUrls[0])
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(PetPalTheme.radiusCard)
          } else {
            this.StoryImageBlock('宠物图集', `${item.imageUrls.length} 张`)
          }
        }
        .width(featured ? 132 : 102)
        .height(featured ? 132 : 102)
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            ForEach(item.topics, (topic: string) => {
              CapsuleChip(`#${topic}`, PetPalTheme.primarySoft, PetPalTheme.primary)
            })
          }
          Row({ space: 8 }) {
            CapsuleChip(`喜欢 ${item.likeCount}`, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
            CapsuleChip('慢慢看', PetPalTheme.accentSoft, PetPalTheme.accent)
          }
          Button('查看详情')
            .height(38)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(featured ? PetPalTheme.primary : PetPalTheme.text)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              void this.getUIContext().getRouter().pushUrl({ url: 'pages/PostDetail', params: { postId: `${item.id}` } })
            })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(featured ? PetPalTheme.surfaceRaised : PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  ProviderStoryCard(item: ServiceProvider, featured: boolean) {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 6 }) {
          CapsuleChip(providerTypeText(item.type), providerSurface(item.type), providerTone(item.type))
          Text(item.name)
            .fontSize(featured ? 22 : 19)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(item.address)
            .fontSize(13)
            .lineHeight(20)
            .fontColor(PetPalTheme.textMuted)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 4 }) {
          Text(item.rating)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(providerTone(item.type))
          Text('评分')
            .fontSize(11)
            .fontColor(PetPalTheme.textSubtle)
        }
      }
      .width('100%')
      Row({ space: 10 }) {
        CapsuleChip(item.businessHours, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
        CapsuleChip('可直接预约', PetPalTheme.surface, PetPalTheme.textMuted)
      }
      Button(featured ? '查看这家机构' : '进入详情')
        .height(40)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(providerTone(item.type))
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.getUIContext().getRouter().pushUrl({ url: 'pages/ProviderDetail', params: { providerId: `${item.id}` } })
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(featured ? PetPalTheme.surfaceRaised : providerSurface(item.type))
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  AppointmentStoryCard(item: Appointment) {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 6 }) {
          Text(item.providerName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(`${item.serviceName} · ${item.petName}`)
            .fontSize(13)
            .fontColor(PetPalTheme.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        CapsuleChip(statusText(item.status), statusSurface(item.status), statusTone(item.status))
      }
      .width('100%')
      Text(item.appointmentTime)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(PetPalTheme.text)
      Text(item.remark.length > 0 ? item.remark : '暂无备注')
        .fontSize(12)
        .lineHeight(19)
        .fontColor(PetPalTheme.textMuted)
      Row({ space: 8 }) {
        CapsuleChip(item.orderNo, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
        CapsuleChip('到店前 10 分钟', PetPalTheme.surface, PetPalTheme.textMuted)
      }
      if (PetPalRepository.canCancelAppointment(item.status)) {
        Button('取消预约')
          .height(38)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(PetPalTheme.danger)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            void this.cancelAppointment(item.id)
          })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  ProviderBookingCard(item: ServiceProvider) {
    Row({ space: 14 }) {
      Column({ space: 8 }) {
        CapsuleChip(providerTypeText(item.type), providerSurface(item.type), providerTone(item.type))
        Text(item.name)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(PetPalTheme.text)
        Text(item.address)
          .fontSize(12)
          .lineHeight(19)
          .fontColor(PetPalTheme.textMuted)
          .maxLines(2)
        Text(`营业时间 ${item.businessHours}`)
          .fontSize(11)
          .fontColor(PetPalTheme.textSubtle)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: 10 }) {
        Text(item.rating)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(providerTone(item.type))
        Button('预约')
          .height(38)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(providerTone(item.type))
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            void this.getUIContext().getRouter().pushUrl({ url: 'pages/ProviderDetail', params: { providerId: `${item.id}` } })
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  ProfileHero() {
    Column({ space: 18 }) {
      Row() {
        Column({ space: 6 }) {
          Text(this.user.nickname)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text(this.user.bio)
            .fontSize(14)
            .lineHeight(22)
            .fontColor('#F5E8DB')
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Image(this.user.avatarUrl)
          .width(58)
          .height(58)
          .objectFit(ImageFit.Cover)
          .borderRadius(29)
      }
      .width('100%')
      Row({ space: 12 }) {
        this.ProfileMetric('关注', `${this.user.followingCount}`)
        this.ProfileMetric('粉丝', `${this.user.followerCount}`)
        this.ProfileMetric('宠物', `${this.pets.length}`)
      }
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 24, bottom: 22 })
    .borderRadius(PetPalTheme.radiusHero)
    .linearGradient({
      angle: 145,
      colors: [[PetPalTheme.primaryStrong, 0.0], [PetPalTheme.primary, 0.52], [PetPalTheme.primaryGlow, 1.0]]
    })
  }

  @Builder
  ProfileMetric(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFF8F3')
      Text(label)
        .fontSize(11)
        .fontColor('#F3DED0')
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor('rgba(255, 248, 243, 0.09)')
    .borderRadius(20)
  }

  @Builder
  PetArchiveCard(item: Pet) {
    Row({ space: 14 }) {
      Column({ space: 10 }) {
        if (item.avatarUrl.length > 0) {
          Image(item.avatarUrl)
            .width(54)
            .height(54)
            .objectFit(ImageFit.Cover)
            .borderRadius(27)
        } else {
          SoftAvatar(item.name.length > 0 ? item.name.substring(0, 1) : '宠', PetPalTheme.primarySoft, PetPalTheme.primary, 54)
        }
      }
      Column({ space: 8 }) {
        Text(item.name)
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor(PetPalTheme.text)
        Text(`${speciesText(item.species)} · ${item.breed.length > 0 ? item.breed : '未填写品种'} · ${genderText(item.gender)}`)
          .fontSize(13)
          .fontColor(PetPalTheme.textMuted)
        Row({ space: 8 }) {
          CapsuleChip(item.birthday.length > 0 ? `生日 ${item.birthday}` : '生日未填写', PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
          CapsuleChip(item.neutered ? '已绝育' : '未绝育', item.neutered ? PetPalTheme.successSoft : PetPalTheme.warningSoft, item.neutered ? PetPalTheme.success : PetPalTheme.warning)
        }
        Button('查看健康档案')
          .height(38)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(PetPalTheme.text)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            void this.getUIContext().getRouter().pushUrl({ url: 'pages/PetDetail', params: { petId: `${item.id}` } })
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
  }
}








