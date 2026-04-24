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
import { PETPAL_API_BASE_URL } from '../config/PetPalAppConfig';
import { PetPalApiClient } from '../services/PetPalApiClient';
import { PetPalHttpMethod } from '../services/PetPalHttpClient';
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

const EMPTY_USER_PROFILE: UserProfile = {
  id: 0,
  nickname: '',
  bio: '',
  avatarUrl: '',
  followingCount: 0,
  followerCount: 0
};

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
  // 社区列表和评论保留一份轻量缓存，供列表页返回后详情页即时读取；真实数据仍以接口刷新结果为准。
  private static postCache: Post[] = [];
  private static commentCache: Record<number, CommentItem[]> = {};
  private static testRequestHandler: PetPalRepositoryRequestHandler | null = null;

  // 应用启动时必须先初始化会话存储，再配置 HTTP 客户端，否则后续鉴权请求拿不到本地 token。
  static initialize(context: common.UIAbilityContext): void {
    PetPalSessionStore.initialize(context);
    PetPalRepository.hydrateSessionFromStore();
    PetPalRepository.apiBaseUrl = PetPalRepository.normalizeBaseUrl(PetPalRepository.apiBaseUrl);
    PetPalRepository.configureApiClient();
  }

  static getCurrentUser(): UserProfile {
    PetPalRepository.hydrateSessionFromStore();
    if (PetPalRepository.session !== null) {
      return PetPalRepository.session.profile;
    }
    return EMPTY_USER_PROFILE;
  }

  static getSession(): LoginSession | null {
    PetPalRepository.hydrateSessionFromStore();
    return PetPalRepository.session;
  }

  static setApiBaseUrl(baseUrl: string): void {
    const normalized = PetPalRepository.normalizeBaseUrl(baseUrl);
    if (normalized.length > 0) {
      PetPalRepository.apiBaseUrl = normalized;
      PetPalRepository.configureApiClient();
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
    PetPalRepository.postCache = [];
    PetPalRepository.commentCache = {};
    PetPalRepository.configureApiClient();
  }

  static getPetById(id: number): Pet {
    void id;
    throw new Error('宠物档案需要从后端加载');
  }

  static getHealthRecords(petId: number): HealthRecord[] {
    void petId;
    return [];
  }

  static getVaccines(petId: number): VaccineRecord[] {
    void petId;
    return [];
  }

  static getPosts(): Post[] {
    return PetPalRepository.postCache;
  }

  static getPostById(id: number): Post | null {
    const post = PetPalRepository.postCache.find((item: Post) => item.id === id);
    return post ?? null;
  }

  static getComments(postId: number): CommentItem[] {
    return PetPalRepository.commentCache[postId] ?? [];
  }

  static getProviderById(id: number): ServiceProvider {
    void id;
    throw new Error('服务机构需要从后端加载');
  }

  static getServices(providerId: number): ServiceItem[] {
    void providerId;
    return [];
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
    const payload = await PetPalRepository.request<BackendPost>(
      '/post',
      http.RequestMethod.POST,
      PetPalRepository.normalizePostCreateInput(input)
    );
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
    // HarmonyOS 当前路径下直接拼 multipart 字符串，保证后端按普通文件上传接口接收。
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
      url: PetPalRepository.resolveMediaUrl(payload.url)
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
    // 这里统一组装业务请求头。rawRequest 传 auth:false，是为了避免底层客户端重复注入 Authorization。
    let headers: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
    if (authRequired && PetPalRepository.session !== null) {
      headers.Authorization = `Bearer ${PetPalRepository.session.accessToken}`;
    }
    if (extraHeaders !== undefined) {
      const keys = Object.keys(extraHeaders);
      for (let index = 0; index < keys.length; index++) {
        const key = keys[index];
        headers[key] = extraHeaders[key];
      }
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

    const response = await PetPalApiClient.rawRequest(PetPalRepository.toPetPalHttpMethod(method), path, {
      auth: false,
      headers: headers,
      body: body,
      timeoutMs: 30000
    });
    return PetPalRepository.parseResponse<T>(response.statusCode, response.rawBody, authRequired);
  }

  private static async parseResponse<T>(responseCode: number, raw: string, authRequired: boolean): Promise<T> {
    let envelope: BackendEnvelope<T> | null = null;
    try {
      envelope = JSON.parse(raw) as BackendEnvelope<T>;
    } catch {
      envelope = null;
    }

    if (responseCode === 401 || responseCode === 403) {
      // 受保护接口认证失败时清掉本地会话，让页面走重新登录，而不是继续使用失效 token。
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
      throw new Error('服务器响应格式无效');
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

  private static normalizePostCreateInput(input: PostCreateInput): PostCreateInput {
    const normalized: PostCreateInput = {
      content: input.content
    };
    if (input.petId !== undefined) {
      normalized.petId = input.petId;
    }
    if (input.imageUrls !== undefined) {
      const imageUrls: string[] = [];
      for (let index = 0; index < input.imageUrls.length; index++) {
        const normalizedUrl = PetPalRepository.normalizeMediaUrlForWrite(input.imageUrls[index]);
        if (normalizedUrl.length > 0) {
          imageUrls.push(normalizedUrl);
        }
      }
      if (imageUrls.length > 0) {
        normalized.imageUrls = imageUrls;
      }
    }
    return normalized;
  }

  private static serverOrigin(): string {
    const apiMarker = '/api';
    const markerIndex = PetPalRepository.apiBaseUrl.lastIndexOf(apiMarker);
    if (markerIndex > 0) {
      return PetPalRepository.apiBaseUrl.substring(0, markerIndex);
    }
    return PetPalRepository.apiBaseUrl;
  }

  private static extractBackendProxyPath(url: string): string | null {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return null;
    }
    const marker = '/api/file/object/';
    const markerIndex = trimmed.indexOf(marker);
    if (markerIndex >= 0) {
      const proxyPath = trimmed.substring(markerIndex);
      return proxyPath.length > marker.length ? proxyPath : null;
    }
    if (trimmed.startsWith('/')) {
      return trimmed;
    }
    return null;
  }

  private static resolveMediaUrl(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const proxyPath = PetPalRepository.extractBackendProxyPath(trimmed);
    if (proxyPath !== null) {
      return `${PetPalRepository.serverOrigin()}${proxyPath}`;
    }
    return trimmed;
  }

  private static normalizeMediaUrlForWrite(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const proxyPath = PetPalRepository.extractBackendProxyPath(trimmed);
    if (proxyPath !== null) {
      return proxyPath;
    }
    return trimmed;
  }

  private static configureApiClient(): void {
    PetPalApiClient.configure({
      baseUrl: PetPalRepository.apiBaseUrl,
      timeoutMs: 30000
    });
  }

  private static communityReadAuthRequired(): boolean {
    // 社区读接口允许未登录浏览；已登录时带 token，后端才能返回 liked 等个性化字段。
    PetPalRepository.hydrateSessionFromStore();
    return PetPalRepository.session !== null;
  }

  private static toPetPalHttpMethod(method: http.RequestMethod): PetPalHttpMethod {
    if (method === http.RequestMethod.POST) {
      return PetPalHttpMethod.POST;
    }
    if (method === http.RequestMethod.PUT) {
      return PetPalHttpMethod.PUT;
    }
    if (method === http.RequestMethod.DELETE) {
      return PetPalHttpMethod.DELETE;
    }
    return PetPalHttpMethod.GET;
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
    const bytes: number[] = [];
    for (let i = 0; i < value.length; i++) {
      let code = value.charCodeAt(i);
      if (code >= 0xD800 && code <= 0xDBFF && i + 1 < value.length) {
        const next = value.charCodeAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          code = 0x10000 + (code - 0xD800) * 0x400 + (next - 0xDC00);
          i += 1;
        }
      }
      if (code <= 0x7F) {
        bytes.push(code);
      } else if (code <= 0x7FF) {
        bytes.push(0xC0 + Math.floor(code / 0x40));
        bytes.push(0x80 + code % 0x40);
      } else if (code <= 0xFFFF) {
        bytes.push(0xE0 + Math.floor(code / 0x1000));
        bytes.push(0x80 + Math.floor(code / 0x40) % 0x40);
        bytes.push(0x80 + code % 0x40);
      } else {
        bytes.push(0xF0 + Math.floor(code / 0x40000));
        bytes.push(0x80 + Math.floor(code / 0x1000) % 0x40);
        bytes.push(0x80 + Math.floor(code / 0x40) % 0x40);
        bytes.push(0x80 + code % 0x40);
      }
    }
    const encoded = new Uint8Array(bytes.length);
    for (let index = 0; index < bytes.length; index++) {
      encoded[index] = bytes[index];
    }
    return encoded.buffer;
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
      profile: snapshot.userProfile ?? EMPTY_USER_PROFILE
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
      avatarUrl: PetPalRepository.resolveMediaUrl(profile.avatarUrl),
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
      avatarUrl: item.avatarUrl === undefined || item.avatarUrl === null ? "" : PetPalRepository.resolveMediaUrl(item.avatarUrl),
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
      coverUrl: PetPalRepository.resolveMediaUrl(item.coverUrl),
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
      authorAvatarUrl: PetPalRepository.resolveMediaUrl(item.userAvatarUrl),
      petId: item.petId ?? undefined,
      petName: item.petName ?? 'PetPal',
      content: item.content,
      imageUrls: (item.imageUrls ?? []).map((imageUrl: string) => PetPalRepository.resolveMediaUrl(imageUrl)),
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
