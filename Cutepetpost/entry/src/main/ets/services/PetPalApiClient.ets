import {
  Appointment,
  HealthRecord,
  Pet,
  ServiceItem,
  ServiceProvider,
  UserProfile,
  VaccineRecord
} from '../models/PetPalModels';
import { PetPalHttpClient } from './PetPalHttpClient';
import { PetPalSessionSnapshot, PetPalSessionStore } from './PetPalSessionStore';

export interface PetPalLoginRequest {
  phone: string;
  password: string;
}

export interface PetPalLoginResult {
  accessToken: string;
  refreshToken?: string;
  userProfile?: UserProfile;
  raw: unknown;
}

export interface PetPalApiClientConfig {
  baseUrl: string;
  timeoutMs?: number;
}

export class PetPalApiClient {
  private static client: PetPalHttpClient | null = null;

  static configure(config: PetPalApiClientConfig): void {
    this.client = new PetPalHttpClient(config.baseUrl, config.timeoutMs ?? 15000);
  }

  static async login(requestBody: PetPalLoginRequest): Promise<PetPalLoginResult> {
    const response = await this.requestJson<unknown>('POST', '/api/user/login', {
      auth: false,
      body: requestBody
    });
    const payload = this.unwrap(response.data);
    const accessToken =
      typeof payload === 'string' && payload.trim().length > 0
        ? payload.trim()
        : this.pickString(payload, ['accessToken', 'token', 'jwt']);
    if (!accessToken) {
      throw new Error('Login response did not include an access token.');
    }

    const refreshToken = this.pickString(payload, ['refreshToken', 'refresh_token']);
    const userProfile = this.pickUserProfile(payload);
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
      raw: payload
    };
  }

  static async getCurrentUserProfile(): Promise<UserProfile> {
    return this.requestJson<UserProfile>('GET', '/api/user/profile');
  }

  static async listPets(): Promise<Pet[]> {
    return this.requestJson<Pet[]>('GET', '/api/pet/list');
  }

  static async getPet(id: number): Promise<Pet> {
    return this.requestJson<Pet>('GET', `/api/pet/${id}`);
  }

  static async getPetHealth(id: number): Promise<HealthRecord[]> {
    return this.requestJson<HealthRecord[]>('GET', `/api/pet/${id}/health`);
  }

  static async getPetVaccines(id: number): Promise<VaccineRecord[]> {
    return this.requestJson<VaccineRecord[]>('GET', `/api/pet/${id}/vaccine`);
  }

  static async listProviders(): Promise<ServiceProvider[]> {
    return this.requestJson<ServiceProvider[]>('GET', '/api/provider/list');
  }

  static async getProvider(id: number): Promise<ServiceProvider> {
    return this.requestJson<ServiceProvider>('GET', `/api/provider/${id}`);
  }

  static async listProviderServices(id: number): Promise<ServiceItem[]> {
    return this.requestJson<ServiceItem[]>('GET', `/api/provider/${id}/services`);
  }

  static async listAppointments(): Promise<Appointment[]> {
    return this.requestJson<Appointment[]>('GET', '/api/appointment/list');
  }

  static async createAppointment(payload: Record<string, unknown>): Promise<Appointment> {
    return this.requestJson<Appointment>('POST', '/api/appointment', { body: payload });
  }

  static async cancelAppointment(id: number): Promise<Appointment> {
    return this.requestJson<Appointment>('PUT', `/api/appointment/${id}/cancel`);
  }

  static async get<T>(path: string): Promise<T> {
    return this.requestJson<T>('GET', path);
  }

  static async post<T>(path: string, body?: string | Record<string, unknown> | ArrayBuffer): Promise<T> {
    return this.requestJson<T>('POST', path, { body: body });
  }

  static async put<T>(path: string, body?: string | Record<string, unknown> | ArrayBuffer): Promise<T> {
    return this.requestJson<T>('PUT', path, { body: body });
  }

  private static async requestJson<T>(
    method: 'GET' | 'POST' | 'PUT',
    path: string,
    options: {
      auth?: boolean;
      body?: string | Record<string, unknown> | ArrayBuffer;
      headers?: Record<string, string>;
      timeoutMs?: number;
      query?: Record<string, string | number | boolean | undefined | null>;
    } = {}
  ): Promise<T> {
    const client = this.requireClient();
    const response = await client.request<unknown>(method, path, {
      auth: options.auth !== false,
      body: options.body,
      headers: options.headers,
      timeoutMs: options.timeoutMs,
      query: options.query
    });
    return this.unwrap(response.data) as T;
  }

  private static requireClient(): PetPalHttpClient {
    if (!this.client) {
      throw new Error('PetPalApiClient is not configured. Call PetPalApiClient.configure(baseUrl) first.');
    }
    return this.client;
  }

  private static unwrap<T>(value: T): T {
    if (value && typeof value === 'object') {
      const objectValue = value as Record<string, unknown>;
      if ('data' in objectValue) {
        return objectValue.data as T;
      }
      if ('result' in objectValue) {
        return objectValue.result as T;
      }
      if ('payload' in objectValue) {
        return objectValue.payload as T;
      }
    }
    return value;
  }

  private static pickString(value: unknown, keys: string[]): string {
    if (!value || typeof value !== 'object') {
      return '';
    }

    const objectValue = value as Record<string, unknown>;
    for (const key of keys) {
      const candidate = objectValue[key];
      if (typeof candidate === 'string' && candidate.trim().length > 0) {
        return candidate.trim();
      }
    }

    return '';
  }

  private static pickUserProfile(value: unknown): UserProfile | undefined {
    if (!value || typeof value !== 'object') {
      return undefined;
    }

    const objectValue = value as Record<string, unknown>;
    const profileSource =
      (objectValue.user as Record<string, unknown> | undefined) ??
      (objectValue.profile as Record<string, unknown> | undefined) ??
      (objectValue.data as Record<string, unknown> | undefined) ??
      objectValue;

    if (!profileSource) {
      return undefined;
    }

    const id = this.pickNumber(profileSource, ['id', 'userId']);
    const nickname = this.pickString(profileSource, ['nickname', 'name', 'username']);
    const avatarUrl = this.pickString(profileSource, ['avatarUrl', 'avatar']);
    const bio = this.pickString(profileSource, ['bio', 'description']);
    const followingCount = this.pickNumber(profileSource, ['followingCount', 'following']) ?? 0;
    const followerCount = this.pickNumber(profileSource, ['followerCount', 'followers']) ?? 0;

    if (id === undefined || nickname.length === 0) {
      return undefined;
    }

    return {
      id: id,
      nickname: nickname,
      bio: bio,
      avatarUrl: avatarUrl,
      followingCount: followingCount,
      followerCount: followerCount
    };
  }

  private static pickNumber(value: Record<string, unknown>, keys: string[]): number | undefined {
    for (const key of keys) {
      const candidate = value[key];
      if (typeof candidate === 'number' && !Number.isNaN(candidate)) {
        return candidate;
      }
      if (typeof candidate === 'string' && candidate.trim().length > 0) {
        const parsed = Number(candidate);
        if (!Number.isNaN(parsed)) {
          return parsed;
        }
      }
    }
    return undefined;
  }
}
