import {
  HealthRecord,
  HealthRecordCreateInput,
  Pet,
  PetGender,
  PetSpecies,
  PetUpdateInput,
  VaccineRecord,
  VaccineRecordCreateInput
} from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
import { genderText, PetPalTheme, petAvatarLabel, speciesText } from '../ui/PetPalTheme';

@Builder
function DetailHeader(eyebrow: string, title: string, subtitle: string) {
  Column({ space: 6 }) {
    Text(eyebrow)
      .fontSize(11)
      .fontColor(PetPalTheme.primary)
      .letterSpacing(1.2)
    Text(title)
      .fontSize(24)
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
function DetailChip(label: string, backgroundColor: string, fontColor: string) {
  Text(label)
    .fontSize(11)
    .fontColor(fontColor)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusChip)
}

interface DetailSpeciesOption {
  value: PetSpecies
  label: string
}

interface DetailGenderOption {
  value: PetGender
  label: string
}

interface HealthRecordTypeOption {
  value: string
  label: string
}

const DETAIL_SPECIES_OPTIONS: DetailSpeciesOption[] = [
  { value: PetSpecies.CAT, label: '猫咪' },
  { value: PetSpecies.DOG, label: '狗狗' },
  { value: PetSpecies.RABBIT, label: '兔兔' },
  { value: PetSpecies.BIRD, label: '鸟类' },
  { value: PetSpecies.OTHER, label: '其他' }
]

const DETAIL_GENDER_OPTIONS: DetailGenderOption[] = [
  { value: PetGender.FEMALE, label: '母' },
  { value: PetGender.MALE, label: '公' },
  { value: PetGender.UNKNOWN, label: '未知' }
]

const HEALTH_RECORD_TYPE_OPTIONS: HealthRecordTypeOption[] = [
  { value: 'CHECKUP', label: '体检' },
  { value: 'MEDICATION', label: '用药' },
  { value: 'SURGERY', label: '手术' },
  { value: 'VACCINE', label: '疫苗' }
]

const EMPTY_PET: Pet = {
  id: 0,
  name: '',
  species: PetSpecies.OTHER,
  breed: '',
  gender: PetGender.UNKNOWN,
  birthday: '',
  weight: '',
  avatarUrl: '',
  neutered: false
}

@Entry
@Component
struct PetDetail {
  private petId: number = Number((this.getUIContext().getRouter().getParams() as Record<string, string>).petId ?? '0')
  @State pet: Pet = EMPTY_PET
  @State health: HealthRecord[] = []
  @State vaccines: VaccineRecord[] = []
  @State loading: boolean = true
  @State notFound: boolean = false
  @State refreshError: string = ''
  @State actionMessage: string = ''
  @State actionError: string = ''
  @State editingPet: boolean = false
  @State savingPet: boolean = false
  @State deletingPet: boolean = false
  @State healthFormVisible: boolean = false
  @State vaccineFormVisible: boolean = false
  @State savingHealth: boolean = false
  @State savingVaccine: boolean = false
  @State editName: string = ''
  @State editSpecies: PetSpecies = PetSpecies.OTHER
  @State editBreed: string = ''
  @State editGender: PetGender = PetGender.UNKNOWN
  @State editBirthday: string = ''
  @State editWeight: string = ''
  @State editAvatarUrl: string = ''
  @State editNeutered: boolean = false
  @State healthRecordType: string = 'CHECKUP'
  @State healthTitle: string = ''
  @State healthDescription: string = ''
  @State healthRecordDate: string = ''
  @State healthNextDate: string = ''
  @State vaccineName: string = ''
  @State vaccineDate: string = ''
  @State vaccineNextDue: string = ''
  @State vaccineHospital: string = ''

  aboutToAppear() {
    void this.refreshData()
  }

  private async refreshData(): Promise<void> {
    if (this.petId <= 0) {
      this.loading = false
      this.notFound = true
      this.refreshError = ''
      return
    }
    try {
      this.loading = true
      this.notFound = false
      this.refreshError = ''
      const pet = await PetPalRepository.getPetByIdAsync(this.petId)
      const health = await PetPalRepository.getHealthRecordsAsync(this.petId)
      const vaccines = await PetPalRepository.getVaccinesAsync(this.petId)
      this.pet = pet
      this.health = health
      this.vaccines = vaccines
      if (!this.editingPet) {
        this.syncEditForm(pet)
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (this.isNotFoundMessage(message)) {
        this.notFound = true
        this.refreshError = ''
      } else {
        this.refreshError = `健康档案刷新失败：${message}`
      }
    } finally {
      this.loading = false
    }
  }

  private isNotFoundMessage(message: string): boolean {
    return message.indexOf('PET_NOT_FOUND') >= 0 || message.indexOf('Pet not found') >= 0 || message.indexOf('not found') >= 0
  }

  private syncEditForm(pet: Pet): void {
    this.editName = pet.name
    this.editSpecies = pet.species
    this.editBreed = pet.breed
    this.editGender = pet.gender
    this.editBirthday = pet.birthday
    this.editWeight = pet.weight
    this.editAvatarUrl = pet.avatarUrl
    this.editNeutered = pet.neutered
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

  private startEditingPet(): void {
    this.syncEditForm(this.pet)
    this.editingPet = true
    this.actionError = ''
    this.actionMessage = ''
  }

  private async submitPetUpdate(): Promise<void> {
    if (this.savingPet) {
      return
    }
    const name = this.editName.trim()
    if (name.length === 0) {
      this.actionError = '请输入宠物名称'
      return
    }
    try {
      this.savingPet = true
      this.actionError = ''
      this.actionMessage = ''
      const input: PetUpdateInput = {
        name: name,
        species: this.editSpecies,
        breed: this.editBreed.trim(),
        gender: this.editGender,
        avatarUrl: this.editAvatarUrl.trim(),
        neutered: this.editNeutered
      }
      const birthday = this.editBirthday.trim()
      const weight = this.optionalPositiveNumber(this.editWeight, '体重')
      if (birthday.length > 0) {
        input.birthday = birthday
      }
      if (weight !== undefined) {
        input.weight = weight
      }
      const updated = await PetPalRepository.updatePet(this.petId, input)
      this.pet = updated
      this.syncEditForm(updated)
      this.editingPet = false
      this.actionMessage = '宠物档案已更新'
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (this.isNotFoundMessage(message)) {
        this.notFound = true
      } else {
        this.actionError = `更新宠物档案失败：${message}`
      }
    } finally {
      this.savingPet = false
    }
  }

  private async deletePet(): Promise<void> {
    if (this.deletingPet) {
      return
    }
    try {
      this.deletingPet = true
      this.actionError = ''
      await PetPalRepository.deletePet(this.petId)
      this.getUIContext().getPromptAction().showToast({ message: '已删除' })
      this.getUIContext().getRouter().back()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (this.isNotFoundMessage(message)) {
        this.notFound = true
      } else {
        this.actionError = `删除宠物档案失败：${message}`
      }
    } finally {
      this.deletingPet = false
    }
  }

  private resetHealthForm(): void {
    this.healthRecordType = 'CHECKUP'
    this.healthTitle = ''
    this.healthDescription = ''
    this.healthRecordDate = ''
    this.healthNextDate = ''
  }

  private async submitHealthRecord(): Promise<void> {
    if (this.savingHealth) {
      return
    }
    const title = this.healthTitle.trim()
    const recordDate = this.healthRecordDate.trim()
    if (title.length === 0 || recordDate.length === 0) {
      this.actionError = '请填写健康记录标题和日期'
      return
    }
    try {
      this.savingHealth = true
      this.actionError = ''
      this.actionMessage = ''
      const input: HealthRecordCreateInput = {
        recordType: this.healthRecordType,
        title: title,
        recordDate: recordDate
      }
      const description = this.healthDescription.trim()
      const nextDate = this.healthNextDate.trim()
      if (description.length > 0) {
        input.description = description
      }
      if (nextDate.length > 0) {
        input.nextDate = nextDate
      }
      await PetPalRepository.addHealthRecord(this.petId, input)
      this.resetHealthForm()
      this.healthFormVisible = false
      this.actionMessage = '健康记录已添加'
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (this.isNotFoundMessage(message)) {
        this.notFound = true
      } else {
        this.actionError = `添加健康记录失败：${message}`
      }
    } finally {
      this.savingHealth = false
    }
  }

  private resetVaccineForm(): void {
    this.vaccineName = ''
    this.vaccineDate = ''
    this.vaccineNextDue = ''
    this.vaccineHospital = ''
  }

  private async submitVaccineRecord(): Promise<void> {
    if (this.savingVaccine) {
      return
    }
    const vaccineName = this.vaccineName.trim()
    const vaccinatedAt = this.vaccineDate.trim()
    if (vaccineName.length === 0 || vaccinatedAt.length === 0) {
      this.actionError = '请填写疫苗名称和接种日期'
      return
    }
    try {
      this.savingVaccine = true
      this.actionError = ''
      this.actionMessage = ''
      const input: VaccineRecordCreateInput = {
        vaccineName: vaccineName,
        vaccinatedAt: vaccinatedAt
      }
      const nextDueAt = this.vaccineNextDue.trim()
      const hospital = this.vaccineHospital.trim()
      if (nextDueAt.length > 0) {
        input.nextDueAt = nextDueAt
      }
      if (hospital.length > 0) {
        input.hospital = hospital
      }
      await PetPalRepository.addVaccineRecord(this.petId, input)
      this.resetVaccineForm()
      this.vaccineFormVisible = false
      this.actionMessage = '疫苗记录已添加'
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (this.isNotFoundMessage(message)) {
        this.notFound = true
      } else {
        this.actionError = `添加疫苗记录失败：${message}`
      }
    } finally {
      this.savingVaccine = false
    }
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        if (this.loading) {
          this.StatePanel('正在加载宠物档案', '正在从后端读取最新资料。', PetPalTheme.surfaceRaised, PetPalTheme.textMuted)
        } else if (this.notFound) {
          this.NotFoundPanel()
        } else {
          if (this.refreshError.length > 0) {
            Text(this.refreshError)
              .fontSize(12)
              .fontColor(PetPalTheme.warning)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(PetPalTheme.warningSoft)
              .borderRadius(PetPalTheme.radiusChip)
          }
          if (this.actionMessage.length > 0) {
            Text(this.actionMessage)
              .fontSize(12)
              .fontColor(PetPalTheme.success)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(PetPalTheme.successSoft)
              .borderRadius(16)
          }
          if (this.actionError.length > 0) {
            Text(this.actionError)
              .fontSize(12)
              .fontColor(PetPalTheme.danger)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(PetPalTheme.dangerSoft)
              .borderRadius(16)
          }
          this.PetHero()
          this.PetActions()
          if (this.editingPet) {
            this.PetEditForm()
          }

          DetailHeader('健康时间线', '把重要节点整理成一条温柔而清楚的记录', '就诊、体检和驱虫不再散落在不同入口里，而是按时间顺序被慢慢收好。')
          Button(this.healthFormVisible ? '收起健康记录' : '添加健康记录')
            .height(42)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(PetPalTheme.primary)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.healthFormVisible = !this.healthFormVisible
              this.actionError = ''
            })
          if (this.healthFormVisible) {
            this.HealthRecordForm()
          }
          if (this.health.length > 0) {
            ForEach(this.health, (item: HealthRecord) => {
              this.HealthCard(item)
            })
          } else {
            this.StatePanel('暂无健康记录', '添加第一条体检、用药或手术记录。', PetPalTheme.surfaceRaised, PetPalTheme.textMuted)
          }

          DetailHeader('疫苗记录', '下一次到期时间一眼能看到', '保留医疗信息的准确性，同时把阅读体验做得更平和。')
          Button(this.vaccineFormVisible ? '收起疫苗记录' : '添加疫苗记录')
            .height(42)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(PetPalTheme.accent)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.vaccineFormVisible = !this.vaccineFormVisible
              this.actionError = ''
            })
          if (this.vaccineFormVisible) {
            this.VaccineRecordForm()
          }
          if (this.vaccines.length > 0) {
            ForEach(this.vaccines, (item: VaccineRecord) => {
              this.VaccineCard(item)
            })
          } else {
            this.StatePanel('暂无疫苗记录', '添加疫苗名称和接种日期后会显示在这里。', PetPalTheme.surface, PetPalTheme.textMuted)
          }
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 24 })
    }
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  NotFoundPanel() {
    Column({ space: 12 }) {
      Text('宠物档案不存在')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text('这条档案可能已被删除，或不属于当前账号。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(PetPalTheme.textMuted)
      Button('返回上一页')
        .height(42)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          this.getUIContext().getRouter().back()
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatePanel(title: string, subtitle: string, backgroundColor: string, fontColor: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text(subtitle)
        .fontSize(12)
        .lineHeight(19)
        .fontColor(fontColor)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PetHero() {
    Column({ space: 16 }) {
      Row({ space: 14 }) {
        if (this.pet.avatarUrl.length > 0) {
          Image(this.pet.avatarUrl)
            .width(62)
            .height(62)
            .objectFit(ImageFit.Cover)
            .borderRadius(31)
        } else {
          Text(petAvatarLabel(this.pet.name))
            .width(62)
            .height(62)
            .textAlign(TextAlign.Center)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.primaryStrong)
            .backgroundColor('#FFF8F3')
            .borderRadius(31)
            .padding({ top: 15 })
        }
        Column({ space: 6 }) {
          Text(this.pet.name)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text(`${speciesText(this.pet.species)} · ${this.pet.breed.length > 0 ? this.pet.breed : '未填写品种'} · ${genderText(this.pet.gender)}`)
            .fontSize(13)
            .fontColor('#F5E8DB')
          Text(`体重 ${this.pet.weight.length > 0 ? this.pet.weight + 'kg' : '未填写'} · 生日 ${this.pet.birthday.length > 0 ? this.pet.birthday : '未填写'}`)
            .fontSize(12)
            .fontColor('#F2DDCC')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      Row({ space: 8 }) {
        DetailChip(this.pet.neutered ? '已绝育' : '未绝育', 'rgba(255, 248, 243, 0.09)', '#FFF8F3')
        DetailChip('健康档案', 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
      }
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 24, bottom: 22 })
    .borderRadius(PetPalTheme.radiusHero)
    .linearGradient({
      angle: 145,
      colors: [[PetPalTheme.primaryStrong, 0.0], [PetPalTheme.primary, 0.52], [PetPalTheme.primaryGlow, 1.0]]
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PetActions() {
    Row({ space: 10 }) {
      Button(this.editingPet ? '收起编辑' : '编辑资料')
        .height(42)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.text)
        .borderRadius(PetPalTheme.radiusChip)
        .layoutWeight(1)
        .onClick(() => {
          if (this.editingPet) {
            this.editingPet = false
          } else {
            this.startEditingPet()
          }
        })
      Button(this.deletingPet ? '删除中...' : '删除档案')
        .height(42)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.danger)
        .borderRadius(PetPalTheme.radiusChip)
        .layoutWeight(1)
        .onClick(() => {
          void this.deletePet()
        })
    }
    .width('100%')
  }

  @Builder
  PetEditForm() {
    Column({ space: 12 }) {
      Text('编辑宠物信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      TextInput({ text: this.editName, placeholder: '宠物名称，必填' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.editName = value
        })
      TextInput({ text: this.editBreed, placeholder: '品种，可选' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.editBreed = value
        })
      Row({ space: 8 }) {
        ForEach(DETAIL_SPECIES_OPTIONS, (option: DetailSpeciesOption) => {
          Button(option.label)
            .height(34)
            .fontSize(12)
            .fontColor(this.editSpecies === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.editSpecies === option.value ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.editSpecies = option.value
            })
        })
      }
      Row({ space: 8 }) {
        ForEach(DETAIL_GENDER_OPTIONS, (option: DetailGenderOption) => {
          Button(option.label)
            .height(34)
            .fontSize(12)
            .fontColor(this.editGender === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.editGender === option.value ? PetPalTheme.accent : PetPalTheme.accentSoft)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.editGender = option.value
            })
        })
      }
      Row({ space: 10 }) {
        TextInput({ text: this.editBirthday, placeholder: '生日（如 2026-04-21，可选）' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.editBirthday = value
          })
        TextInput({ text: this.editWeight, placeholder: '体重（千克，可选）' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.editWeight = value
          })
      }
      TextInput({ text: this.editAvatarUrl, placeholder: '头像链接（可选）' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.editAvatarUrl = value
        })
      Button(this.editNeutered ? '已绝育' : '未绝育')
        .height(38)
        .fontSize(12)
        .fontColor(this.editNeutered ? '#FFFFFF' : PetPalTheme.text)
        .backgroundColor(this.editNeutered ? PetPalTheme.success : PetPalTheme.warningSoft)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          this.editNeutered = !this.editNeutered
        })
      Button(this.savingPet ? '保存中...' : '保存修改')
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.submitPetUpdate()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HealthRecordForm() {
    Column({ space: 12 }) {
      Text('添加健康记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Row({ space: 8 }) {
        ForEach(HEALTH_RECORD_TYPE_OPTIONS, (option: HealthRecordTypeOption) => {
          Button(option.label)
            .height(34)
            .fontSize(12)
            .fontColor(this.healthRecordType === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.healthRecordType === option.value ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.healthRecordType = option.value
            })
        })
      }
      TextInput({ text: this.healthTitle, placeholder: '标题，必填' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.healthTitle = value
        })
      TextInput({ text: this.healthDescription, placeholder: '说明，可选' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.healthDescription = value
        })
      Row({ space: 10 }) {
        TextInput({ text: this.healthRecordDate, placeholder: '记录日期，必填' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.healthRecordDate = value
          })
        TextInput({ text: this.healthNextDate, placeholder: '下次日期，可选' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.healthNextDate = value
          })
      }
      Button(this.savingHealth ? '保存中...' : '保存健康记录')
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.submitHealthRecord()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  VaccineRecordForm() {
    Column({ space: 12 }) {
      Text('添加疫苗记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      TextInput({ text: this.vaccineName, placeholder: '疫苗名称，必填' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.vaccineName = value
        })
      Row({ space: 10 }) {
        TextInput({ text: this.vaccineDate, placeholder: '接种日期，必填' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.vaccineDate = value
          })
        TextInput({ text: this.vaccineNextDue, placeholder: '下次日期，可选' })
          .height(50)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusImage)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.vaccineNextDue = value
          })
      }
      TextInput({ text: this.vaccineHospital, placeholder: '机构，可选' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusImage)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.vaccineHospital = value
        })
      Button(this.savingVaccine ? '保存中...' : '保存疫苗记录')
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.accent)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.submitVaccineRecord()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HealthCard(item: HealthRecord) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(item.recordDate)
            .fontSize(12)
            .fontColor(PetPalTheme.textSubtle)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        DetailChip(item.nextDate.length > 0 ? '下次 ' + item.nextDate : '无下次提醒', PetPalTheme.surfaceWarm, PetPalTheme.primary)
      }
      .width('100%')
      Text(item.summary.length > 0 ? item.summary : '暂无说明')
        .fontSize(13)
        .lineHeight(21)
        .fontColor(PetPalTheme.textMuted)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
  }

  @Builder
  VaccineCard(item: VaccineRecord) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(item.vaccineName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
          Text(item.hospital.length > 0 ? item.hospital : '未填写机构')
            .fontSize(12)
            .fontColor(PetPalTheme.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        DetailChip(item.nextDueAt.length > 0 ? '下次 ' + item.nextDueAt : '无下次提醒', PetPalTheme.primarySoft, PetPalTheme.primary)
      }
      .width('100%')
      Text(`接种日期 ${item.vaccinatedAt}`)
        .fontSize(13)
        .fontColor(PetPalTheme.textMuted)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusPanel)
  }
}
