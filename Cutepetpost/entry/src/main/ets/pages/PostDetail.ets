import router from '@ohos.router';
import { CommentItem, Post } from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
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

@Entry
@Component
struct PostDetail {
  private post: Post = PetPalRepository.getPostById(Number((router.getParams() as Record<string, string>).postId ?? '1'))
  private comments: CommentItem[] = PetPalRepository.getComments(this.post.id)

  build() {
    Scroll() {
      Column({ space: 22 }) {
        this.StoryHero()
        this.ImageBand()
        this.CommentSection()
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

