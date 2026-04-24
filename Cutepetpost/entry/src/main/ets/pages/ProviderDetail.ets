import { Pet, ProviderType, ServiceItem, ServiceProvider } from '../models/PetPalModels';
import { AppointmentCreateInput, PetPalRepository } from '../repository/PetPalRepository';
import { PetPalTheme, providerSurface, providerTone, providerTypeText } from '../ui/PetPalTheme';

const APPOINTMENT_TIME_SLOTS: string[] = ['09:00', '10:30', '14:00', '15:30', '17:00'];
const APPOINTMENT_TIME_SLOT_FIRST_ROW: string[] = ['09:00', '10:30', '14:00'];
const APPOINTMENT_TIME_SLOT_SECOND_ROW: string[] = ['15:30', '17:00'];

interface AppointmentDateOption {
  value: string;
  label: string;
  description: string;
}

@Builder
function ProviderChip(label: string, backgroundColor: string, fontColor: string) {
  Text(label)
    .fontSize(11)
    .fontColor(fontColor)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusChip)
}

const EMPTY_PROVIDER: ServiceProvider = {
  id: 0,
  name: '机构信息加载中',
  type: ProviderType.HOSPITAL,
  address: '等待后端返回真实数据',
  phone: '',
  rating: '-',
  businessHours: '-',
  coverUrl: ''
}

@Entry
@Component
struct ProviderDetail {
  private providerId: number = Number((this.getUIContext().getRouter().getParams() as Record<string, string>).providerId ?? '1')
  @State provider: ServiceProvider = EMPTY_PROVIDER
  @State items: ServiceItem[] = []
  @State pets: Pet[] = []
  @State selectedServiceId: number = 0
  @State selectedPetId: number = 0
  @State selectedAppointmentDate: string = this.formatDate(new Date())
  @State selectedAppointmentSlot: string = ''
  @State remark: string = ''
  @State refreshError: string = ''
  @State actionError: string = ''
  @State actionMessage: string = ''
  @State creating: boolean = false

  aboutToAppear() {
    void this.refreshData()
  }

  private async refreshData(): Promise<void> {
    try {
      this.refreshError = ''
      const provider = await PetPalRepository.getProviderByIdAsync(this.providerId)
      const items = await PetPalRepository.getServicesAsync(this.providerId)
      this.provider = provider
      this.items = items
      if (items.length > 0 && this.selectedServiceId === 0) {
        this.selectedServiceId = items[0].id
      }
      if (PetPalRepository.getSession() !== null) {
        const remotePets = await PetPalRepository.getPetsAsync()
        this.pets = remotePets
        if (remotePets.length > 0 && this.selectedPetId === 0) {
          this.selectedPetId = remotePets[0].id
        }
      } else {
        this.pets = []
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.refreshError = `机构信息刷新失败：${message}`
    }
  }

  private formatDate(value: Date): string {
    const year = `${value.getFullYear()}`
    const month = `${value.getMonth() + 1}`.padStart(2, '0')
    const day = `${value.getDate()}`.padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  private buildDateOption(offsetDays: number, label: string): AppointmentDateOption {
    const date = new Date()
    date.setDate(date.getDate() + offsetDays)
    return {
      value: this.formatDate(date),
      label: label,
      description: this.formatDate(date)
    }
  }

  private getAppointmentDateOptions(): AppointmentDateOption[] {
    return [
      this.buildDateOption(0, '今天'),
      this.buildDateOption(1, '明天'),
      this.buildDateOption(2, '后天')
    ]
  }

  private buildCandidateDateTime(dateValue: string, slot: string): Date {
    const dateParts = dateValue.split('-')
    const timeParts = slot.split(':')
    return new Date(
      Number(dateParts[0]),
      Number(dateParts[1]) - 1,
      Number(dateParts[2]),
      Number(timeParts[0]),
      Number(timeParts[1]),
      0
    )
  }

  private getAvailableTimeSlots(dateValue: string): string[] {
    if (dateValue !== this.formatDate(new Date())) {
      return APPOINTMENT_TIME_SLOTS
    }
    const cutoff = new Date()
    cutoff.setMinutes(cutoff.getMinutes() + 30)
    return APPOINTMENT_TIME_SLOTS.filter((slot: string): boolean => {
      return this.buildCandidateDateTime(dateValue, slot).getTime() > cutoff.getTime()
    })
  }

  private selectAppointmentDate(value: string): void {
    this.selectedAppointmentDate = value
    const availableSlots = this.getAvailableTimeSlots(value)
    if (availableSlots.indexOf(this.selectedAppointmentSlot) < 0) {
      this.selectedAppointmentSlot = ''
    }
  }

  private buildAppointmentIntentTime(): string {
    if (this.selectedAppointmentDate.length === 0 || this.selectedAppointmentSlot.length === 0) {
      return ''
    }
    if (this.getAvailableTimeSlots(this.selectedAppointmentDate).indexOf(this.selectedAppointmentSlot) < 0) {
      return ''
    }
    return `${this.selectedAppointmentDate}T${this.selectedAppointmentSlot}:00`
  }

  private showActionError(message: string): void {
    this.actionError = message
    this.actionMessage = ''
    try {
      this.getUIContext().getPromptAction().showToast({ message: message })
    } catch (_) {
      // Keep the inline error visible even if toast is unavailable in a test/runtime context.
    }
  }

  private async submitAppointment(): Promise<void> {
    if (PetPalRepository.getSession() === null) {
      this.showActionError('请先登录后再预约')
      return
    }
    if (this.creating) {
      return
    }
    if (this.selectedServiceId === 0) {
      this.showActionError('请选择服务项目')
      return
    }
    if (this.selectedPetId === 0) {
      this.showActionError('请选择宠物')
      return
    }
    const appointmentTime = this.buildAppointmentIntentTime()
    if (appointmentTime.length === 0) {
      this.showActionError('请选择预约意向时间')
      return
    }
    this.creating = true
    this.actionError = ''
    this.actionMessage = ''
    try {
      const input: AppointmentCreateInput = {
        petId: this.selectedPetId,
        providerId: this.providerId,
        serviceId: this.selectedServiceId,
        appointmentTime: appointmentTime,
        remark: this.remark.trim()
      }
      const created = await PetPalRepository.createAppointment(input)
      this.actionMessage = `预约成功：${created.orderNo}`
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.actionError = `预约失败：${this.toAppointmentErrorMessage(message)}`
    } finally {
      this.creating = false
    }
  }

  private toAppointmentErrorMessage(message: string): string {
    if (message.includes('INVALID_APPOINTMENT_TIME')) {
      return '预约意向时间格式不正确'
    }
    if (message.includes('APPOINTMENT_TIME_IN_PAST')) {
      return '预约意向时间必须晚于当前时间'
    }
    if (message.includes('PET_NOT_AVAILABLE')) {
      return '请选择当前账号下的宠物'
    }
    if (message.includes('SERVICE_NOT_AVAILABLE')) {
      return '请选择该机构提供的服务项目'
    }
    return message
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        if (this.refreshError.length > 0) {
          Text(this.refreshError)
            .fontSize(12)
            .fontColor(PetPalTheme.warning)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(PetPalTheme.warningSoft)
            .borderRadius(PetPalTheme.radiusChip)
        }
        this.ProviderHero()
        this.ServiceSection()
        this.BookingCallout()
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 24 })
    }
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  ProviderHero() {
    Column({ space: 14 }) {
      if (this.provider.coverUrl.length > 0) {
        Image(this.provider.coverUrl)
          .width('100%')
          .height(170)
          .objectFit(ImageFit.Cover)
          .borderRadius(PetPalTheme.radiusPanel)
      }
      ProviderChip(providerTypeText(this.provider.type), 'rgba(255, 248, 243, 0.09)', '#FFF8F3')
      Text(this.provider.name)
        .fontSize(31)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFF8F3')
      Text(this.provider.address)
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#F3E4D6')
      Row({ space: 8 }) {
        ProviderChip(`评分 ${this.provider.rating}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
        ProviderChip(`营业 ${this.provider.businessHours}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
      }
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 24, bottom: 24 })
    .borderRadius(PetPalTheme.radiusHero)
    .linearGradient({
      angle: 145,
      colors: [[providerTone(this.provider.type), 0.0], [PetPalTheme.primary, 0.58], [PetPalTheme.primaryGlow, 1.0]]
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ServiceSection() {
    Column({ space: 14 }) {
      Text('服务项目')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text('信息保持准确，但整体节奏像一本精心排版的店铺菜单。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(PetPalTheme.textMuted)
      if (this.items.length > 0) {
        ForEach(this.items, (item: ServiceItem) => {
          Row({ space: 14 }) {
            Column({ space: 6 }) {
              Text(item.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(PetPalTheme.text)
              Text(item.duration)
                .fontSize(12)
                .fontColor(PetPalTheme.textMuted)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Column({ space: 8 }) {
              Text(item.price)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(providerTone(this.provider.type))
              Button(this.selectedServiceId === item.id ? '已选择' : '选择服务')
                .height(36)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(this.selectedServiceId === item.id ? PetPalTheme.text : providerTone(this.provider.type))
                .borderRadius(PetPalTheme.radiusChip)
                .onClick(() => {
                  this.selectedServiceId = item.id
                })
            }
          }
          .width('100%')
          .padding(18)
          .backgroundColor(this.selectedServiceId === item.id ? providerSurface(this.provider.type) : PetPalTheme.surfaceRaised)
          .borderRadius(PetPalTheme.radiusPanel)
        })
      } else {
        this.EmptyStatePanel('暂无服务项目', '服务项目会在后端返回真实数据后显示。')
      }
    }
    .width('100%')
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
  BookingCallout() {
    Column({ space: 12 }) {
      Text('准备预约')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Text('先选择服务和宠物，再提交预约意向时间。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(PetPalTheme.textMuted)
      Row({ space: 8 }) {
        if (this.provider.phone.length > 0) {
          ProviderChip(this.provider.phone, providerSurface(this.provider.type), providerTone(this.provider.type))
        }
        ProviderChip('支持到店预约', PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
      }
      Text('选择宠物')
        .fontSize(12)
        .fontColor(PetPalTheme.textSubtle)
      if (this.pets.length === 0) {
        Text('登录后可选择宠物并创建预约')
          .fontSize(12)
          .fontColor(PetPalTheme.textMuted)
      }
      Row({ space: 8 }) {
        ForEach(this.pets, (pet: Pet) => {
          Button(this.selectedPetId === pet.id ? `${pet.name} 已选` : pet.name)
            .height(36)
            .fontSize(12)
            .fontColor(this.selectedPetId === pet.id ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.selectedPetId === pet.id ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.selectedPetId = pet.id
            })
        })
      }
      this.AppointmentTimeSection()
      Text('备注')
        .fontSize(12)
        .fontColor(PetPalTheme.textSubtle)
      TextInput({ text: this.remark, placeholder: '可选：补充症状或需求' })
        .height(50)
        .backgroundColor(PetPalTheme.surfaceRaised)
        .borderRadius(18)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.remark = value
        })
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
      Button(this.creating ? '预约提交中...' : '立即预约')
        .width('100%')
        .height(50)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(providerTone(this.provider.type))
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          void this.submitAppointment()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surface)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AppointmentTimeSlotButton(slot: string) {
    Button(this.selectedAppointmentSlot === slot ? `${slot} 已选` : slot)
      .width(82)
      .height(36)
      .fontSize(12)
      .fontColor(this.selectedAppointmentSlot === slot ? '#FFFFFF' : PetPalTheme.text)
      .backgroundColor(this.selectedAppointmentSlot === slot ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
      .borderRadius(PetPalTheme.radiusChip)
      .onClick(() => {
        this.selectedAppointmentSlot = slot
      })
  }

  @Builder
  AppointmentTimeSection() {
    Column({ space: 10 }) {
      Text('预约意向时间')
        .fontSize(12)
        .fontColor(PetPalTheme.textSubtle)
      Text('选择预约意向时间，最终以机构确认为准')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(PetPalTheme.textMuted)
      Row({ space: 8 }) {
        ForEach(this.getAppointmentDateOptions(), (option: AppointmentDateOption) => {
          Button(this.selectedAppointmentDate === option.value ? `${option.label} 已选` : option.label)
            .height(36)
            .fontSize(12)
            .fontColor(this.selectedAppointmentDate === option.value ? '#FFFFFF' : PetPalTheme.text)
            .backgroundColor(this.selectedAppointmentDate === option.value ? providerTone(this.provider.type) : PetPalTheme.surfaceWarm)
            .borderRadius(PetPalTheme.radiusChip)
            .onClick(() => {
              this.selectAppointmentDate(option.value)
            })
        })
      }
        Text(this.selectedAppointmentDate)
          .fontSize(12)
          .fontColor(PetPalTheme.textMuted)
        if (this.getAvailableTimeSlots(this.selectedAppointmentDate).length > 0) {
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              ForEach(APPOINTMENT_TIME_SLOT_FIRST_ROW, (slot: string) => {
                if (this.getAvailableTimeSlots(this.selectedAppointmentDate).indexOf(slot) >= 0) {
                  this.AppointmentTimeSlotButton(slot)
                }
              })
            }
            Row({ space: 8 }) {
              ForEach(APPOINTMENT_TIME_SLOT_SECOND_ROW, (slot: string) => {
                if (this.getAvailableTimeSlots(this.selectedAppointmentDate).indexOf(slot) >= 0) {
                  this.AppointmentTimeSlotButton(slot)
                }
              })
            }
          }
          .alignItems(HorizontalAlign.Start)
        } else {
          Text('今天暂无可选时间')
            .fontSize(12)
          .fontColor(PetPalTheme.textMuted)
          .padding({ left: 12, right: 12, top: 9, bottom: 9 })
          .backgroundColor(PetPalTheme.surfaceRaised)
          .borderRadius(PetPalTheme.radiusChip)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}


