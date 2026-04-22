import { PetPalTheme } from '../../ui/PetPalTheme';

export interface IndexTabBarProps {
  currentTab: number
  onTabChange: (index: number) => void
}

@Builder
function IndexTabPill(symbol: string, label: string, index: number, $$: IndexTabBarProps) {
  Column({ space: 4 }) {
    Text(symbol)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor($$.currentTab === index ? '#FFFFFF' : PetPalTheme.textMuted)
    Text(label)
      .fontSize(11)
      .fontWeight($$.currentTab === index ? FontWeight.Medium : FontWeight.Regular)
      .fontColor($$.currentTab === index ? '#FFFFFF' : PetPalTheme.textMuted)
  }
  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
  .backgroundColor($$.currentTab === index ? PetPalTheme.primary : PetPalTheme.surface)
  .borderRadius(PetPalTheme.radiusChip)
  .layoutWeight(1)
  .onClick(() => {
    $$.onTabChange(index)
  })
}

@Builder
export function IndexTabBar($$: IndexTabBarProps) {
  Row({ space: 8 }) {
    IndexTabPill('舍', '首页', 0, $$)
    IndexTabPill('圈', '社区', 1, $$)
    IndexTabPill('约', '预约', 2, $$)
    IndexTabPill('我', '我的', 3, $$)
  }
  .padding({ left: 10, right: 10, top: 10, bottom: 10 })
  .margin({ left: 18, right: 18, bottom: 18 })
  .backgroundColor(PetPalTheme.overlay)
  .borderRadius(PetPalTheme.radiusPanel)
  .width('90%')
}
