import {
  Appointment,
  ServiceProvider
} from '../../models/PetPalModels';
import { PetPalRepository } from '../../repository/PetPalRepository';
import {
  PetPalTheme,
  providerSurface,
  providerTone,
  providerTypeText,
  statusSurface,
  statusText,
  statusTone
} from '../../ui/PetPalTheme';
import {
  CapsuleChip,
  EmptyStatePanel,
  LoginRequiredPanel,
  SectionLead
} from './IndexTabShared';

export interface BookingTabProps {
  isAuthenticated: boolean
  appointments: Appointment[]
  providers: ServiceProvider[]
  onGoLogin: () => void
  onCancelAppointment: (appointmentId: number) => void
  onOpenProvider: (providerId: number) => void
}

@Builder
function AppointmentStoryCard(item: Appointment, onCancelAppointment: (appointmentId: number) => void) {
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
          onCancelAppointment(item.id)
        })
    }
  }
  .width('100%')
  .padding(18)
  .backgroundColor(PetPalTheme.surfaceRaised)
  .borderRadius(PetPalTheme.radiusPanel)
}

@Builder
function ProviderBookingCard(item: ServiceProvider, onOpenProvider: (providerId: number) => void) {
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
          onOpenProvider(item.id)
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
export function BookingTab($$: BookingTabProps) {
  Scroll() {
    Column({ space: 24 }) {
      SectionLead('预约与照护', '先看今天的安排，再挑下一程服务', '预约页保留效率，但视觉像一本生活方式目录，不像表单列表。')
      if (!$$.isAuthenticated) {
        LoginRequiredPanel('登录后查看我的预约', $$.onGoLogin)
      } else if ($$.appointments.length > 0) {
        Column({ space: 12 }) {
          ForEach($$.appointments, (item: Appointment) => {
            AppointmentStoryCard(item, $$.onCancelAppointment)
          })
        }
      } else {
        EmptyStatePanel('暂无预约', '创建第一条预约后会显示在这里。')
      }
      SectionLead('继续发现', '把机构做成像值得信任的店铺名片', '信息明确，动作直接，但层级和节奏仍然保持轻松。')
      if ($$.providers.length > 0) {
        ForEach($$.providers, (item: ServiceProvider) => {
          ProviderBookingCard(item, $$.onOpenProvider)
        })
      } else {
        EmptyStatePanel('暂无机构数据', '请确认后端服务可用后刷新。')
      }
    }
    .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
  }
}
