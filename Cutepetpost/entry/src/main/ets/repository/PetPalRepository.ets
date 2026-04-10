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
import {
  appointments,
  comments,
  currentUser,
  healthRecords,
  pets,
  posts,
  providers,
  serviceItems,
  vaccineRecords
} from '../data/MockPetPalData';
import http from '@ohos.net.http';

export interface LoginSession {
  accessToken: string;
  refreshToken: string;
  profile: UserProfile;
}

interface BackendEnvelope<T> {
  code: string;
  message: string;
  data: T;
  requestId?: string;
}

interface BackendUserProfilePayload {
  id: number;
  phone: string;
  nickname: string;
  avatarUrl: string;
  bio: string;
  followingCount: number;
  followerCount: number;
}

interface BackendTokenPayload {
  accessToken: string;
  refreshToken: string;
}

interface BackendLoginPayload {
  profile: BackendUserProfilePayload;
  tokens: BackendTokenPayload;
}

interface BackendPet {
  id: number;
  name: string;
  species: string;
  breed: string;
  gender: string;
  birthday: string;
  weight: number;
  avatarUrl: string;
  neutered: boolean;
}

interface BackendHealthRecord {
  id: number;
  title: string;
  description: string;
  recordDate: string;
  nextDate: string;
}

interface BackendProvider {
  id: number;
  name: string;
  type: string;
  address: string;
  phone: string;
  rating: number;
  coverUrl: string;
  businessHours: string;
  status: string;
}

interface BackendServiceItem {
  id: number;
  providerId: number;
  name: string;
  price: number;
  durationMinutes: number;
}

interface BackendAppointment {
  id: number;
  orderNo: string;
  userId: number;
  petId: number;
  petName: string;
  providerId: number;
  providerName: string;
  serviceId: number;
  serviceName: string;
  status: string;
  appointmentTime: string;
  remark: string;
}

interface LoginRequestPayload {
  phone: string;
  password: string;
}

export interface AppointmentCreateInput {
  petId: number;
  providerId: number;
  serviceId: number;
  appointmentTime: string;
  remark: string;
}

export class PetPalRepository {
  private static apiBaseUrl: string = 'http://127.0.0.1:8080/api';
  private static session: LoginSession | null = null;

  static getCurrentUser(): UserProfile {
    if (PetPalRepository.session !== null) {
      return PetPalRepository.session.profile;
    }
    return currentUser;
  }

  static getSession(): LoginSession | null {
    return PetPalRepository.session;
  }

  static setApiBaseUrl(baseUrl: string): void {
    const normalized = baseUrl.trim();
    if (normalized.length > 0) {
      if (normalized.endsWith('/')) {
        PetPalRepository.apiBaseUrl = normalized.slice(0, normalized.length - 1);
      } else {
        PetPalRepository.apiBaseUrl = normalized;
      }
    }
  }

  static storeSession(session: LoginSession): void {
    PetPalRepository.session = session;
  }

  static clearSession(): void {
    PetPalRepository.session = null;
  }

  static getPets(): Pet[] {
    return pets;
  }

  static getPetById(id: number): Pet {
    const pet = pets.find((item: Pet) => item.id === id);
    return pet ?? pets[0];
  }

  static getHealthRecords(petId: number): HealthRecord[] {
    void petId;
    return healthRecords;
  }

  static getVaccines(petId: number): VaccineRecord[] {
    void petId;
    return vaccineRecords;
  }

  static getPosts(): Post[] {
    return posts;
  }

  static getPostById(id: number): Post {
    const post = posts.find((item: Post) => item.id === id);
    return post ?? posts[0];
  }

  static getComments(postId: number): CommentItem[] {
    void postId;
    return comments;
  }

  static getProviders(): ServiceProvider[] {
    return providers;
  }

  static getProviderById(id: number): ServiceProvider {
    const provider = providers.find((item: ServiceProvider) => item.id === id);
    return provider ?? providers[0];
  }

  static getServices(providerId: number): ServiceItem[] {
    return serviceItems.filter((item: ServiceItem) => item.providerId === providerId);
  }

  static getAppointments(): Appointment[] {
    return appointments;
  }

  static async login(phone: string, password: string): Promise<LoginSession> {
    const body: LoginRequestPayload = {
      phone: phone,
      password: password
    };
    const payload = await PetPalRepository.request<BackendLoginPayload>('/user/login', http.RequestMethod.POST, body, false);
    const session: LoginSession = {
      accessToken: payload.tokens.accessToken,
      refreshToken: payload.tokens.refreshToken,
      profile: PetPalRepository.mapProfile(payload.profile)
    };
    return session;
  }

  static async loginAsync(phone: string, password: string): Promise<LoginSession> {
    return PetPalRepository.login(phone, password);
  }

  static async getCurrentUserRemote(): Promise<UserProfile> {
    const payload = await PetPalRepository.request<BackendUserProfilePayload>('/user/profile', http.RequestMethod.GET);
    const profile = PetPalRepository.mapProfile(payload);
    if (PetPalRepository.session !== null) {
      const session: LoginSession = {
        accessToken: PetPalRepository.session.accessToken,
        refreshToken: PetPalRepository.session.refreshToken,
        profile: profile
      };
      PetPalRepository.session = session;
    }
    return profile;
  }

  static async getPetsRemote(): Promise<Pet[]> {
    const payload = await PetPalRepository.request<BackendPet[]>('/pet/list', http.RequestMethod.GET);
    return payload.map((item: BackendPet) => PetPalRepository.mapPet(item));
  }

  static async getPetByIdAsync(id: number): Promise<Pet> {
    const payload = await PetPalRepository.request<BackendPet>(`/pet/${id}`, http.RequestMethod.GET);
    return PetPalRepository.mapPet(payload);
  }

  static async getHealthRecordsAsync(petId: number): Promise<HealthRecord[]> {
    const payload = await PetPalRepository.request<BackendHealthRecord[]>(`/pet/${petId}/health`, http.RequestMethod.GET);
    return payload.map((item: BackendHealthRecord) => {
      const record: HealthRecord = {
        id: item.id,
        title: item.title,
        summary: item.description,
        recordDate: item.recordDate,
        nextDate: item.nextDate
      };
      return record;
    });
  }

  static async getVaccinesAsync(petId: number): Promise<VaccineRecord[]> {
    return PetPalRepository.request<VaccineRecord[]>(`/pet/${petId}/vaccine`, http.RequestMethod.GET);
  }

  static async getProvidersRemote(): Promise<ServiceProvider[]> {
    const payload = await PetPalRepository.request<BackendProvider[]>('/provider/list', http.RequestMethod.GET, undefined, false);
    return payload.map((item: BackendProvider) => PetPalRepository.mapProvider(item));
  }

  static async getProviderByIdAsync(id: number): Promise<ServiceProvider> {
    const payload = await PetPalRepository.request<BackendProvider>(`/provider/${id}`, http.RequestMethod.GET, undefined, false);
    return PetPalRepository.mapProvider(payload);
  }

  static async getServicesRemote(providerId: number): Promise<ServiceItem[]> {
    const payload = await PetPalRepository.request<BackendServiceItem[]>(`/provider/${providerId}/services`, http.RequestMethod.GET, undefined, false);
    return payload.map((item: BackendServiceItem) => PetPalRepository.mapService(item));
  }

  static async getAppointmentsRemote(): Promise<Appointment[]> {
    const payload = await PetPalRepository.request<BackendAppointment[]>('/appointment/list', http.RequestMethod.GET);
    return payload.map((item: BackendAppointment) => PetPalRepository.mapAppointment(item));
  }

  static async createAppointment(input: AppointmentCreateInput): Promise<Appointment> {
    const payload = await PetPalRepository.request<BackendAppointment>('/appointment', http.RequestMethod.POST, input);
    return PetPalRepository.mapAppointment(payload);
  }

  static async cancelAppointment(id: number): Promise<void> {
    await PetPalRepository.request<void>(`/appointment/${id}/cancel`, http.RequestMethod.PUT);
  }

  static canCancelAppointment(status: AppointmentStatus): boolean {
    return status === AppointmentStatus.PENDING_CONFIRM || status === AppointmentStatus.CONFIRMED;
  }

  static async getCurrentUserAsync(): Promise<UserProfile> {
    return PetPalRepository.getCurrentUserRemote();
  }

  static async getPetsAsync(): Promise<Pet[]> {
    return PetPalRepository.getPetsRemote();
  }

  static async getProvidersAsync(): Promise<ServiceProvider[]> {
    return PetPalRepository.getProvidersRemote();
  }

  static async getServicesAsync(providerId: number): Promise<ServiceItem[]> {
    return PetPalRepository.getServicesRemote(providerId);
  }

  static async getAppointmentsAsync(): Promise<Appointment[]> {
    return PetPalRepository.getAppointmentsRemote();
  }

  private static async request<T>(
    path: string,
    method: http.RequestMethod,
    body?: Object,
    authRequired: boolean = true
  ): Promise<T> {
    const request = http.createHttp();
    try {
      let headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      if (authRequired && PetPalRepository.session !== null) {
        headers.Authorization = `Bearer ${PetPalRepository.session.accessToken}`;
      }
      let options: http.HttpRequestOptions = {
        method: method,
        header: headers,
        connectTimeout: 30000,
        readTimeout: 30000,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false
      };
      if (body !== undefined) {
        options.extraData = JSON.stringify(body) as string | Object;
      }
      const response = await request.request(`${PetPalRepository.apiBaseUrl}${path}`, options);
      const raw = String(response.result);
      let envelope: BackendEnvelope<T> = JSON.parse(raw) as BackendEnvelope<T>;
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(envelope.message);
      }
      if (envelope.code !== 'OK') {
        throw new Error(envelope.message);
      }
      return envelope.data;
    } finally {
      request.destroy();
    }
  }

  private static mapProfile(profile: BackendUserProfilePayload): UserProfile {
    const result: UserProfile = {
      id: profile.id,
      nickname: profile.nickname,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      followingCount: profile.followingCount,
      followerCount: profile.followerCount
    };
    return result;
  }

  private static mapPet(item: BackendPet): Pet {
    const result: Pet = {
      id: item.id,
      name: item.name,
      species: PetPalRepository.mapSpecies(item.species),
      breed: item.breed,
      gender: PetPalRepository.mapGender(item.gender),
      birthday: item.birthday,
      weight: `${item.weight}`,
      avatarUrl: item.avatarUrl,
      neutered: item.neutered
    };
    return result;
  }

  private static mapProvider(item: BackendProvider): ServiceProvider {
    const result: ServiceProvider = {
      id: item.id,
      name: item.name,
      type: PetPalRepository.mapProviderType(item.type),
      address: item.address,
      phone: item.phone,
      rating: item.rating.toFixed(1),
      coverUrl: item.coverUrl,
      businessHours: item.businessHours
    };
    return result;
  }

  private static mapService(item: BackendServiceItem): ServiceItem {
    const result: ServiceItem = {
      id: item.id,
      providerId: item.providerId,
      name: item.name,
      price: `￥${item.price.toFixed(0)}`,
      duration: `${item.durationMinutes}分钟`
    };
    return result;
  }

  private static mapAppointment(item: BackendAppointment): Appointment {
    const result: Appointment = {
      id: item.id,
      orderNo: item.orderNo,
      petName: item.petName,
      providerName: item.providerName,
      serviceName: item.serviceName,
      appointmentTime: item.appointmentTime,
      status: PetPalRepository.mapAppointmentStatus(item.status),
      remark: item.remark
    };
    return result;
  }

  private static mapSpecies(value: string): PetSpecies {
    if (value === PetSpecies.DOG) {
      return PetSpecies.DOG;
    }
    if (value === PetSpecies.CAT) {
      return PetSpecies.CAT;
    }
    if (value === PetSpecies.RABBIT) {
      return PetSpecies.RABBIT;
    }
    if (value === PetSpecies.BIRD) {
      return PetSpecies.BIRD;
    }
    return PetSpecies.OTHER;
  }

  private static mapGender(value: string): PetGender {
    if (value === PetGender.MALE) {
      return PetGender.MALE;
    }
    if (value === PetGender.FEMALE) {
      return PetGender.FEMALE;
    }
    return PetGender.UNKNOWN;
  }

  private static mapProviderType(value: string): ProviderType {
    if (value === ProviderType.GROOMING) {
      return ProviderType.GROOMING;
    }
    if (value === ProviderType.BOARDING) {
      return ProviderType.BOARDING;
    }
    return ProviderType.HOSPITAL;
  }

  private static mapAppointmentStatus(value: string): AppointmentStatus {
    if (value === AppointmentStatus.CONFIRMED) {
      return AppointmentStatus.CONFIRMED;
    }
    if (value === AppointmentStatus.COMPLETED) {
      return AppointmentStatus.COMPLETED;
    }
    if (value === AppointmentStatus.CANCELLED) {
      return AppointmentStatus.CANCELLED;
    }
    if (value === AppointmentStatus.EXPIRED) {
      return AppointmentStatus.EXPIRED;
    }
    return AppointmentStatus.PENDING_CONFIRM;
  }
}

