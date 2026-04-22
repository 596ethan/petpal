import {
  Appointment,
  HealthRecord,
  Pet,
  ServiceItem,
  ServiceProvider,
  UserProfile,
  VaccineRecord
} from '../models/PetPalModels';
import { PetPalHttpClient, PetPalHttpMethod } from './PetPalHttpClient';
import { PetPalSessionSnapshot, PetPalSessionStore } from './PetPalSessionStore';

export interface PetPalLoginRequest {
  phone: string;
  password: string;
}

export interface PetPalLoginResult {
  accessToken: string;
  refreshToken?: string;
  userProfile?: UserProfile;
  raw: Object;
}

export interface PetPalApiClientConfig {
  baseUrl: string;
  timeoutMs?: number;
}

interface PetPalApiRequestOptions {
  auth?: boolean;
  body?: string | Object | ArrayBuffer;
  headers?: Record<string, string>;
  timeoutMs?: number;
  query?: Record<string, string | number | boolean | undefined | null>;
}

interface PetPalApiEnvelope<T> {
  code: string;
  message: string;
  data: T;
}

interface PetPalBackendTokenPayload {
  accessToken: string;
  refreshToken: string;
}

interface PetPalBackendUserProfilePayload {
  id: number;
  phone?: string;
  nickname: string;
  avatarUrl?: string | null;
  bio?: string | null;
  followingCount?: number | null;
  followerCount?: number | null;
}

interface PetPalBackendLoginPayload {
  profile: PetPalBackendUserProfilePayload;
  tokens: PetPalBackendTokenPayload;
}

export class PetPalApiClient {
  private static client: PetPalHttpClient | null = null;

  static configure(config: PetPalApiClientConfig): void {
    PetPalApiClient.client = new PetPalHttpClient(config.baseUrl, config.timeoutMs ?? 15000);
  }

  static async login(requestBody: PetPalLoginRequest): Promise<PetPalLoginResult> {
    const options: PetPalApiRequestOptions = {
      auth: false,
      body: requestBody
    };
    const payload = await PetPalApiClient.requestJson<PetPalBackendLoginPayload>(PetPalHttpMethod.POST, '/user/login', options);
    const accessToken = payload.tokens.accessToken.trim();
    if (!accessToken) {
      throw new Error('登录响应缺少访问令牌');
    }

    const refreshToken = payload.tokens.refreshToken.trim();
    const userProfile = PetPalApiClient.mapUserProfile(payload.profile);
    const snapshot: PetPalSessionSnapshot = {
      accessToken: accessToken,
      refreshToken: refreshToken,
      userProfile: userProfile
    };
    await PetPalSessionStore.setSession(snapshot);

    return {
      accessToken: accessToken,
      refreshToken: refreshToken,
      userProfile: userProfile,
      raw: payload as Object
    };
  }

  static async getCurrentUserProfile(): Promise<UserProfile> {
    return PetPalApiClient.requestJson<UserProfile>(PetPalHttpMethod.GET, '/user/profile');
  }

  static async listPets(): Promise<Pet[]> {
    return PetPalApiClient.requestJson<Pet[]>(PetPalHttpMethod.GET, '/pet/list');
  }

  static async getPet(id: number): Promise<Pet> {
    return PetPalApiClient.requestJson<Pet>(PetPalHttpMethod.GET, `/pet/${id}`);
  }

  static async getPetHealth(id: number): Promise<HealthRecord[]> {
    return PetPalApiClient.requestJson<HealthRecord[]>(PetPalHttpMethod.GET, `/pet/${id}/health`);
  }

  static async getPetVaccines(id: number): Promise<VaccineRecord[]> {
    return PetPalApiClient.requestJson<VaccineRecord[]>(PetPalHttpMethod.GET, `/pet/${id}/vaccine`);
  }

  static async listProviders(): Promise<ServiceProvider[]> {
    return PetPalApiClient.requestJson<ServiceProvider[]>(PetPalHttpMethod.GET, '/provider/list');
  }

  static async getProvider(id: number): Promise<ServiceProvider> {
    return PetPalApiClient.requestJson<ServiceProvider>(PetPalHttpMethod.GET, `/provider/${id}`);
  }

  static async listProviderServices(id: number): Promise<ServiceItem[]> {
    return PetPalApiClient.requestJson<ServiceItem[]>(PetPalHttpMethod.GET, `/provider/${id}/services`);
  }

  static async listAppointments(): Promise<Appointment[]> {
    return PetPalApiClient.requestJson<Appointment[]>(PetPalHttpMethod.GET, '/appointment/list');
  }

  static async createAppointment(payload: Object): Promise<Appointment> {
    const options: PetPalApiRequestOptions = {
      body: payload
    };
    return PetPalApiClient.requestJson<Appointment>(PetPalHttpMethod.POST, '/appointment', options);
  }

  static async cancelAppointment(id: number): Promise<Appointment> {
    return PetPalApiClient.requestJson<Appointment>(PetPalHttpMethod.PUT, `/appointment/${id}/cancel`);
  }

  static async get<T>(path: string): Promise<T> {
    return PetPalApiClient.requestJson<T>(PetPalHttpMethod.GET, path);
  }

  static async post<T>(path: string, body?: string | Object | ArrayBuffer): Promise<T> {
    const options: PetPalApiRequestOptions = {
      body: body
    };
    return PetPalApiClient.requestJson<T>(PetPalHttpMethod.POST, path, options);
  }

  static async put<T>(path: string, body?: string | Object | ArrayBuffer): Promise<T> {
    const options: PetPalApiRequestOptions = {
      body: body
    };
    return PetPalApiClient.requestJson<T>(PetPalHttpMethod.PUT, path, options);
  }

  static async delete<T>(path: string): Promise<T> {
    return PetPalApiClient.requestJson<T>(PetPalHttpMethod.DELETE, path);
  }

  private static async requestJson<T>(
    method: PetPalHttpMethod,
    path: string,
    options: PetPalApiRequestOptions = {}
  ): Promise<T> {
    const client = PetPalApiClient.requireClient();
    const response = await client.request<PetPalApiEnvelope<T>>(method, path, {
      auth: options.auth !== false,
      body: options.body,
      headers: options.headers,
      timeoutMs: options.timeoutMs,
      query: options.query
    });
    return PetPalApiClient.unwrap(response.data);
  }

  private static requireClient(): PetPalHttpClient {
    if (PetPalApiClient.client === null) {
      throw new Error('PetPalApiClient 尚未配置，请先调用 configure');
    }
    return PetPalApiClient.client;
  }

  private static unwrap<T>(value: PetPalApiEnvelope<T>): T {
    if (value.code !== 'OK') {
      throw new Error(value.message);
    }
    return value.data;
  }

  private static mapUserProfile(profile: PetPalBackendUserProfilePayload): UserProfile {
    return {
      id: profile.id,
      nickname: profile.nickname,
      bio: profile.bio ?? '',
      avatarUrl: profile.avatarUrl ?? '',
      followingCount: profile.followingCount ?? 0,
      followerCount: profile.followerCount ?? 0
    };
  }
}
