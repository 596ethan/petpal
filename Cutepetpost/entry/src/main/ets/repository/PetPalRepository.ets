import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import {
  Appointment,
  AppointmentStatus,
  CommentItem,
  HealthRecordCreateInput,
  PetCreateInput,
  PetUpdateInput,
  VaccineRecordCreateInput,
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
import { PETPAL_API_BASE_URL } from '../config/PetPalAppConfig';
import { PetPalSessionSnapshot, PetPalSessionStore } from '../services/PetPalSessionStore';

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
  breed?: string;
  gender: string;
  birthday?: string | null;
  weight?: number | null;
  avatarUrl?: string | null;
  neutered: boolean;
}

interface BackendHealthRecord {
  id: number;
  recordType: string;
  title: string;
  description?: string | null;
  recordDate: string;
  nextDate?: string | null;
}

interface BackendVaccineRecord {
  id: number;
  vaccineName: string;
  vaccinatedAt: string;
  nextDueAt?: string | null;
  hospital?: string | null;
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

interface BackendPost {
  id: number;
  userNickname: string;
  userAvatarUrl: string;
  petName?: string;
  content: string;
  topics: string[];
  likeCount: number;
  commentCount: number;
  createdAt: string;
}

interface BackendComment {
  id: number;
  userNickname: string;
  content: string;
  createdAt: string;
}

interface LoginRequestPayload {
  phone: string;
  password: string;
}

export interface PetPalRepositoryRequest {
  path: string;
  method: http.RequestMethod;
  body?: Object;
  authRequired: boolean;
  headers: Record<string, string>;
}

export interface PetPalRepositoryResponse {
  responseCode: number;
  result: string;
}

export type PetPalRepositoryRequestHandler = (request: PetPalRepositoryRequest) => Promise<PetPalRepositoryResponse>;

export interface AppointmentCreateInput {
  petId: number;
  providerId: number;
  serviceId: number;
  appointmentTime: string;
  remark: string;
}

export class PetPalRepository {
  private static apiBaseUrl: string = PETPAL_API_BASE_URL;
  private static session: LoginSession | null = null;
  private static postCache: Post[] = posts;
  private static commentCache: Record<number, CommentItem[]> = {};
  private static testRequestHandler: PetPalRepositoryRequestHandler | null = null;

  static initialize(context: common.UIAbilityContext): void {
    PetPalSessionStore.initialize(context);
    PetPalRepository.hydrateSessionFromStore();
    PetPalRepository.apiBaseUrl = PetPalRepository.normalizeBaseUrl(PetPalRepository.apiBaseUrl);
  }

  static getCurrentUser(): UserProfile {
    PetPalRepository.hydrateSessionFromStore();
    if (PetPalRepository.session !== null) {
      return PetPalRepository.session.profile;
    }
    return currentUser;
  }

  static getSession(): LoginSession | null {
    PetPalRepository.hydrateSessionFromStore();
    return PetPalRepository.session;
  }

  static setApiBaseUrl(baseUrl: string): void {
    const normalized = PetPalRepository.normalizeBaseUrl(baseUrl);
    if (normalized.length > 0) {
      PetPalRepository.apiBaseUrl = normalized;
    }
  }

  static storeSession(session: LoginSession): void {
    PetPalRepository.session = session;
    PetPalRepository.persistSession(session);
  }

  static clearSession(): void {
    PetPalRepository.session = null;
    void PetPalRepository.clearPersistedSession();
  }

  static setRequestHandlerForTest(handler: PetPalRepositoryRequestHandler | null): void {
    PetPalRepository.testRequestHandler = handler;
  }

  static resetForTest(): void {
    PetPalRepository.testRequestHandler = null;
    PetPalRepository.session = null;
    PetPalRepository.apiBaseUrl = PetPalRepository.normalizeBaseUrl(PETPAL_API_BASE_URL);
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
    return PetPalRepository.postCache;
  }

  static getPostById(id: number): Post {
    const post = PetPalRepository.postCache.find((item: Post) => item.id === id);
    return post ?? PetPalRepository.postCache[0] ?? posts[0];
  }

  static getComments(postId: number): CommentItem[] {
    return PetPalRepository.commentCache[postId] ?? comments;
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
    PetPalRepository.storeSession(session);
    return session;
  }

  static async loginAsync(phone: string, password: string): Promise<LoginSession> {
    return PetPalRepository.login(phone, password);
  }

  static async getCurrentUserRemote(): Promise<UserProfile> {
    const payload = await PetPalRepository.request<BackendUserProfilePayload>('/user/profile', http.RequestMethod.GET);
    const profile = PetPalRepository.mapProfile(payload);
    if (PetPalRepository.session !== null) {
      PetPalRepository.storeSession({
        accessToken: PetPalRepository.session.accessToken,
        refreshToken: PetPalRepository.session.refreshToken,
        profile: profile
      });
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
    return payload.map((item: BackendHealthRecord) => PetPalRepository.mapHealthRecord(item));
  }

  static async createPet(input: PetCreateInput): Promise<Pet> {
    const payload = await PetPalRepository.request<BackendPet>(`/pet`, http.RequestMethod.POST, input);
    return PetPalRepository.mapPet(payload);
  }

  static async updatePet(petId: number, input: PetUpdateInput): Promise<Pet> {
    const payload = await PetPalRepository.request<BackendPet>(`/pet/${petId}`, http.RequestMethod.PUT, input);
    return PetPalRepository.mapPet(payload);
  }

  static async deletePet(petId: number): Promise<void> {
    await PetPalRepository.request<void>(`/pet/${petId}`, http.RequestMethod.DELETE);
  }

  static async addHealthRecord(petId: number, input: HealthRecordCreateInput): Promise<HealthRecord> {
    const payload = await PetPalRepository.request<BackendHealthRecord>(`/pet/${petId}/health`, http.RequestMethod.POST, input);
    return PetPalRepository.mapHealthRecord(payload);
  }

  static async getVaccineRecords(petId: number): Promise<VaccineRecord[]> {
    const payload = await PetPalRepository.request<BackendVaccineRecord[]>(`/pet/${petId}/vaccine`, http.RequestMethod.GET);
    return payload.map((item: BackendVaccineRecord) => PetPalRepository.mapVaccineRecord(item));
  }

  static async getVaccineRecordsAsync(petId: number): Promise<VaccineRecord[]> {
    return PetPalRepository.getVaccineRecords(petId);
  }

  static async addVaccineRecord(petId: number, input: VaccineRecordCreateInput): Promise<VaccineRecord> {
    const payload = await PetPalRepository.request<BackendVaccineRecord>(`/pet/${petId}/vaccine`, http.RequestMethod.POST, input);
    return PetPalRepository.mapVaccineRecord(payload);
  }

  static async getVaccinesAsync(petId: number): Promise<VaccineRecord[]> {
    return PetPalRepository.getVaccineRecords(petId);
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

  static async getPostsAsync(): Promise<Post[]> {
    const payload = await PetPalRepository.request<BackendPost[]>('/post/feed', http.RequestMethod.GET, undefined, false);
    const mapped = payload.map((item: BackendPost) => PetPalRepository.mapPost(item));
    if (mapped.length > 0) {
      PetPalRepository.postCache = mapped;
    }
    return mapped;
  }

  static async getPostByIdAsync(postId: number): Promise<Post> {
    const payload = await PetPalRepository.request<BackendPost>(`/post/${postId}`, http.RequestMethod.GET, undefined, false);
    const mapped = PetPalRepository.mapPost(payload);
    const existingIndex = PetPalRepository.postCache.findIndex((item: Post) => item.id === postId);
    if (existingIndex >= 0) {
      PetPalRepository.postCache[existingIndex] = mapped;
    }
    return mapped;
  }

  static async getCommentsAsync(postId: number): Promise<CommentItem[]> {
    const payload = await PetPalRepository.request<BackendComment[]>(`/post/${postId}/comment`, http.RequestMethod.GET, undefined, false);
    const mapped = payload.map((item: BackendComment) => PetPalRepository.mapComment(item));
    PetPalRepository.commentCache[postId] = mapped;
    return mapped;
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
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (authRequired && PetPalRepository.session !== null) {
      headers.Authorization = `Bearer ${PetPalRepository.session.accessToken}`;
    }

    if (PetPalRepository.testRequestHandler !== null) {
      const response = await PetPalRepository.testRequestHandler({
        path: path,
        method: method,
        body: body,
        authRequired: authRequired,
        headers: headers
      });
      return PetPalRepository.parseResponse<T>(response.responseCode, response.result, authRequired);
    }

    const request = http.createHttp();
    try {
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
      let response: http.HttpResponse;
      try {
        response = await request.request(`${PetPalRepository.apiBaseUrl}${path}`, options);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Request failed';
        throw new Error(message);
      }
      const raw = String(response.result);
      let envelope: BackendEnvelope<T> | null = null;
      try {
        envelope = JSON.parse(raw) as BackendEnvelope<T>;
      } catch {
        envelope = null;
      }

      if (response.responseCode === 401 || response.responseCode === 403) {
        if (authRequired) {
          await PetPalRepository.clearPersistedSession();
          throw new Error(envelope?.message ?? '登录已失效，请重新登录');
        }
        throw new Error(envelope?.message ?? '登录失败，请检查账号密码');
      }

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(envelope?.message ?? `HTTP ${response.responseCode}`);
      }
      if (envelope === null) {
        throw new Error('Invalid server response');
      }
      if (envelope.code !== 'OK') {
        throw new Error(envelope.message);
      }
      return envelope.data;
    } finally {
      request.destroy();
    }
  }

  private static async parseResponse<T>(responseCode: number, raw: string, authRequired: boolean): Promise<T> {
    let envelope: BackendEnvelope<T> | null = null;
    try {
      envelope = JSON.parse(raw) as BackendEnvelope<T>;
    } catch {
      envelope = null;
    }

    if (responseCode === 401 || responseCode === 403) {
      if (authRequired) {
        await PetPalRepository.clearPersistedSession();
        throw new Error(envelope?.message ?? '登录已失效，请重新登录');
      }
      throw new Error(envelope?.message ?? '登录失败，请检查账号密码');
    }

    if (responseCode < 200 || responseCode >= 300) {
      throw new Error(envelope?.message ?? `HTTP ${responseCode}`);
    }
    if (envelope === null) {
      throw new Error('Invalid server response');
    }
    if (envelope.code !== 'OK') {
      throw new Error(envelope.message);
    }
    return envelope.data;
  }

  private static normalizeBaseUrl(baseUrl: string): string {
    const normalized = baseUrl.trim();
    return normalized.endsWith('/') ? normalized.slice(0, normalized.length - 1) : normalized;
  }

  private static hydrateSessionFromStore(): void {
    if (PetPalRepository.session !== null || !PetPalSessionStore.isInitialized()) {
      return;
    }

    const snapshot = PetPalSessionStore.getSnapshot();
    if (!snapshot?.accessToken) {
      return;
    }

    PetPalRepository.session = {
      accessToken: snapshot.accessToken,
      refreshToken: snapshot.refreshToken ?? '',
      profile: snapshot.userProfile ?? currentUser
    };
  }

  private static persistSession(session: LoginSession): void {
    if (!PetPalSessionStore.isInitialized()) {
      return;
    }

    const snapshot: PetPalSessionSnapshot = {
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userProfile: session.profile
    };
    void PetPalSessionStore.setSession(snapshot);
  }

  private static async clearPersistedSession(): Promise<void> {
    PetPalRepository.session = null;
    if (PetPalSessionStore.isInitialized()) {
      await PetPalSessionStore.clear();
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
      breed: item.breed ?? "",
      gender: PetPalRepository.mapGender(item.gender),
      birthday: item.birthday ?? "",
      weight: item.weight === undefined || item.weight === null ? "" : `${item.weight}`,
      avatarUrl: item.avatarUrl ?? "",
      neutered: item.neutered
    };
    return result;
  }

  private static mapHealthRecord(item: BackendHealthRecord): HealthRecord {
    const result: HealthRecord = {
      id: item.id,
      title: item.title,
      summary: item.description ?? "",
      recordDate: item.recordDate,
      nextDate: item.nextDate ?? ""
    };
    return result;
  }

  private static mapVaccineRecord(item: BackendVaccineRecord): VaccineRecord {
    const result: VaccineRecord = {
      id: item.id,
      vaccineName: item.vaccineName,
      vaccinatedAt: item.vaccinatedAt,
      nextDueAt: item.nextDueAt ?? "",
      hospital: item.hospital ?? ""
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

  private static mapPost(item: BackendPost): Post {
    return {
      id: item.id,
      authorName: item.userNickname,
      authorAvatarUrl: item.userAvatarUrl,
      petName: item.petName ?? 'PetPal',
      content: item.content,
      imageUrls: [],
      topics: item.topics,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      createdAt: item.createdAt
    };
  }

  private static mapComment(item: BackendComment): CommentItem {
    return {
      id: item.id,
      userName: item.userNickname,
      content: item.content,
      createdAt: item.createdAt
    };
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
