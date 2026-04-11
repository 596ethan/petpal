import { HealthRecord, Pet, VaccineRecord } from '../models/PetPalModels';
import { PetPalRepository } from '../repository/PetPalRepository';
import { genderText, PetPalTheme, speciesText } from '../ui/PetPalTheme';

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

@Entry
@Component
struct PetDetail {
  private petId: number = Number((this.getUIContext().getRouter().getParams() as Record<string, string>).petId ?? '1')
  @State pet: Pet = PetPalRepository.getPetById(this.petId)
  @State health: HealthRecord[] = PetPalRepository.getHealthRecords(this.petId)
  @State vaccines: VaccineRecord[] = PetPalRepository.getVaccines(this.petId)
  @State refreshError: string = ''

  aboutToAppear() {
    void this.refreshData()
  }

  private async refreshData() {
    try {
      this.refreshError = ''
      const pet = await PetPalRepository.getPetByIdAsync(this.petId)
      const health = await PetPalRepository.getHealthRecordsAsync(this.petId)
      const vaccines = await PetPalRepository.getVaccinesAsync(this.petId)
      this.pet = pet
      this.health = health
      this.vaccines = vaccines
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.refreshError = `健康档案刷新失败：${message}`
    }
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
        this.PetHero()

        DetailHeader('健康时间线', '把重要节点整理成一条温柔而清楚的记录', '就诊、体检和驱虫不再散落在不同入口里，而是按时间顺序被慢慢收好。')
        ForEach(this.health, (item: HealthRecord) => {
          this.HealthCard(item)
        })

        DetailHeader('疫苗记录', '下一次到期时间一眼能看到', '保留医疗信息的准确性，同时把阅读体验做得更平和。')
        ForEach(this.vaccines, (item: VaccineRecord) => {
          this.VaccineCard(item)
        })
      }
      .padding({ left: PetPalTheme.pagePadding, right: PetPalTheme.pagePadding, top: 18, bottom: 24 })
    }
    .backgroundColor(PetPalTheme.background)
  }

  @Builder
  PetHero() {
    Column({ space: 16 }) {
      Row({ space: 14 }) {
        Image(this.pet.avatarUrl)
          .width(62)
          .height(62)
          .objectFit(ImageFit.Cover)
          .borderRadius(31)
        Column({ space: 6 }) {
          Text(this.pet.name)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF8F3')
          Text(`${speciesText(this.pet.species)} · ${this.pet.breed} · ${genderText(this.pet.gender)}`)
            .fontSize(13)
            .fontColor('#F5E8DB')
          Text(`体重 ${this.pet.weight} · 生日 ${this.pet.birthday}`)
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
        DetailChip('下次 ' + item.nextDate, PetPalTheme.surfaceWarm, PetPalTheme.primary)
      }
      .width('100%')
      Text(item.summary)
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
          Text(item.hospital)
            .fontSize(12)
            .fontColor(PetPalTheme.textMuted)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        DetailChip('下次 ' + item.nextDueAt, PetPalTheme.primarySoft, PetPalTheme.primary)
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


