import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import {
  Appointment,
  AppointmentStatus,
  CommentCreateInput,
  CommentItem,
  FileUploadInput,
  FileUploadResult,
  HealthRecordCreateInput,
  PetCreateInput,
  PetUpdateInput,
  PostCreateInput,
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
  userId: number;
  userNickname: string;
  userAvatarUrl: string;
  petId?: number | null;
  petName?: string;
  content: string;
  imageUrls?: string[];
  topics: string[];
  likeCount: number;
  commentCount: number;
  liked: boolean;
  createdAt: string;
}

interface BackendComment {
  id: number;
  parentId?: number | null;
  userId: number;
  userNickname: string;
  content: string;
  createdAt: string;
}

interface BackendFileUpload {
  fileKey: string;
  url: string;
}

interface LoginRequestPayload {
  phone: string;
  password: string;
}

export interface PetPalRepositoryRequest {
  path: string;
  method: http.RequestMethod;
  body?: Object | string | ArrayBuffer;
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
    const payload = await PetPalRepository.request<BackendPost[]>('/post/feed', http.RequestMethod.GET, undefined, PetPalRepository.communityReadAuthRequired());
    const mapped = payload.map((item: BackendPost) => PetPalRepository.mapPost(item));
    PetPalRepository.postCache = mapped;
    return mapped;
  }

  static async getPostByIdAsync(postId: number): Promise<Post> {
    const payload = await PetPalRepository.request<BackendPost>(`/post/${postId}`, http.RequestMethod.GET, undefined, PetPalRepository.communityReadAuthRequired());
    const mapped = PetPalRepository.mapPost(payload);
    PetPalRepository.upsertPostCache(mapped);
    return mapped;
  }

  static async getCommentsAsync(postId: number): Promise<CommentItem[]> {
    const payload = await PetPalRepository.request<BackendComment[]>(`/post/${postId}/comment`, http.RequestMethod.GET, undefined, PetPalRepository.communityReadAuthRequired());
    const mapped = payload.map((item: BackendComment) => PetPalRepository.mapComment(item));
    PetPalRepository.commentCache[postId] = mapped;
    return mapped;
  }

  static async createPost(input: PostCreateInput): Promise<Post> {
    const payload = await PetPalRepository.request<BackendPost>('/post', http.RequestMethod.POST, input);
    const mapped = PetPalRepository.mapPost(payload);
    PetPalRepository.postCache = [mapped].concat(PetPalRepository.postCache.filter((item: Post) => item.id !== mapped.id));
    return mapped;
  }

  static async deletePost(postId: number): Promise<void> {
    await PetPalRepository.request<void>(`/post/${postId}`, http.RequestMethod.DELETE);
    PetPalRepository.postCache = PetPalRepository.postCache.filter((item: Post) => item.id !== postId);
    PetPalRepository.commentCache[postId] = [];
  }

  static async likePost(postId: number): Promise<Post> {
    await PetPalRepository.request<void>(`/post/${postId}/like`, http.RequestMethod.POST);
    return PetPalRepository.getPostByIdAsync(postId);
  }

  static async unlikePost(postId: number): Promise<Post> {
    await PetPalRepository.request<void>(`/post/${postId}/like`, http.RequestMethod.DELETE);
    return PetPalRepository.getPostByIdAsync(postId);
  }

  static async addComment(postId: number, input: CommentCreateInput): Promise<CommentItem> {
    const payload = await PetPalRepository.request<BackendComment>(`/post/${postId}/comment`, http.RequestMethod.POST, input);
    const mapped = PetPalRepository.mapComment(payload);
    const existing = PetPalRepository.commentCache[postId] ?? [];
    PetPalRepository.commentCache[postId] = existing.concat([mapped]);
    PetPalRepository.postCache = PetPalRepository.postCache.map((item: Post) => {
      if (item.id !== postId) {
        return item;
      }
      return {
        id: item.id,
        userId: item.userId,
        authorName: item.authorName,
        authorAvatarUrl: item.authorAvatarUrl,
        petId: item.petId,
        petName: item.petName,
        content: item.content,
        imageUrls: item.imageUrls,
        topics: item.topics,
        likeCount: item.likeCount,
        commentCount: item.commentCount + 1,
        liked: item.liked,
        createdAt: item.createdAt
      };
    });
    return mapped;
  }

  static async uploadPostImage(input: FileUploadInput): Promise<FileUploadResult> {
    const boundary = `----PetPalBoundary${Date.now()}`;
    const body = PetPalRepository.buildMultipartBody(input, boundary);
    const payload = await PetPalRepository.request<BackendFileUpload>(
      '/file/upload',
      http.RequestMethod.POST,
      body,
      true,
      {
        'Content-Type': `multipart/form-data; boundary=${boundary}`
      }
    );
    return {
      fileKey: payload.fileKey,
      url: payload.url
    };
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
    body?: Object | string | ArrayBuffer,
    authRequired: boolean = true,
    extraHeaders?: Record<string, string>
  ): Promise<T> {
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (authRequired && PetPalRepository.session !== null) {
      headers.Authorization = `Bearer ${PetPalRepository.session.accessToken}`;
    }
    if (extraHeaders?.['Content-Type'] !== undefined) {
      headers['Content-Type'] = extraHeaders['Content-Type'];
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
        options.extraData = PetPalRepository.serializeBody(body) as string | Object | ArrayBuffer;
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

  private static serializeBody(body: Object | string | ArrayBuffer): string | Object | ArrayBuffer {
    if (typeof body === 'string' || body instanceof ArrayBuffer) {
      return body;
    }
    return JSON.stringify(body);
  }

  private static communityReadAuthRequired(): boolean {
    PetPalRepository.hydrateSessionFromStore();
    return PetPalRepository.session !== null;
  }

  private static upsertPostCache(post: Post): void {
    const existingIndex = PetPalRepository.postCache.findIndex((item: Post) => item.id === post.id);
    if (existingIndex >= 0) {
      PetPalRepository.postCache[existingIndex] = post;
      return;
    }
    PetPalRepository.postCache = [post].concat(PetPalRepository.postCache);
  }

  private static buildMultipartBody(input: FileUploadInput, boundary: string): ArrayBuffer {
    const fileName = PetPalRepository.escapeMultipartValue(input.fileName.length > 0 ? input.fileName : 'image.jpg');
    const contentType = input.contentType.length > 0 ? input.contentType : 'image/jpeg';
    const header = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\nContent-Type: ${contentType}\r\n\r\n`;
    const footer = `\r\n--${boundary}--\r\n`;
    const headerBytes = new Uint8Array(PetPalRepository.encodeUtf8(header));
    const fileBytes = new Uint8Array(input.data);
    const footerBytes = new Uint8Array(PetPalRepository.encodeUtf8(footer));
    const body = new Uint8Array(headerBytes.byteLength + fileBytes.byteLength + footerBytes.byteLength);
    body.set(headerBytes, 0);
    body.set(fileBytes, headerBytes.byteLength);
    body.set(footerBytes, headerBytes.byteLength + fileBytes.byteLength);
    return body.buffer;
  }

  private static encodeUtf8(value: string): ArrayBuffer {
    const bytes = new Uint8Array(value.length);
    for (let i = 0; i < value.length; i++) {
      const code = value.charCodeAt(i);
      bytes[i] = code <= 0x7F ? code : 95;
    }
    return bytes.buffer;
  }

  private static escapeMultipartValue(value: string): string {
    return value.replace(/"/g, '').replace(/\r/g, '').replace(/\n/g, '');
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
      userId: item.userId ?? 0,
      authorName: item.userNickname,
      authorAvatarUrl: item.userAvatarUrl,
      petId: item.petId ?? undefined,
      petName: item.petName ?? 'PetPal',
      content: item.content,
      imageUrls: item.imageUrls ?? [],
      topics: item.topics ?? [],
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      liked: item.liked ?? false,
      createdAt: item.createdAt
    };
  }

  private static mapComment(item: BackendComment): CommentItem {
    return {
      id: item.id,
      userId: item.userId ?? 0,
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
