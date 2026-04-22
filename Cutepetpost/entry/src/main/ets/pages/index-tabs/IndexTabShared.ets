import { PetPalTheme } from '../../ui/PetPalTheme';

@Builder
export function SectionLead(eyebrow: string, title: string, subtitle: string) {
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
export function CapsuleChip(label: string, backgroundColor: string, fontColor: string) {
  Text(label)
    .fontSize(11)
    .fontColor(fontColor)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusChip)
}

@Builder
export function SoftAvatar(label: string, backgroundColor: string, fontColor: string, size: number = 44) {
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

@Builder
export function EmptyStatePanel(title: string, subtitle: string) {
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
export function LoginRequiredPanel(message: string, onGoLogin: () => void) {
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
        onGoLogin()
      })
  }
  .width('100%')
  .padding(18)
  .backgroundColor(PetPalTheme.surfaceRaised)
  .borderRadius(PetPalTheme.radiusPanel)
  .alignItems(HorizontalAlign.Start)
}

@Builder
export function NotePanel(title: string, value: string, subtitle: string, backgroundColor: string, accentColor: string) {
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
export function StoryImageBlock(title: string, subtitle: string) {
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
