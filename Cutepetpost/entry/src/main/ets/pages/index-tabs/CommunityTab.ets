import { Pet, Post } from '../../models/PetPalModels';
import { PetPalTheme } from '../../ui/PetPalTheme';
import {
  CapsuleChip,
  EmptyStatePanel,
  LoginRequiredPanel,
  SectionLead,
  SoftAvatar,
  StoryImageBlock
} from './IndexTabShared';

export interface CommunityTabProps {
  isAuthenticated: boolean
  refreshing: boolean
  pets: Pet[]
  posts: Post[]
  communityMessage: string
  communityError: string
  postComposerVisible: boolean
  postSubmitting: boolean
  postUploading: boolean
  postActionId: number
  postContent: string
  selectedPostPetId: number
  postImageUrls: string[]
  userId: number
  onGoLogin: () => void
  onToggleComposer: () => void
  onPostContentChange: (value: string) => void
  onSelectPostPet: (petId: number) => void
  onUploadImages: () => void
  onSubmitPost: () => void
  onToggleLike: (post: Post) => void
  onDeletePost: (post: Post) => void
  onOpenPostDetail: (postId: number) => void
}

@Component
struct CommunityAuthorAvatar {
  @Prop imageUrl: string = ''
  @Prop label: string = '友'
  @Prop avatarSize: number = 44
  @State imageFailed: boolean = false

  build() {
    if (this.imageUrl.length > 0 && !this.imageFailed) {
      Image(this.imageUrl)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .objectFit(ImageFit.Cover)
        .borderRadius(this.avatarSize / 2)
        .onError(() => {
          this.imageFailed = true
        })
    } else {
      SoftAvatar(this.label, PetPalTheme.primarySoft, PetPalTheme.primary, this.avatarSize)
    }
  }
}

@Builder
function PostComposer($$: CommunityTabProps) {
  Column({ space: 12 }) {
    Text('发布社区动态')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(PetPalTheme.text)
    TextInput({ text: $$.postContent, placeholder: '分享一条照护记录' })
      .height(54)
      .backgroundColor(PetPalTheme.surface)
      .borderRadius(PetPalTheme.radiusImage)
      .padding({ left: 12, right: 12 })
      .onChange((value: string) => {
        $$.onPostContentChange(value)
      })
    Text('关联宠物')
      .fontSize(12)
      .fontColor(PetPalTheme.textSubtle)
    Row({ space: 8 }) {
      Button($$.selectedPostPetId === 0 ? '不关联宠物 已选' : '不关联宠物')
        .height(36)
        .fontSize(12)
        .fontColor($$.selectedPostPetId === 0 ? '#FFFFFF' : PetPalTheme.text)
        .backgroundColor($$.selectedPostPetId === 0 ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
        .borderRadius(PetPalTheme.radiusChip)
        .onClick(() => {
          $$.onSelectPostPet(0)
        })
      ForEach($$.pets, (pet: Pet) => {
        Button($$.selectedPostPetId === pet.id ? `${pet.name} 已选` : pet.name)
          .height(36)
          .fontSize(12)
          .fontColor($$.selectedPostPetId === pet.id ? '#FFFFFF' : PetPalTheme.text)
          .backgroundColor($$.selectedPostPetId === pet.id ? PetPalTheme.primary : PetPalTheme.surfaceWarm)
          .borderRadius(PetPalTheme.radiusChip)
          .onClick(() => {
            $$.onSelectPostPet(pet.id)
          })
      })
    }
    .width('100%')
    if ($$.pets.length === 0) {
      Text('当前账号下还没有宠物档案，默认按不关联宠物发布。')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(PetPalTheme.textMuted)
    }
    if ($$.postImageUrls.length > 0) {
      Row({ space: 8 }) {
        ForEach($$.postImageUrls, (imageUrl: string) => {
          Image(imageUrl)
            .width(72)
            .height(72)
            .objectFit(ImageFit.Cover)
            .borderRadius(PetPalTheme.radiusCard)
        })
      }
      .width('100%')
    }
    Row({ space: 10 }) {
      Button($$.postUploading ? '上传中...' : `添加图片 ${$$.postImageUrls.length}/9`)
        .height(40)
        .fontSize(13)
        .fontColor(PetPalTheme.primary)
        .backgroundColor(PetPalTheme.primarySoft)
        .borderRadius(PetPalTheme.radiusChip)
        .enabled(!$$.postUploading && !$$.postSubmitting && $$.postImageUrls.length < 9)
        .onClick(() => {
          $$.onUploadImages()
        })
      Button($$.postSubmitting ? '发布中...' : '发布')
        .height(40)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .enabled(!$$.postSubmitting && !$$.postUploading)
        .onClick(() => {
          $$.onSubmitPost()
        })
    }
    .width('100%')
  }
  .width('100%')
  .padding(18)
  .backgroundColor(PetPalTheme.surfaceRaised)
  .borderRadius(PetPalTheme.radiusPanel)
  .alignItems(HorizontalAlign.Start)
}

@Builder
function JournalPostCard(item: Post, featured: boolean, $$: CommunityTabProps) {
  Column({ space: 14 }) {
    Row({ space: 12 }) {
      CommunityAuthorAvatar({
        imageUrl: item.authorAvatarUrl,
        label: item.authorName.length > 0 ? item.authorName.substring(0, 1) : '友',
        avatarSize: 44
      })
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
          StoryImageBlock('宠物图集', `${item.imageUrls.length} 张`)
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
            $$.onOpenPostDetail(item.id)
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    Row({ space: 8 }) {
      Button(item.liked ? '取消喜欢' : '喜欢')
        .height(34)
        .fontSize(12)
        .fontColor(item.liked ? '#FFFFFF' : PetPalTheme.primary)
        .backgroundColor(item.liked ? PetPalTheme.primary : PetPalTheme.primarySoft)
        .borderRadius(PetPalTheme.radiusChip)
        .enabled($$.postActionId === 0 || $$.postActionId === item.id)
        .onClick(() => {
          $$.onToggleLike(item)
        })
      CapsuleChip(`${item.commentCount} 评论`, PetPalTheme.surfaceWarm, PetPalTheme.textMuted)
      Blank()
      if ($$.isAuthenticated && item.userId === $$.userId) {
        Button($$.postActionId === item.id ? '删除中...' : '删除')
          .height(34)
          .fontSize(12)
          .fontColor(PetPalTheme.danger)
          .backgroundColor(PetPalTheme.dangerSoft)
          .borderRadius(PetPalTheme.radiusChip)
          .enabled($$.postActionId === 0)
          .onClick(() => {
            $$.onDeletePost(item)
          })
      }
    }
    .width('100%')
  }
  .width('100%')
  .padding(18)
  .backgroundColor(featured ? PetPalTheme.surfaceRaised : PetPalTheme.surface)
  .borderRadius(PetPalTheme.radiusPanel)
}

@Builder
export function CommunityTab($$: CommunityTabProps) {
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
            .enabled($$.isAuthenticated)
            .onClick(() => {
              $$.onToggleComposer()
            })
        }
        .width('100%')
      }

      if ($$.communityMessage.length > 0) {
        Text($$.communityMessage)
          .fontSize(12)
          .fontColor(PetPalTheme.success)
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(PetPalTheme.successSoft)
          .borderRadius(16)
      }
      if ($$.communityError.length > 0) {
        Text($$.communityError)
          .fontSize(12)
          .fontColor(PetPalTheme.danger)
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(PetPalTheme.dangerSoft)
          .borderRadius(16)
      }
      if (!$$.isAuthenticated) {
        LoginRequiredPanel('登录后可以发布、点赞、评论并删除自己的帖子。', $$.onGoLogin)
      } else if ($$.postComposerVisible) {
        PostComposer($$)
      }
      if ($$.refreshing) {
        EmptyStatePanel('正在加载社区动态', '正在获取最新的社区内容。')
      } else if ($$.posts.length > 0) {
        ForEach($$.posts, (item: Post, index: number) => {
          JournalPostCard(item, index === 0, $$)
        })
      } else {
        EmptyStatePanel('还没有社区动态', '登录后发布第一条照护记录。')
      }
    }
    .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 120 })
  }
}
