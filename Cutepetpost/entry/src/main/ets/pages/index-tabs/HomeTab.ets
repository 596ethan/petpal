import {
  Appointment,
  Pet,
  Post,
  ServiceProvider
} from '../../models/PetPalModels';
import {
  PetPalTheme,
  providerSurface,
  providerTone,
  providerTypeText,
  speciesText,
  statusText,
  statusTone
} from '../../ui/PetPalTheme';
import {
  CapsuleChip,
  EmptyStatePanel,
  NotePanel,
  SectionLead,
  SoftAvatar,
  StoryImageBlock
} from './IndexTabShared';

export interface HomeTabProps {
  refreshError: string
  posts: Post[]
  providers: ServiceProvider[]
  pets: Pet[]
  appointments: Appointment[]
  onOpenCommunity: () => void
  onGoLogin: () => void
  onOpenPostDetail: (postId: number) => void
  onOpenProvider: (providerId: number) => void
}

@Builder
function HomeHero($$: HomeTabProps) {
  Stack({ alignContent: Alignment.TopEnd }) {
    Column({ space: 16 }) {
      CapsuleChip('宠物日记', 'rgba(255, 248, 243, 0.14)', '#FFF7EF')
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
            $$.onOpenCommunity()
          })
        Button('登录进入')
          .height(46)
          .fontSize(14)
          .fontColor('#FFF8F3')
          .backgroundColor('rgba(255, 248, 243, 0.14)')
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            $$.onGoLogin()
          })
      }
      Row({ space: 10 }) {
        CapsuleChip(`社群故事 ${$$.posts.length * 14}`, 'rgba(255, 248, 243, 0.12)', '#FFF8F3')
        CapsuleChip(`照护机构 ${$$.providers.length}`, 'rgba(255, 248, 243, 0.10)', '#FFF8F3')
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
function HomeMoodStrip($$: HomeTabProps) {
  Row({ space: 12 }) {
    if ($$.pets.length > 0) {
      NotePanel(
        '今日主角',
        $$.pets[0].name,
        `${speciesText($$.pets[0].species)} · ${$$.pets[0].weight}`,
        PetPalTheme.surfaceRaised,
        PetPalTheme.text
      )
    } else {
      NotePanel('今日主角', '暂无宠物', '请稍后刷新', PetPalTheme.surfaceRaised, PetPalTheme.text)
    }
    if ($$.appointments.length > 0) {
      NotePanel(
        '最近预约',
        statusText($$.appointments[0].status),
        `${$$.appointments[0].serviceName} · ${$$.appointments[0].petName}`,
        PetPalTheme.surfaceWarm,
        statusTone($$.appointments[0].status)
      )
    } else {
      NotePanel('最近预约', '暂无预约', '请稍后刷新', PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
    }
  }
  .width('100%')
}

@Builder
function ServiceCard(title: string, subtitle: string, marker: string, backgroundColor: string, accentColor: string) {
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
function ServiceSection() {
  Column({ space: 14 }) {
    SectionLead('生活服务', '服务入口保留，但退后半步', '三类入口继续存在，不过以轻量目录的方式出现，而不是首页的主视觉。')
    Row({ space: 12 }) {
      ServiceCard('医疗', '问诊、疫苗、体检', '照护', PetPalTheme.primarySoft, PetPalTheme.primary)
      ServiceCard('美容', '洗护、修剪、护理', '清洁', PetPalTheme.accentSoft, PetPalTheme.accent)
    }
    .width('100%')
    ServiceCard('寄养', '短住、长住、陪伴观察', '停留', PetPalTheme.tertiarySoft, '#9C7623')
  }
  .width('100%')
}

@Builder
function FeaturedPostCard(item: Post, onOpenPostDetail: (postId: number) => void) {
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
        StoryImageBlock('正在恢复', `${item.imageUrls.length} 张照片`)
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
            onOpenPostDetail(item.id)
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
function ProviderStoryCard(item: ServiceProvider, featured: boolean, onOpenProvider: (providerId: number) => void) {
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
        onOpenProvider(item.id)
      })
  }
  .width('100%')
  .padding(18)
  .backgroundColor(featured ? PetPalTheme.surfaceRaised : providerSurface(item.type))
  .borderRadius(PetPalTheme.radiusPanel)
}

@Builder
export function HomeTab($$: HomeTabProps) {
  Scroll() {
    Column({ space: 26 }) {
      if ($$.refreshError.length > 0) {
        Text($$.refreshError)
          .fontSize(12)
          .fontColor(PetPalTheme.warning)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(PetPalTheme.warningSoft)
          .borderRadius(PetPalTheme.radiusChip)
      }
      HomeHero($$)
      HomeMoodStrip($$)
      SectionLead('社群精选', '今天值得被记住的宠物片段', '首页第一屏先讲故事，再把护理和预约轻轻带出来。')
      if ($$.posts.length > 0) {
        FeaturedPostCard($$.posts[0], $$.onOpenPostDetail)
      }
      ServiceSection()
      SectionLead('收藏机构', '适合今天顺手预约的温柔去处', '把高频医疗、美容、寄养保留在第二层，不打断社区的入口感。')
      if ($$.providers.length > 0) {
        ForEach($$.providers, (item: ServiceProvider, index: number) => {
          ProviderStoryCard(item, index === 0, $$.onOpenProvider)
        })
      } else {
        EmptyStatePanel('暂无机构数据', '机构列表会在后端返回真实数据后显示。')
      }
    }
    .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
  }
}
