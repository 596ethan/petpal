import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import { UserProfile } from '../models/PetPalModels';

const SESSION_STORAGE_NAME = 'petpal_session';
const SESSION_STORAGE_KEY = 'session';

export interface PetPalSessionSnapshot {
  accessToken: string;
  refreshToken?: string;
  expiresAt?: number;
  userProfile?: UserProfile;
}

export class PetPalSessionStore {
  private static context: common.UIAbilityContext | null = null;
  private static pref: preferences.Preferences | null = null;
  private static snapshot: PetPalSessionSnapshot | null = null;

  static initialize(context: common.UIAbilityContext): void {
    this.context = context;
    this.pref = preferences.getPreferencesSync(context, { name: SESSION_STORAGE_NAME });
    const storedSnapshot = this.readSnapshot();
    if (storedSnapshot) {
      this.snapshot = storedSnapshot;
    }
  }

  static isInitialized(): boolean {
    return this.pref !== null;
  }

  static isAuthenticated(): boolean {
    return (this.snapshot?.accessToken ?? '').length > 0;
  }

  static getAccessToken(): string {
    return this.snapshot?.accessToken ?? '';
  }

  static getUserProfile(): UserProfile | undefined {
    return this.snapshot?.userProfile;
  }

  static getSnapshot(): PetPalSessionSnapshot | null {
    return this.snapshot;
  }

  static getAuthHeaders(): Record<string, string> {
    const token = this.getAccessToken();
    return token ? { Authorization: `Bearer ${token}` } : {};
  }

  static async setSession(snapshot: PetPalSessionSnapshot): Promise<void> {
    this.snapshot = this.normalizeSnapshot(snapshot);
    await this.persistSnapshot();
  }

  static async setAccessToken(accessToken: string): Promise<void> {
    await this.setSession({
      accessToken: accessToken,
      refreshToken: this.snapshot?.refreshToken,
      expiresAt: this.snapshot?.expiresAt,
      userProfile: this.snapshot?.userProfile
    });
  }

  static async setUserProfile(userProfile: UserProfile): Promise<void> {
    await this.setSession({
      accessToken: this.getAccessToken(),
      refreshToken: this.snapshot?.refreshToken,
      expiresAt: this.snapshot?.expiresAt,
      userProfile: userProfile
    });
  }

  static async clear(): Promise<void> {
    this.snapshot = null;
    if (this.pref) {
      await this.pref.clear();
      await this.pref.flush();
    }
  }

  private static normalizeSnapshot(snapshot: PetPalSessionSnapshot): PetPalSessionSnapshot {
    return {
      accessToken: snapshot.accessToken.trim(),
      refreshToken: snapshot.refreshToken?.trim(),
      expiresAt: snapshot.expiresAt,
      userProfile: snapshot.userProfile
    };
  }

  private static readSnapshot(): PetPalSessionSnapshot | null {
    if (!this.pref) {
      return this.snapshot;
    }

    const raw = this.pref.get(SESSION_STORAGE_KEY, '') as string;
    if (!raw) {
      return null;
    }

    try {
      const parsed = JSON.parse(raw) as PetPalSessionSnapshot;
      if (!parsed.accessToken) {
        return null;
      }
      return this.normalizeSnapshot(parsed);
    } catch {
      return null;
    }
  }

  private static async persistSnapshot(): Promise<void> {
    if (!this.pref) {
      return;
    }
    if (!this.snapshot || !this.snapshot.accessToken) {
      await this.pref.delete(SESSION_STORAGE_KEY);
      await this.pref.flush();
      return;
    }

    await this.pref.put(SESSION_STORAGE_KEY, JSON.stringify(this.snapshot));
    await this.pref.flush();
  }
}
