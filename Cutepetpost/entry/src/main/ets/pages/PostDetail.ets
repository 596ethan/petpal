import { CommentItem, Post } from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
import { UserProfile } from '../models/PetPalModels';
import { PetPalTheme } from '../ui/PetPalTheme';

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

@Entry
@Component
struct PostDetail {
  private readonly postId: number = Number((this.getUIContext().getRouter().getParams() as Record<string, string>).postId ?? '1')
  @State post: Post = PetPalRepository.getPostById(this.postId)
  @State comments: CommentItem[] = PetPalRepository.getComments(this.post.id)
  @State currentUser: UserProfile = PetPalRepository.getSession()?.profile ?? EMPTY_USER
  @State loading: boolean = false
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
    } finally {
      this.loading = false
    }
  }

  private async toggleLike(): Promise<void> {
    if (this.actionSubmitting) {
      return
    }
    try {
      this.actionSubmitting = true
      this.errorMessage = ''
      this.post = this.post.liked ? await PetPalRepository.unlikePost(this.post.id) : await PetPalRepository.likePost(this.post.id)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `Like update failed: ${message}`
    } finally {
      this.actionSubmitting = false
    }
  }

  private async deletePost(): Promise<void> {
    if (this.actionSubmitting || this.post.userId !== this.currentUser.id) {
      return
    }
    try {
      this.actionSubmitting = true
      this.errorMessage = ''
      await PetPalRepository.deletePost(this.post.id)
      this.successMessage = 'Post deleted.'
      this.getUIContext().getRouter().back()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `Delete failed: ${message}`
    } finally {
      this.actionSubmitting = false
    }
  }

  private async submitComment(): Promise<void> {
    if (this.commentSubmitting) {
      return
    }
    const content = this.commentText.trim()
    if (content.length === 0) {
      this.errorMessage = 'Please enter a comment.'
      return
    }
    try {
      this.commentSubmitting = true
      this.errorMessage = ''
      await PetPalRepository.addComment(this.post.id, { content: content })
      this.commentText = ''
      this.comments = await PetPalRepository.getCommentsAsync(this.post.id)
      this.post = await PetPalRepository.getPostByIdAsync(this.post.id)
      this.successMessage = 'Comment published.'
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.errorMessage = `Comment failed: ${message}`
    } finally {
      this.commentSubmitting = false
    }
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        if (this.loading) {
          Text('Loading post...')
            .fontSize(16)
            .fontColor(PetPalTheme.textMuted)
            .width('100%')
        } else if (this.notFound) {
          Text('Post not found')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(PetPalTheme.text)
            .width('100%')
          Text('This post may have been deleted.')
            .fontSize(13)
            .fontColor(PetPalTheme.textMuted)
            .width('100%')
        } else {
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
          this.StoryHero()
          this.ImageBand()
          this.CommentSection()
        }
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 24 })
    }
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  StoryHero() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Image(this.post.authorAvatarUrl)
          .width(52)
          .height(52)
          .objectFit(ImageFit.Cover)
          .borderRadius(26)
        Column({ space: 5 }) {
          Text(this.post.authorName)
            .fontSize(27)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text(`${this.post.petName} · ${this.post.createdAt}`)
            .fontSize(13)
            .fontColor('#F3E4D6')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      Text(this.post.content)
        .fontSize(15)
        .lineHeight(24)
        .fontColor('#FFF8F3')
      Row({ space: 8 }) {
        ForEach(this.post.topics, (topic: string) => {
          PostChip(`#${topic}`, 'rgba(255, 248, 243, 0.09)', '#FFF8F3')
        })
      }
      Row({ space: 8 }) {
        PostChip(`喜欢 ${this.post.likeCount}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
        PostChip(`评论 ${this.post.commentCount}`, 'rgba(255, 248, 243, 0.07)', '#FFF8F3')
      }
      Row({ space: 8 }) {
        Button(this.post.liked ? 'Unlike' : 'Like')
          .height(38)
          .fontSize(13)
          .fontColor(this.post.liked ? PetPalTheme.primary : '#FFFFFF')
          .backgroundColor(this.post.liked ? '#FFF8F3' : PetPalTheme.primaryStrong)
          .borderRadius(PetPalTheme.radiusChip)
          .enabled(!this.actionSubmitting)
          .onClick(() => {
            void this.toggleLike()
          })
        if (this.post.userId === this.currentUser.id) {
          Button(this.actionSubmitting ? 'Deleting...' : 'Delete')
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
  ImageBand() {
    Column({ space: 12 }) {
      Text('图片与片段')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PetPalTheme.text)
      Row({ space: 10 }) {
        ForEach(this.post.imageUrls, (imageUrl: string, index: number) => {
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
      TextInput({ text: this.commentText, placeholder: 'Write a root comment' })
        .height(50)
        .backgroundColor(PetPalTheme.surface)
        .borderRadius(PetPalTheme.radiusPanel)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.commentText = value
        })
      Button(this.commentSubmitting ? 'Publishing...' : 'Publish comment')
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
        Text('No comments yet.')
          .fontSize(13)
          .fontColor(PetPalTheme.textMuted)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

