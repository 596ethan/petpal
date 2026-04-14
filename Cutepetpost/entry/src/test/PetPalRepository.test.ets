import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import http from '@ohos.net.http';
import {
  AppointmentStatus,
  HealthRecordCreateInput,
  PetCreateInput,
  PetGender,
  PetSpecies,
  PetUpdateInput,
  UserProfile,
  VaccineRecordCreateInput
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

interface TestPetPayload {
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

interface TestHealthRecordPayload {
  id: number;
  recordType: string;
  title: string;
  description: string;
  recordDate: string;
  nextDate: string;
}

interface TestVaccineRecordPayload {
  id: number;
  vaccineName: string;
  vaccinatedAt: string;
  nextDueAt: string;
  hospital: string;
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


function petPayload(): TestPetPayload {
  return {
    id: 3,
    name: 'Mittens',
    species: 'CAT',
    breed: 'British Shorthair',
    gender: 'FEMALE',
    birthday: '2023-01-02',
    weight: 4.2,
    avatarUrl: 'https://example.com/pet.png',
    neutered: true
  };
}

function healthRecordPayload(id: number = 7, description: string = 'Annual checkup'): TestHealthRecordPayload {
  return {
    id: id,
    recordType: 'CHECKUP',
    title: 'Annual checkup',
    description: description,
    recordDate: '2026-02-18',
    nextDate: '2027-02-18'
  };
}

function vaccineRecordPayload(id: number = 8): TestVaccineRecordPayload {
  return {
    id: id,
    vaccineName: 'Feline triple vaccine',
    vaccinatedAt: '2025-04-18',
    nextDueAt: '2026-04-11',
    hospital: 'Cloud Vet Center'
  };
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

    it("create pet maps success response", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.path).assertEqual("/pet");
        expect(request.method).assertEqual(http.RequestMethod.POST);
        expect(request.authRequired).assertTrue();
        expect(request.headers.Authorization).assertEqual("Bearer access-token");
        const body = request.body as PetCreateInput;
        expect(body.name).assertEqual("Mittens");
        expect(body.species).assertEqual(PetSpecies.CAT);
        expect(body.gender).assertEqual(PetGender.FEMALE);
        return {
          responseCode: 200,
          result: okEnvelope<TestPetPayload>(petPayload())
        };
      });

      const created = await PetPalRepository.createPet({
        name: "Mittens",
        species: PetSpecies.CAT,
        breed: "British Shorthair",
        gender: PetGender.FEMALE,
        birthday: "2023-01-02",
        weight: 4.2,
        avatarUrl: "https://example.com/pet.png",
        neutered: true
      });

      expect(created.id).assertEqual(3);
      expect(created.name).assertEqual("Mittens");
      expect(created.weight).assertEqual("4.2");
      expect(created.neutered).assertTrue();
    });

    it("update pet sends partial body and maps response", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.path).assertEqual("/pet/3");
        expect(request.method).assertEqual(http.RequestMethod.PUT);
        expect(request.authRequired).assertTrue();
        const body = request.body as PetUpdateInput;
        expect(body.name).assertEqual("Mittens Jr.");
        expect(body.neutered).assertFalse();
        expect(body.birthday === undefined).assertTrue();
        expect(body.weight === undefined).assertTrue();
        return {
          responseCode: 200,
          result: okEnvelope<TestPetPayload>({
            id: 3,
            name: "Mittens Jr.",
            species: "CAT",
            breed: "British Shorthair",
            gender: "FEMALE",
            birthday: "2023-01-02",
            weight: 4.2,
            avatarUrl: "https://example.com/pet.png",
            neutered: false
          })
        };
      });

      const updated = await PetPalRepository.updatePet(3, {
        name: "Mittens Jr.",
        neutered: false
      });

      expect(updated.name).assertEqual("Mittens Jr.");
      expect(updated.neutered).assertFalse();
    });

    it("delete pet issues soft-delete request", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.path).assertEqual("/pet/3");
        expect(request.method).assertEqual(http.RequestMethod.DELETE);
        expect(request.authRequired).assertTrue();
        expect(request.headers.Authorization).assertEqual("Bearer access-token");
        return {
          responseCode: 200,
          result: okEnvelope<null>(null)
        };
      });

      await PetPalRepository.deletePet(3);
    });

    it("health record write and read map success", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      let callCount = 0;
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.authRequired).assertTrue();
        expect(request.headers.Authorization).assertEqual("Bearer access-token");
        if (request.method === http.RequestMethod.POST) {
          expect(request.path).assertEqual("/pet/3/health");
          const body = request.body as HealthRecordCreateInput;
          expect(body.recordType).assertEqual("CHECKUP");
          expect(body.title).assertEqual("Annual checkup");
          return {
            responseCode: 200,
            result: okEnvelope<TestHealthRecordPayload>({
              id: 9,
              recordType: "CHECKUP",
              title: "Annual checkup",
              description: "Bloodwork normal",
              recordDate: "2026-02-18",
              nextDate: "2027-02-18"
            })
          };
        }
        callCount += 1;
        expect(request.path).assertEqual("/pet/3/health");
        return {
          responseCode: 200,
          result: okEnvelope<TestHealthRecordPayload[]>([
            {
              id: 10,
              recordType: "MEDICATION",
              title: "Deworming",
              description: null as unknown as string,
              recordDate: "2026-03-01",
              nextDate: null as unknown as string
            }
          ])
        };
      });

      const created = await PetPalRepository.addHealthRecord(3, {
        recordType: "CHECKUP",
        title: "Annual checkup",
        description: "Bloodwork normal",
        recordDate: "2026-02-18",
        nextDate: "2027-02-18"
      });
      const list = await PetPalRepository.getHealthRecordsAsync(3);

      expect(created.title).assertEqual("Annual checkup");
      expect(created.nextDate).assertEqual("2027-02-18");
      expect(list.length).assertEqual(1);
      expect(list[0].summary).assertEqual("");
      expect(list[0].nextDate).assertEqual("");
      expect(callCount).assertEqual(1);
    });

    it("vaccine record write and alias read map success", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      let callCount = 0;
      PetPalRepository.setRequestHandlerForTest(async (request: PetPalRepositoryRequest): Promise<PetPalRepositoryResponse> => {
        expect(request.authRequired).assertTrue();
        expect(request.headers.Authorization).assertEqual("Bearer access-token");
        if (request.method === http.RequestMethod.POST) {
          expect(request.path).assertEqual("/pet/3/vaccine");
          const body = request.body as VaccineRecordCreateInput;
          expect(body.vaccineName).assertEqual("Rabies");
          return {
            responseCode: 200,
            result: okEnvelope<TestVaccineRecordPayload>({
              id: 11,
              vaccineName: "Rabies",
              vaccinatedAt: "2025-07-01",
              nextDueAt: "2026-06-24",
              hospital: "Cloud Vet Center"
            })
          };
        }
        callCount += 1;
        expect(request.path).assertEqual("/pet/3/vaccine");
        return {
          responseCode: 200,
          result: okEnvelope<TestVaccineRecordPayload[]>([
            {
              id: 12,
              vaccineName: "Feline triple vaccine",
              vaccinatedAt: "2025-04-18",
              nextDueAt: null as unknown as string,
              hospital: null as unknown as string
            }
          ])
        };
      });

      const created = await PetPalRepository.addVaccineRecord(3, {
        vaccineName: "Rabies",
        vaccinatedAt: "2025-07-01",
        nextDueAt: "2026-06-24",
        hospital: "Cloud Vet Center"
      });
      const list = await PetPalRepository.getVaccineRecords(3);
      const aliasList = await PetPalRepository.getVaccinesAsync(3);

      expect(created.vaccineName).assertEqual("Rabies");
      expect(created.hospital).assertEqual("Cloud Vet Center");
      expect(list.length).assertEqual(1);
      expect(list[0].nextDueAt).assertEqual("");
      expect(aliasList.length).assertEqual(1);
      expect(callCount).assertEqual(2);
    });

    it("create pet surfaces backend errors", 0, async () => {
      PetPalRepository.storeSession({
        accessToken: "access-token",
        refreshToken: "refresh-token",
        profile: profilePayload() as UserProfile
      });
      PetPalRepository.setRequestHandlerForTest(async (): Promise<PetPalRepositoryResponse> => {
        return {
          responseCode: 400,
          result: errorEnvelope("INVALID_PET_FIELD", "Pet name is required")
        };
      });

      await expectRejectsMessage(() => PetPalRepository.createPet({
        name: "",
        species: PetSpecies.CAT,
        gender: PetGender.FEMALE
      }), "Pet name is required");
    });

  });
}
