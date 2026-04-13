import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import {
  AppointmentStatus,
  UserProfile
} from '../main/ets/models/PetPalModels';
import {
  AppointmentCreateInput,
  PetPalRepository,
  PetPalRepositoryRequest,
  PetPalRepositoryResponse
} from '../main/ets/repository/PetPalRepository';

interface TestEnvelope<T> {
  code: string;
  message: string;
  data: T | null;
}

interface TestUserProfilePayload {
  id: number;
  phone: string;
  nickname: string;
  avatarUrl: string;
  bio: string;
  followingCount: number;
  followerCount: number;
}

interface TestTokenPayload {
  accessToken: string;
  refreshToken: string;
}

interface TestLoginPayload {
  profile: TestUserProfilePayload;
  tokens: TestTokenPayload;
}

interface TestAppointmentPayload {
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

function okEnvelope<T>(data: T): string {
  const envelope: TestEnvelope<T> = {
    code: 'OK',
    message: 'OK',
    data: data
  };
  return JSON.stringify(envelope);
}

function errorEnvelope(code: string, message: string): string {
  const envelope: TestEnvelope<null> = {
    code: code,
    message: message,
    data: null
  };
  return JSON.stringify(envelope);
}

function profilePayload(): TestUserProfilePayload {
  const payload: TestUserProfilePayload = {
    id: 1,
    phone: '13800000001',
    nickname: 'Xiaoman',
    avatarUrl: 'https://example.com/avatar.png',
    bio: 'PetPal tester',
    followingCount: 2,
    followerCount: 3
  };
  return payload;
}

function appointmentPayload(status: string = 'PENDING_CONFIRM'): TestAppointmentPayload {
  const payload: TestAppointmentPayload = {
    id: 2,
    orderNo: 'PP209901020001',
    userId: 1,
    petId: 1,
    petName: 'Nuomi',
    providerId: 1,
    providerName: 'Cloud Vet Center',
    serviceId: 1,
    serviceName: 'Wellness Check',
    status: status,
    appointmentTime: '2099-01-02T10:00:00',
    remark: 'Check appetite'
  };
  return payload;
}

async function expectRejectsMessage(action: () => Promise<Object>, expected: string): Promise<void> {
  let message = '';
  try {
    await action();
  } catch (error) {
    message = error instanceof Error ? error.message : String(error);
  }
  expect(message).assertContain(expected);
}

export default function petPalRepositoryTest() {
  describe('PetPalRepository', () => {
    beforeEach(() => {
      PetPalRepository.resetForTest();
    });

    afterEach(() => {
      PetPalRepository.resetForTest();
    });

    it('login stores tokens on success', 0, async () => {
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.path).assertEqual('/user/login');
        expect(request.authRequired).assertFalse();
        const tokens: TestTokenPayload = {
          accessToken: 'access-token',
          refreshToken: 'refresh-token'
        };
        const loginPayload: TestLoginPayload = {
          profile: profilePayload(),
          tokens: tokens
        };
        return {
          responseCode: 200,
          result: okEnvelope<TestLoginPayload>(loginPayload)
        };
      });

      const session = await PetPalRepository.login('13800000001', '123456');

      expect(session.accessToken).assertEqual('access-token');
      expect(PetPalRepository.getSession()?.accessToken).assertEqual('access-token');
      expect(PetPalRepository.getSession()?.refreshToken).assertEqual('refresh-token');
    });

    it('login reports failure without storing tokens', 0, async () => {
      PetPalRepository.setRequestHandlerForTest(async (): Promise<PetPalRepositoryResponse> => {
        return {
          responseCode: 401,
          result: errorEnvelope('INVALID_CREDENTIALS', 'Invalid phone or password')
        };
      });

      await expectRejectsMessage(() => PetPalRepository.login('13800000001', 'bad-password'), 'Invalid phone or password');

      expect(PetPalRepository.getSession()).assertNull();
    });

    it('create appointment maps success response', 0, async () => {
      const profile = profilePayload() as UserProfile;
      PetPalRepository.storeSession({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        profile: profile
      });
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.path).assertEqual('/appointment');
        expect(request.headers.Authorization).assertEqual('Bearer access-token');
        const body = request.body as AppointmentCreateInput;
        expect(body.appointmentTime).assertEqual('2099-01-02T10:00:00');
        return {
          responseCode: 200,
          result: okEnvelope(appointmentPayload())
        };
      });

      const appointment = await PetPalRepository.createAppointment({
        petId: 1,
        providerId: 1,
        serviceId: 1,
        appointmentTime: '2099-01-02T10:00:00',
        remark: 'Check appetite'
      });

      expect(appointment.orderNo).assertEqual('PP209901020001');
      expect(appointment.status).assertEqual(AppointmentStatus.PENDING_CONFIRM);
    });

    it('create appointment reports backend failure', 0, async () => {
      PetPalRepository.storeSession({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (): Promise<PetPalRepositoryResponse> => {
        return {
          responseCode: 400,
          result: errorEnvelope('APPOINTMENT_TIME_IN_PAST', 'Appointment time must be in the future')
        };
      });

      await expectRejectsMessage(() => PetPalRepository.createAppointment({
        petId: 1,
        providerId: 1,
        serviceId: 1,
        appointmentTime: '2026-01-01T10:00:00',
        remark: ''
      }), 'Appointment time must be in the future');
    });

    it('appointment list reports failure state', 0, async () => {
      PetPalRepository.storeSession({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (): Promise<PetPalRepositoryResponse> => {
        return {
          responseCode: 500,
          result: errorEnvelope('SERVER_ERROR', 'Appointment list unavailable')
        };
      });

      await expectRejectsMessage(() => PetPalRepository.getAppointmentsAsync(), 'Appointment list unavailable');
    });

    it('authenticated 401 clears session for login required state', 0, async () => {
      PetPalRepository.storeSession({
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (): Promise<PetPalRepositoryResponse> => {
        return {
          responseCode: 401,
          result: errorEnvelope('UNAUTHORIZED', 'Login required')
        };
      });

      await expectRejectsMessage(() => PetPalRepository.getAppointmentsAsync(), 'Login required');

      expect(PetPalRepository.getSession()).assertNull();
    });
  });
}
