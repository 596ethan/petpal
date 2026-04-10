import {
  Appointment,
  AppointmentStatus,
  CommentItem,
  HealthRecord,
  Pet,
  PetGender,
  PetSpecies,
  Post,
  ProviderType,
  ServiceItem,
  ServiceProvider,
  UserProfile,
  VaccineRecord
} from '../models/PetPalModels';

export const currentUser: UserProfile = {
  id: 1,
  nickname: '小满',
  bio: '三只猫一只狗的日常记录者。',
  avatarUrl: 'https://loremflickr.com/240/240/person,pet?lock=31',
  followingCount: 18,
  followerCount: 42
};

export const pets: Pet[] = [
  {
    id: 1,
    name: '糯米',
    species: PetSpecies.CAT,
    breed: '英短',
    gender: PetGender.FEMALE,
    birthday: '2022-05-01',
    weight: '4.3kg',
    avatarUrl: 'https://loremflickr.com/640/640/cat?lock=11',
    neutered: true
  },
  {
    id: 2,
    name: '七七',
    species: PetSpecies.DOG,
    breed: '柯基',
    gender: PetGender.MALE,
    birthday: '2021-11-18',
    weight: '10.8kg',
    avatarUrl: 'https://loremflickr.com/640/640/dog?lock=12',
    neutered: false
  }
];

export const healthRecords: HealthRecord[] = [
  { id: 1, title: '年度体检', summary: '血常规正常，医生建议继续控制体重。', recordDate: '2026-02-18', nextDate: '2027-02-18' },
  { id: 2, title: '常规驱虫', summary: '体内驱虫已完成，状态稳定。', recordDate: '2026-03-01', nextDate: '2026-06-01' }
];

export const vaccineRecords: VaccineRecord[] = [
  { id: 1, vaccineName: '猫三联', vaccinatedAt: '2025-04-18', nextDueAt: '2026-04-11', hospital: '云朵宠物医院' },
  { id: 2, vaccineName: '狂犬', vaccinatedAt: '2025-07-01', nextDueAt: '2026-06-24', hospital: '云朵宠物医院' }
];

export const posts: Post[] = [
  {
    id: 1,
    authorName: '小满',
    authorAvatarUrl: 'https://loremflickr.com/128/128/person?lock=41',
    petName: '糯米',
    content: '糯米今天打完疫苗，回家后就趴在窗边晒太阳，状态比想象中轻松很多。',
    imageUrls: ['https://loremflickr.com/1200/900/cat,home?lock=51', 'https://loremflickr.com/1200/900/cat,window?lock=52'],
    topics: ['猫咪日常', '疫苗记录'],
    likeCount: 23,
    commentCount: 5,
    createdAt: '3月24日 18:20'
  },
  {
    id: 2,
    authorName: '阿柚',
    authorAvatarUrl: 'https://loremflickr.com/128/128/person?lock=42',
    petName: '七七',
    content: '七七第一次做全套美容，耳朵边修得特别精神，出来时一路都在摇尾巴。',
    imageUrls: ['https://loremflickr.com/1200/900/dog,grooming?lock=53'],
    topics: ['柯基', '美容'],
    likeCount: 56,
    commentCount: 12,
    createdAt: '3月23日 13:10'
  }
];

export const comments: CommentItem[] = [
  { id: 1, userName: '阿柚', content: '恢复得真快，看起来状态很好。', createdAt: '19:10' },
  { id: 2, userName: '小满', content: '嗯，医生也说很稳定，今晚继续观察。', createdAt: '19:18' }
];

export const providers: ServiceProvider[] = [
  {
    id: 1,
    name: '云朵宠物医院',
    type: ProviderType.HOSPITAL,
    address: '浦东新区丁香路 99 号',
    phone: '021-12345678',
    rating: '4.8',
    businessHours: '09:00-20:00',
    coverUrl: 'https://loremflickr.com/1200/700/vet,pet?lock=61'
  },
  {
    id: 2,
    name: '泡泡宠物美容',
    type: ProviderType.GROOMING,
    address: '静安区延平路 28 号',
    phone: '021-87654321',
    rating: '4.7',
    businessHours: '10:00-21:00',
    coverUrl: 'https://loremflickr.com/1200/700/dog,grooming,salon?lock=62'
  },
  {
    id: 3,
    name: '安心寄养之家',
    type: ProviderType.BOARDING,
    address: '徐汇区漕溪北路 111 号',
    phone: '021-99887766',
    rating: '4.6',
    businessHours: '08:00-22:00',
    coverUrl: 'https://loremflickr.com/1200/700/pet,boarding?lock=63'
  }
];

export const serviceItems: ServiceItem[] = [
  { id: 1, providerId: 1, name: '基础问诊', price: '￥59', duration: '30分钟' },
  { id: 2, providerId: 1, name: '疫苗接种', price: '￥88', duration: '20分钟' },
  { id: 3, providerId: 2, name: '基础洗护', price: '￥79', duration: '60分钟' },
  { id: 4, providerId: 2, name: '全套美容', price: '￥199', duration: '120分钟' },
  { id: 5, providerId: 3, name: '单日寄养', price: '￥128', duration: '1天' }
];

export const appointments: Appointment[] = [
  {
    id: 1,
    orderNo: 'PP202603260001',
    petName: '糯米',
    providerName: '云朵宠物医院',
    serviceName: '疫苗接种',
    appointmentTime: '2026-03-29 10:30',
    status: AppointmentStatus.CONFIRMED,
    remark: '提前十分钟到店'
  },
  {
    id: 2,
    orderNo: 'PP202603260002',
    petName: '七七',
    providerName: '泡泡宠物美容',
    serviceName: '全套美容',
    appointmentTime: '2026-03-30 14:00',
    status: AppointmentStatus.PENDING_CONFIRM,
    remark: '怕吹风，尽量温和一点'
  }
];


