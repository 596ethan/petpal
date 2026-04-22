import {
  Appointment,
  Pet,
  PetGender,
  PetSpecies,
  Post,
  UserProfile
} from '../../models/PetPalModels';
import {
  PetPalTheme,
  genderText,
  speciesText
} from '../../ui/PetPalTheme';
import {
  CapsuleChip,
  EmptyStatePanel,
  LoginRequiredPanel,
  NotePanel,
  SectionLead,
  SoftAvatar
} from './IndexTabShared';

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
];

const PET_GENDER_OPTIONS: PetGenderOption[] = [
  { value: PetGender.FEMALE, label: '母' },
  { value: PetGender.MALE, label: '公' },
  { value: PetGender.UNKNOWN, label: '未知' }
];

export interface MineTabProps {
  isAuthenticated: boolean
  user: UserProfile
  pets: Pet[]
  posts: Post[]
  appointments: Appointment[]
  petArchiveMessage: string
  petArchiveError: string
  petCreateVisible: boolean
  creatingPet: boolean
  createPetName: string
  createPetSpecies: PetSpecies
  createPetBreed: string
  createPetGender: PetGender
  createPetBirthday: string
  createPetWeight: string
  createPetAvatarUrl: string
  createPetNeutered: boolean
  onGoLogin: () => void
  onTogglePetCreate: () => void
  onCreatePetNameChange: (value: string) => void
  onCreatePetBreedChange: (value: string) => void
  onCreatePetSpeciesChange: (value: PetSpecies) => void
  onCreatePetGenderChange: (value: PetGender) => void
  onCreatePetBirthdayChange: (value: string) => void
  onCreatePetWeightChange: (value: string) => void
  onCreatePetAvatarUrlChange: (value: string) => void
  onToggleCreatePetNeutered: () => void
  onSubmitCreatePet: () => void
  onOpenPetDetail: (petId: number) => void
}

@Builder
function ProfileMetric(label: string, value: string) {
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
function ProfileHero($$: MineTabProps) {
  Column({ space: 18 }) {
    Row() {
      Column({ space: 6 }) {
        Text($$.user.nickname)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF8F3')
        Text($$.user.bio)
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#F5E8DB')
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Image($$.user.avatarUrl)
        .width(58)
        .height(58)
        .objectFit(ImageFit.Cover)
        .borderRadius(29)
    }
    .width('100%')
    Row({ space: 12 }) {
      ProfileMetric('关注', `${$$.user.followingCount}`)
      ProfileMetric('粉丝', `${$$.user.followerCount}`)
      ProfileMetric('宠物', `${$$.pets.length}`)
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
function PetCreateForm($$: MineTabProps) {
  Column({ space: 12 }) {
    Text('新建宠物档案')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(PetPalTheme.text)
    TextInput({ text: $$.createPetName, placeholder: '宠物名称，必填' })
      .height(50)
      .backgroundColor(PetPalTheme.surface)
      .borderRadius(PetPalTheme.radiusImage)
      .padding({ left: 12, right: 12 })
      .onChange((value: string) => {
        $$.onCreatePetNameChange(value)
      })
    TextInput({ text: $$.createPetBreed, placeholder: '品种，可选' })
      .height(50)
      .backgroundColor(PetPalTheme.surface)
      .borderRadius(PetPalTheme.radiusImage)
      .padding({ left: 12, right: 12 })
      .onChange((value: string) => {
        $$.onCreatePetBreedChange(value)
      })
    Row({ space: 8 }) {
      ForEach(PET_SPECIES_OPTIONS, (option: PetSpeciesOption) => {
        Button(option.label)
          .height(34)
          .fontSize(12)
          .fontColor($$.createPetSpecies === option.value ? '#FFFFFF' : PetPalTheme.text)
          .backgroundColor($$.createPetSpecies === option.value ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            $$.onCreatePetSpeciesChange(option.value)
          })
      })
    }
    Row({ space: 8 }) {
      ForEach(PET_GENDER_OPTIONS, (option: PetGenderOption) => {
        Button(option.label)
          .height(34)
          .fontSize(12)
          .fontColor($$.createPetGender === option.value ? '#FFFFFF' : PetPalTheme.text)
          .backgroundColor($$.createPetGender === option.value ? PetPalTheme.accent : PetPalTheme.accentSoft)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            $$.onCreatePetGenderChange(option.value)
          })
      })
    }
    Row({ space: 10 }) {
      TextInput({ text: $$.createPetBirthday, placeholder: '生日（如 2026-04-21，可选）' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
        .onChange((value: string) => {
          $$.onCreatePetBirthdayChange(value)
        })
      TextInput({ text: $$.createPetWeight, placeholder: '体重（千克，可选）' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
        .onChange((value: string) => {
          $$.onCreatePetWeightChange(value)
        })
    }
    TextInput({ text: $$.createPetAvatarUrl, placeholder: '头像链接（可选）' })
      .height(50)
      .backgroundColor(PetPalTheme.surface)
      .borderRadius(PetPalTheme.radiusImage)
      .padding({ left: 12, right: 12 })
      .onChange((value: string) => {
        $$.onCreatePetAvatarUrlChange(value)
      })
    Button($$.createPetNeutered ? '已绝育' : '未绝育')
      .height(38)
      .fontSize(12)
      .fontColor($$.createPetNeutered ? '#FFFFFF' : PetPalTheme.text)
      .backgroundColor($$.createPetNeutered ? PetPalTheme.success : PetPalTheme.warningSoft)
      .borderRadius(PetPalTheme.radiusChip)
      .onClick(() => {
        $$.onToggleCreatePetNeutered()
      })
    Button($$.creatingPet ? '保存中...' : '保存宠物档案')
      .width('100%')
      .height(48)
      .fontSize(14)
      .fontColor('#FFFFFF')
      .backgroundColor(PetPalTheme.text)
      .borderRadius(PetPalTheme.radiusChip)
      .onClick(() => {
        $$.onSubmitCreatePet()
      })
  }
  .width('100%')
  .padding(18)
  .backgroundColor(PetPalTheme.surfaceRaised)
  .borderRadius(PetPalTheme.radiusPanel)
  .alignItems(HorizontalAlign.Start)
}

@Builder
function PetArchiveCard(item: Pet, onOpenPetDetail: (petId: number) => void) {
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
        CapsuleChip(
          item.neutered ? '已绝育' : '未绝育',
          item.neutered ? PetPalTheme.successSoft : PetPalTheme.warningSoft,
          item.neutered ? PetPalTheme.success : PetPalTheme.warning
        )
      }
      Button('查看健康档案')
        .height(38)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.text)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          onOpenPetDetail(item.id)
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

@Builder
export function MineTab($$: MineTabProps) {
  Scroll() {
    Column({ space: 24 }) {
      if (!$$.isAuthenticated) {
        LoginRequiredPanel('登录后查看我的资料和宠物档案', $$.onGoLogin)
      } else {
        ProfileHero($$)
        Row({ space: 12 }) {
          NotePanel('本周记录', `${$$.posts.length} 条动态`, '继续把恢复、洗护和日常都写下来。', PetPalTheme.primarySoft, PetPalTheme.primary)
          NotePanel(
            '下次提醒',
            $$.appointments.length > 0 ? $$.appointments[0].appointmentTime : '暂无预约',
            $$.appointments.length > 0 ? '下一程照护已经排进日历。' : '创建第一条预约后会显示在这里。',
            PetPalTheme.accentSoft,
            PetPalTheme.accent
          )
        }
        .width('100%')
        SectionLead('我的宠物档案', '每一只都有独立的照护叙事', '把体重、生日、绝育与提醒汇总成更有身份感的档案卡。')
        if ($$.petArchiveMessage.length > 0) {
          Text($$.petArchiveMessage)
            .fontSize(12)
            .fontColor(PetPalTheme.success)
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(PetPalTheme.successSoft)
            .borderRadius(16)
        }
        if ($$.petArchiveError.length > 0) {
          Text($$.petArchiveError)
            .fontSize(12)
            .fontColor(PetPalTheme.danger)
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(PetPalTheme.dangerSoft)
            .borderRadius(16)
        }
        Button($$.petCreateVisible ? '收起新建档案' : '新建宠物档案')
          .height(42)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(PetPalTheme.primary)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            $$.onTogglePetCreate()
          })
        if ($$.petCreateVisible) {
          PetCreateForm($$)
        }
        if ($$.pets.length > 0) {
          ForEach($$.pets, (item: Pet) => {
            PetArchiveCard(item, $$.onOpenPetDetail)
          })
        } else {
          EmptyStatePanel('暂无宠物档案', '当前账号还没有可显示的宠物数据。')
        }
      }
    }
    .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
  }
}
