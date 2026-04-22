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
    // preferences 是手机端会话的持久化来源；初始化失败时只退回内存态，不阻断应用启动。
    PetPalSessionStore.context = context;
    try {
      const options: preferences.Options = { name: SESSION_STORAGE_NAME };
      PetPalSessionStore.pref = preferences.getPreferencesSync(context, options);
      const storedSnapshot = PetPalSessionStore.readSnapshot();
      if (storedSnapshot) {
        PetPalSessionStore.snapshot = storedSnapshot;
      }
    } catch {
      PetPalSessionStore.pref = null;
      PetPalSessionStore.snapshot = null;
    }
  }

  static isInitialized(): boolean {
    return PetPalSessionStore.pref !== null;
  }

  static isAuthenticated(): boolean {
    return (PetPalSessionStore.snapshot?.accessToken ?? '').length > 0;
  }

  static getAccessToken(): string {
    return PetPalSessionStore.snapshot?.accessToken ?? '';
  }

  static getUserProfile(): UserProfile | undefined {
    return PetPalSessionStore.snapshot?.userProfile;
  }

  static getSnapshot(): PetPalSessionSnapshot | null {
    return PetPalSessionStore.snapshot;
  }

  static getAuthHeaders(): Record<string, string> {
    const headers: Record<string, string> = {};
    const token = PetPalSessionStore.getAccessToken();
    if (token.length > 0) {
      headers.Authorization = `Bearer ${token}`;
    }
    return headers;
  }

  static async setSession(snapshot: PetPalSessionSnapshot): Promise<void> {
    // 先更新内存快照，页面立即可读；再异步落盘，保证重启后还能恢复登录态。
    PetPalSessionStore.snapshot = PetPalSessionStore.normalizeSnapshot(snapshot);
    await PetPalSessionStore.persistSnapshot();
  }

  static async setAccessToken(accessToken: string): Promise<void> {
    await PetPalSessionStore.setSession({
      accessToken: accessToken,
      refreshToken: PetPalSessionStore.snapshot?.refreshToken,
      expiresAt: PetPalSessionStore.snapshot?.expiresAt,
      userProfile: PetPalSessionStore.snapshot?.userProfile
    });
  }

  static async setUserProfile(userProfile: UserProfile): Promise<void> {
    await PetPalSessionStore.setSession({
      accessToken: PetPalSessionStore.getAccessToken(),
      refreshToken: PetPalSessionStore.snapshot?.refreshToken,
      expiresAt: PetPalSessionStore.snapshot?.expiresAt,
      userProfile: userProfile
    });
  }

  static async clear(): Promise<void> {
    PetPalSessionStore.snapshot = null;
    if (PetPalSessionStore.pref) {
      try {
        await PetPalSessionStore.pref.clear();
        await PetPalSessionStore.pref.flush();
      } catch {
        return;
      }
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
    if (!PetPalSessionStore.pref) {
      return PetPalSessionStore.snapshot;
    }

    let raw: string = '';
    try {
      raw = PetPalSessionStore.pref.getSync(SESSION_STORAGE_KEY, '') as string;
    } catch {
      return null;
    }
    if (!raw) {
      return null;
    }

    try {
      const parsed = JSON.parse(raw) as PetPalSessionSnapshot;
      if (!parsed.accessToken) {
        return null;
      }
      return PetPalSessionStore.normalizeSnapshot(parsed);
    } catch {
      return null;
    }
  }

  private static async persistSnapshot(): Promise<void> {
    if (!PetPalSessionStore.pref) {
      return;
    }
    if (!PetPalSessionStore.snapshot || !PetPalSessionStore.snapshot.accessToken) {
      // 空 token 视为退出登录，清掉持久化数据，避免下次启动误判已登录。
      try {
        await PetPalSessionStore.pref.delete(SESSION_STORAGE_KEY);
        await PetPalSessionStore.pref.flush();
      } catch {
        return;
      }
      return;
    }

    try {
      await PetPalSessionStore.pref.put(SESSION_STORAGE_KEY, JSON.stringify(PetPalSessionStore.snapshot));
      await PetPalSessionStore.pref.flush();
    } catch {
      return;
    }
  }
}


