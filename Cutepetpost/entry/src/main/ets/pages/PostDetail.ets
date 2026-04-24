import { CommentItem, Post } from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
import { UserProfile } from '../models/PetPalModels';
import { PetPalTheme } from '../ui/PetPalTheme';
import { SoftAvatar } from './index-tabs/IndexTabShared';

@Builder
function PostChip(label: string, backgroundColor: string, fontColor: string) {
  Text(label)
    .fontSize(11)
    .fontColor(fontColor)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .backgroundColor(backgroundColor)
    .borderRadius(PetPalTheme.radiusChip)
}

const EMPTY_USER: UserProfile = {
  id: 0,
  nickname: '',
  bio: '',
  avatarUrl: '',
  followingCount: 0,
  followerCount: 0
}

@Component
struct PostAuthorAvatar {
  @Prop imageUrl: string = ''
  @Prop label: string = '友'
  @Prop avatarSize: number = 52
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
      SoftAvatar(this.label, 'rgba(255, 248, 243, 0.14)', '#FFF8F3', this.avatarSize)
    }
  }
}

@Entry
@Component
struct PostDetail {
  private readonly postId: number = Number((this.getUIContext().getRouter().getParams() as Record<string, string>).postId ?? '1')
  private readonly initialPost: Post | null = PetPalRepository.getPostById(this.postId)
  @State post: Post | null = this.initialPost
  @State comments: CommentItem[] = PetPalRepository.getComments(this.postId)
  @State currentUser: UserProfile = PetPalRepository.getSession()?.profile ?? EMPTY_USER
  @State loading: boolean = this.initialPost === null
  @State actionSubmitting: boolean = false
  @State commentSubmitting: boolean = false
  @State notFound: boolean = false
  @State errorMessage: string = ''
  @State successMessage: string = ''
  @State commentText: string = ''

  aboutToAppear() {
    void this.refreshPost()
  }

  private async refreshPost(): Promise<void> {
    try {
      this.loading = true
      this.errorMessage = ''
      this.notFound = false
      this.currentUser = PetPalRepository.getSession()?.profile ?? EMPTY_USER
      this.post = await PetPalRepository.getPostByIdAsync(this.postId)
      this.comments = await PetPalRepository.getCommentsAsync(this.postId)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = message
      this.notFound = message.indexOf('Post not found') >= 0 || message.indexOf('POST_NOT_FOUND') >= 0
      if (this.notFound) {
        this.post = null
        this.comments = []
      }
    } finally {
      this.loading = false
    }
  }

  private async toggleLike(): Promise<void> {
    const post = this.post
    if (this.actionSubmitting || post === null) {
      return
    }
    try {
      this.actionSubmitting = true
      this.errorMessage = ''
      this.post = post.liked ? await PetPalRepository.unlikePost(post.id) : await PetPalRepository.likePost(post.id)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `点赞状态更新失败：${message}`
    } finally {
      this.actionSubmitting = false
    }
  }

  private async deletePost(): Promise<void> {
    const post = this.post
    if (this.actionSubmitting || post === null || post.userId !== this.currentUser.id) {
      return
    }
    try {
      this.actionSubmitting = true
      this.errorMessage = ''
      await PetPalRepository.deletePost(post.id)
      this.successMessage = '帖子已删除'
      this.getUIContext().getRouter().back()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `删除失败：${message}`
    } finally {
      this.actionSubmitting = false
    }
  }

  private async submitComment(): Promise<void> {
    const post = this.post
    if (this.commentSubmitting || post === null) {
      return
    }
    const content = this.commentText.trim()
    if (content.length === 0) {
      this.errorMessage = '请输入评论内容。'
      return
    }
    try {
      this.commentSubmitting = true
      this.errorMessage = ''
      await PetPalRepository.addComment(post.id, { content: content })
      this.commentText = ''
      this.comments = await PetPalRepository.getCommentsAsync(post.id)
      this.post = await PetPalRepository.getPostByIdAsync(post.id)
      this.successMessage = '评论已发布'
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `评论失败：${message}`
    } finally {
      this.commentSubmitting = false
    }
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        if (this.loading) {
          Text('正在加载帖子...')
            .fontSize(16)
            .fontColor(PetPalTheme.textMuted)
            .width('100%')
        } else if (this.notFound || this.post === null) {
          if (this.errorMessage.length > 0 && !this.notFound) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor(PetPalTheme.danger)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(PetPalTheme.dangerSoft)
              .borderRadius(16)
          }
          Text(this.notFound ? '帖子不存在' : '暂时无法加载帖子')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
            .width('100%')
          Text(this.notFound ? '这条帖子可能已被删除。' : '请稍后重试或返回社区列表。')
            .fontSize(13)
            .fontColor(PetPalTheme.textMuted)
            .width('100%')
        } else {
          this.PostBody(this.post)
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 24 })
    }
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  PostBody(post: Post) {
    Column({ space: 22 }) {
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(PetPalTheme.danger)
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(PetPalTheme.dangerSoft)
          .borderRadius(16)
      }
      if (this.successMessage.length > 0) {
        Text(this.successMessage)
          .fontSize(12)
          .fontColor(PetPalTheme.success)
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(PetPalTheme.successSoft)
          .borderRadius(16)
      }
      this.StoryHero(post)
      this.ImageBand(post)
      this.CommentSection()
    }
    .width('100%')
  }

  @Builder
  StoryHero(post: Post) {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        PostAuthorAvatar({
          imageUrl: post.authorAvatarUrl,
          label: post.authorName.length > 0 ? post.authorName.substring(0, 1) : '友',
          avatarSize: 52
        })
        Column({ space: 5 }) {
          Text(post.authorName)
            .fontSize(27)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text(`${post.petName} · ${post.createdAt}`)
            .fontSize(13)
            .fontColor('#F3E4D6')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      Text(post.content)
        .fontSize(15)
        .lineHeight(24)
        .fontColor('#FFF8F3')
      Row({ space: 8 }) {
        ForEach(post.topics, (topic: string) => {
          PostChip(`#${topic}`, 'rgba(255, 248, 243, 0.09)', '#FFF8F3')
        })
      }
      Row({ space: 8 }) {
        PostChip(`喜欢 ${post.likeCount}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
        PostChip(`评论 ${post.commentCount}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
      }
      Row({ space: 8 }) {
        Button(post.liked ? '取消喜欢' : '喜欢')
          .height(38)
          .fontSize(13)
          .fontColor(post.liked ? PetPalTheme.primary : '#FFFFFF')
          .backgroundColor(post.liked ? '#FFF8F3' : PetPalTheme.primaryStrong)
          .borderRadius(PetPalTheme.radiusChip)
          .enabled(!this.actionSubmitting)
          .onClick(() => {
            void this.toggleLike()
          })
        if (post.userId === this.currentUser.id) {
          Button(this.actionSubmitting ? '删除中...' : '删除')
            .height(38)
            .fontSize(13)
            .fontColor(PetPalTheme.danger)
            .backgroundColor('#FFF8F3')
            .borderRadius(PetPalTheme.radiusChip)
            .enabled(!this.actionSubmitting)
            .onClick(() => {
              void this.deletePost()
            })
        }
      }
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 24, bottom: 24 })
    .borderRadius(PetPalTheme.radiusHero)
    .linearGradient({
      angle: 145,
      colors: [[PetPalTheme.primaryStrong, 0.0], [PetPalTheme.primary, 0.52], [PetPalTheme.primaryGlow, 1.0]]
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ImageBand(post: Post) {
    Column({ space: 12 }) {
      Text('图片与片段')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Row({ space: 10 }) {
        ForEach(post.imageUrls, (imageUrl: string, index: number) => {
          Image(imageUrl)
            .width(index === 0 ? 138 : 108)
            .height(index === 0 ? 148 : 118)
            .objectFit(ImageFit.Cover)
            .borderRadius(PetPalTheme.radiusPanel)
        })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(PetPalTheme.surfaceRaised)
    .borderRadius(PetPalTheme.radiusPanel)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CommentSection() {
    Column({ space: 14 }) {
      Text('评论')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      TextInput({ text: this.commentText, placeholder: '写一条评论' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusPanel)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.commentText = value
        })
      Button(this.commentSubmitting ? '发布中...' : '发表评论')
        .height(40)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor(PetPalTheme.primary)
        .borderRadius(PetPalTheme.radiusChip)
        .enabled(!this.commentSubmitting)
        .onClick(() => {
          void this.submitComment()
        })
      if (this.comments.length > 0) {
        ForEach(this.comments, (item: CommentItem) => {
          Column({ space: 8 }) {
            Row() {
              Text(item.userName)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(PetPalTheme.text)
              Blank()
              Text(item.createdAt)
                .fontSize(12)
                .fontColor(PetPalTheme.textSubtle)
            }
            .width('100%')
            Text(item.content)
              .fontSize(13)
              .lineHeight(21)
              .fontColor(PetPalTheme.textMuted)
          }
          .width('100%')
          .padding(18)
          .backgroundColor(PetPalTheme.surface)
          .borderRadius(PetPalTheme.radiusPanel)
        })
      } else {
        Text('还没有评论。')
          .fontSize(13)
          .fontColor(PetPalTheme.textMuted)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

