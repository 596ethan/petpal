export enum PetSpecies {
  DOG = 'DOG',
  CAT = 'CAT',
  RABBIT = 'RABBIT',
  BIRD = 'BIRD',
  OTHER = 'OTHER'
}

export enum PetGender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  UNKNOWN = 'UNKNOWN'
}

export enum ProviderType {
  HOSPITAL = 'HOSPITAL',
  GROOMING = 'GROOMING',
  BOARDING = 'BOARDING'
}

export enum AppointmentStatus {
  PENDING_CONFIRM = 'PENDING_CONFIRM',
  CONFIRMED = 'CONFIRMED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED'
}

export interface UserProfile {
  id: number
  nickname: string
  bio: string
  avatarUrl: string
  followingCount: number
  followerCount: number
}

export interface Pet {
  id: number
  name: string
  species: PetSpecies
  breed: string
  gender: PetGender
  birthday: string
  weight: string
  avatarUrl: string
  neutered: boolean
}

export interface HealthRecord {
  id: number
  title: string
  summary: string
  recordDate: string
  nextDate: string
}

export interface VaccineRecord {
  id: number
  vaccineName: string
  vaccinatedAt: string
  nextDueAt: string
  hospital: string
}

export interface Post {
  id: number
  authorName: string
  authorAvatarUrl: string
  petName: string
  content: string
  imageUrls: string[]
  topics: string[]
  likeCount: number
  commentCount: number
  createdAt: string
}

export interface CommentItem {
  id: number
  userName: string
  content: string
  createdAt: string
}

export interface ServiceProvider {
  id: number
  name: string
  type: ProviderType
  address: string
  phone: string
  rating: string
  businessHours: string
  coverUrl: string
}

export interface ServiceItem {
  id: number
  providerId: number
  name: string
  price: string
  duration: string
}

export interface Appointment {
  id: number
  orderNo: string
  petName: string
  providerName: string
  serviceName: string
  appointmentTime: string
  status: AppointmentStatus
  remark: string
}
