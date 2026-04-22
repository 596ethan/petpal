import {
  Appointment,
  FileUploadInput,
  Pet,
  PetCreateInput,
  PetGender,
  PetSpecies,
  Post,
  PostCreateInput,
  ServiceProvider,
  UserProfile
} from '../models/PetPalModels';
import fs from '@ohos.file.fs';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { PetPalRepository } from '../repository/PetPalRepository';
import { PetPalTheme } from '../ui/PetPalTheme';
import { BookingTab } from './index-tabs/BookingTab';
import { CommunityTab } from './index-tabs/CommunityTab';
import { HomeTab } from './index-tabs/HomeTab';
import { IndexTabBar } from './index-tabs/IndexTabBar';
import { MineTab } from './index-tabs/MineTab';

const EMPTY_USER: UserProfile = {
  id: 0,
  nickname: '',
  bio: '',
  avatarUrl: '',
  followingCount: 0,
  followerCount: 0
};

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State user: UserProfile = EMPTY_USER
  @State pets: Pet[] = []
  @State posts: Post[] = []
  @State providers: ServiceProvider[] = []
  @State appointments: Appointment[] = []
  @State isAuthenticated: boolean = PetPalRepository.getSession() !== null
  @State refreshError: string = ''
  @State refreshing: boolean = false
  @State communityMessage: string = ''
  @State communityError: string = ''
  @State postComposerVisible: boolean = false
  @State postSubmitting: boolean = false
  @State postUploading: boolean = false
  @State postActionId: number = 0
  @State postContent: string = ''
  @State postPetIdText: string = ''
  @State postImageUrls: string[] = []
  @State petArchiveMessage: string = ''
  @State petArchiveError: string = ''
  @State petCreateVisible: boolean = false
  @State creatingPet: boolean = false
  @State createPetName: string = ''
  @State createPetSpecies: PetSpecies = PetSpecies.CAT
  @State createPetBreed: string = ''
  @State createPetGender: PetGender = PetGender.UNKNOWN
  @State createPetBirthday: string = ''
  @State createPetWeight: string = ''
  @State createPetAvatarUrl: string = ''
  @State createPetNeutered: boolean = false

  aboutToAppear() {
    void this.refreshData()
  }

  onPageShow() {
    void this.refreshData()
  }

  private async refreshData() {
    try {
      this.refreshing = true
      this.refreshError = ''
      const remotePosts = await PetPalRepository.getPostsAsync()
      this.posts = remotePosts
      this.providers = await PetPalRepository.getProvidersAsync()
      if (PetPalRepository.getSession() === null) {
        this.isAuthenticated = false
        this.user = EMPTY_USER
        this.pets = []
        this.appointments = []
        return
      }
      this.isAuthenticated = true
      const user = await PetPalRepository.getCurrentUserAsync()
      const remotePets = await PetPalRepository.getPetsAsync()
      const remoteAppointments = await PetPalRepository.getAppointmentsAsync()
      this.user = user
      this.pets = remotePets
      this.appointments = remoteAppointments
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.posts = PetPalRepository.getPosts()
      this.communityError = message
      this.refreshError = `内容刷新失败：${message}`
    } finally {
      this.refreshing = false
    }
  }

  private async cancelAppointment(id: number): Promise<void> {
    try {
      await PetPalRepository.cancelAppointment(id)
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.refreshError = `取消预约失败：${message}`
    }
  }

  private optionalPositiveNumber(value: string, label: string): number | undefined {
    const trimmed = value.trim()
    if (trimmed.length === 0) {
      return undefined
    }
    const parsed = Number(trimmed)
    if (parsed !== parsed || parsed <= 0) {
      throw new Error(`${label}请输入大于 0 的数字`)
    }
    return parsed
  }

  private resetCreatePetForm(): void {
    this.createPetName = ''
    this.createPetSpecies = PetSpecies.CAT
    this.createPetBreed = ''
    this.createPetGender = PetGender.UNKNOWN
    this.createPetBirthday = ''
    this.createPetWeight = ''
    this.createPetAvatarUrl = ''
    this.createPetNeutered = false
  }

  private async submitCreatePet(): Promise<void> {
    if (this.creatingPet) {
      return
    }
    const name = this.createPetName.trim()
    if (name.length === 0) {
      this.petArchiveError = '请输入宠物名称'
      return
    }
    try {
      this.creatingPet = true
      this.petArchiveError = ''
      this.petArchiveMessage = ''
      const input: PetCreateInput = {
        name: name,
        species: this.createPetSpecies,
        gender: this.createPetGender,
        neutered: this.createPetNeutered
      }
      const breed = this.createPetBreed.trim()
      const birthday = this.createPetBirthday.trim()
      const avatarUrl = this.createPetAvatarUrl.trim()
      const weight = this.optionalPositiveNumber(this.createPetWeight, '体重')
      if (breed.length > 0) {
        input.breed = breed
      }
      if (birthday.length > 0) {
        input.birthday = birthday
      }
      if (weight !== undefined) {
        input.weight = weight
      }
      if (avatarUrl.length > 0) {
        input.avatarUrl = avatarUrl
      }
      await PetPalRepository.createPet(input)
      this.resetCreatePetForm()
      this.petCreateVisible = false
      this.petArchiveMessage = '宠物档案已创建'
      await this.refreshData()
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.petArchiveError = `创建宠物档案失败：${message}`
    } finally {
      this.creatingPet = false
    }
  }

  private resetPostComposer(): void {
    this.postContent = ''
    this.postPetIdText = ''
    this.postImageUrls = []
  }

  private async pickPostImages(): Promise<void> {
    if (!this.isAuthenticated) {
      this.communityError = '请先登录后再上传图片。'
      return
    }
    if (this.postUploading || this.postImageUrls.length >= 9) {
      return
    }
    try {
      this.postUploading = true
      this.communityError = ''
      const options = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 9 - this.postImageUrls.length
      const picker = new photoAccessHelper.PhotoViewPicker()
      const result = await picker.select(options)
      for (const uri of result.photoUris) {
        if (this.postImageUrls.length >= 9) {
          break
        }
        const uploadInput = this.uploadInputFromUri(uri)
        const uploaded = await PetPalRepository.uploadPostImage(uploadInput)
        this.postImageUrls = this.postImageUrls.concat([uploaded.url])
      }
      if (this.postImageUrls.length > 0) {
        this.communityMessage = '图片已上传'
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.communityError = `图片上传失败：${message}`
    } finally {
      this.postUploading = false
    }
  }

  private uploadInputFromUri(uri: string): FileUploadInput {
    let file: fs.File | null = null
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      const stat = fs.statSync(file.fd)
      const data = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, data)
      return {
        fileName: this.fileNameFromUri(uri),
        contentType: this.contentTypeFromUri(uri),
        data: data
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      throw new Error(`读取图片失败：${message}`)
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file)
        } catch {
        }
      }
    }
  }

  private fileNameFromUri(uri: string): string {
    const index = uri.lastIndexOf('/')
    const name = index >= 0 ? uri.substring(index + 1) : uri
    return name.length > 0 ? name : 'community-image.jpg'
  }

  private contentTypeFromUri(uri: string): string {
    const lower = uri.toLowerCase()
    if (lower.endsWith('.png')) {
      return 'image/png'
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif'
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp'
    }
    return 'image/jpeg'
  }

  private async submitPost(): Promise<void> {
    if (this.postSubmitting) {
      return
    }
    if (!this.isAuthenticated) {
      this.communityError = '请先登录后再发布。'
      return
    }
    const content = this.postContent.trim()
    if (content.length === 0) {
      this.communityError = '请输入帖子内容。'
      return
    }
    try {
      this.postSubmitting = true
      this.communityError = ''
      this.communityMessage = ''
      const input: PostCreateInput = {
        content: content,
        imageUrls: this.postImageUrls
      }
      const petIdText = this.postPetIdText.trim()
      if (petIdText.length > 0) {
        const petId = Number(petIdText)
        if (petId !== petId || petId <= 0) {
          throw new Error('宠物 ID 必须是正整数')
        }
        input.petId = petId
      }
      const created = await PetPalRepository.createPost(input)
      this.posts = [created].concat(this.posts.filter((item: Post) => item.id !== created.id))
      this.resetPostComposer()
      this.postComposerVisible = false
      this.communityMessage = '帖子已发布'
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.communityError = `发布失败：${message}`
    } finally {
      this.postSubmitting = false
    }
  }

  private async toggleLike(item: Post): Promise<void> {
    if (!this.isAuthenticated) {
      this.communityError = '请先登录后再点赞。'
      return
    }
    if (this.postActionId !== 0) {
      return
    }
    try {
      this.postActionId = item.id
      this.communityError = ''
      const updated = item.liked ? await PetPalRepository.unlikePost(item.id) : await PetPalRepository.likePost(item.id)
      this.posts = this.posts.map((post: Post) => post.id === updated.id ? updated : post)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.communityError = `点赞状态更新失败：${message}`
    } finally {
      this.postActionId = 0
    }
  }

  private async deletePost(item: Post): Promise<void> {
    if (!this.isAuthenticated || item.userId !== this.user.id) {
      this.communityError = '只有作者可以删除这条帖子。'
      return
    }
    if (this.postActionId !== 0) {
      return
    }
    try {
      this.postActionId = item.id
      this.communityError = ''
      await PetPalRepository.deletePost(item.id)
      this.posts = this.posts.filter((post: Post) => post.id !== item.id)
      this.communityMessage = '帖子已删除'
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      this.communityError = `删除失败：${message}`
    } finally {
      this.postActionId = 0
    }
  }

  private goToLogin(): void {
    void this.getUIContext().getRouter().pushUrl({ url: 'pages/Login' })
  }

  private openProviderDetail(providerId: number): void {
    void this.getUIContext().getRouter().pushUrl({ url: 'pages/ProviderDetail', params: { providerId: `${providerId}` } })
  }

  private openPostDetail(postId: number): void {
    void this.getUIContext().getRouter().pushUrl({ url: 'pages/PostDetail', params: { postId: `${postId}` } })
  }

  private openPetDetail(petId: number): void {
    void this.getUIContext().getRouter().pushUrl({ url: 'pages/PetDetail', params: { petId: `${petId}` } })
  }

  private togglePostComposer(): void {
    this.postComposerVisible = !this.postComposerVisible
    this.communityError = ''
  }

  private togglePetCreateVisible(): void {
    this.petCreateVisible = !this.petCreateVisible
    this.petArchiveError = ''
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.currentTab === 0) {
          HomeTab({
            refreshError: this.refreshError,
            posts: this.posts,
            providers: this.providers,
            pets: this.pets,
            appointments: this.appointments,
            onOpenCommunity: () => {
              this.currentTab = 1
            },
            onGoLogin: () => {
              this.goToLogin()
            },
            onOpenPostDetail: (postId: number) => {
              this.openPostDetail(postId)
            },
            onOpenProvider: (providerId: number) => {
              this.openProviderDetail(providerId)
            }
          })
        }
        if (this.currentTab === 1) {
          CommunityTab({
            isAuthenticated: this.isAuthenticated,
            refreshing: this.refreshing,
            posts: this.posts,
            communityMessage: this.communityMessage,
            communityError: this.communityError,
            postComposerVisible: this.postComposerVisible,
            postSubmitting: this.postSubmitting,
            postUploading: this.postUploading,
            postActionId: this.postActionId,
            postContent: this.postContent,
            postPetIdText: this.postPetIdText,
            postImageUrls: this.postImageUrls,
            userId: this.user.id,
            onGoLogin: () => {
              this.goToLogin()
            },
            onToggleComposer: () => {
              this.togglePostComposer()
            },
            onPostContentChange: (value: string) => {
              this.postContent = value
            },
            onPostPetIdTextChange: (value: string) => {
              this.postPetIdText = value
            },
            onUploadImages: () => {
              void this.pickPostImages()
            },
            onSubmitPost: () => {
              void this.submitPost()
            },
            onToggleLike: (item: Post) => {
              void this.toggleLike(item)
            },
            onDeletePost: (item: Post) => {
              void this.deletePost(item)
            },
            onOpenPostDetail: (postId: number) => {
              this.openPostDetail(postId)
            }
          })
        }
        if (this.currentTab === 2) {
          BookingTab({
            isAuthenticated: this.isAuthenticated,
            appointments: this.appointments,
            providers: this.providers,
            onGoLogin: () => {
              this.goToLogin()
            },
            onCancelAppointment: (appointmentId: number) => {
              void this.cancelAppointment(appointmentId)
            },
            onOpenProvider: (providerId: number) => {
              this.openProviderDetail(providerId)
            }
          })
        }
        if (this.currentTab === 3) {
          MineTab({
            isAuthenticated: this.isAuthenticated,
            user: this.user,
            pets: this.pets,
            posts: this.posts,
            appointments: this.appointments,
            petArchiveMessage: this.petArchiveMessage,
            petArchiveError: this.petArchiveError,
            petCreateVisible: this.petCreateVisible,
            creatingPet: this.creatingPet,
            createPetName: this.createPetName,
            createPetSpecies: this.createPetSpecies,
            createPetBreed: this.createPetBreed,
            createPetGender: this.createPetGender,
            createPetBirthday: this.createPetBirthday,
            createPetWeight: this.createPetWeight,
            createPetAvatarUrl: this.createPetAvatarUrl,
            createPetNeutered: this.createPetNeutered,
            onGoLogin: () => {
              this.goToLogin()
            },
            onTogglePetCreate: () => {
              this.togglePetCreateVisible()
            },
            onCreatePetNameChange: (value: string) => {
              this.createPetName = value
            },
            onCreatePetBreedChange: (value: string) => {
              this.createPetBreed = value
            },
            onCreatePetSpeciesChange: (value: PetSpecies) => {
              this.createPetSpecies = value
            },
            onCreatePetGenderChange: (value: PetGender) => {
              this.createPetGender = value
            },
            onCreatePetBirthdayChange: (value: string) => {
              this.createPetBirthday = value
            },
            onCreatePetWeightChange: (value: string) => {
              this.createPetWeight = value
            },
            onCreatePetAvatarUrlChange: (value: string) => {
              this.createPetAvatarUrl = value
            },
            onToggleCreatePetNeutered: () => {
              this.createPetNeutered = !this.createPetNeutered
            },
            onSubmitCreatePet: () => {
              void this.submitCreatePet()
            },
            onOpenPetDetail: (petId: number) => {
              this.openPetDetail(petId)
            }
          })
        }
      }
      .width('100%')
      .height('100%')

      IndexTabBar({
        currentTab: this.currentTab,
        onTabChange: (index: number) => {
          this.currentTab = index
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PetPalTheme.background)
  }
}
