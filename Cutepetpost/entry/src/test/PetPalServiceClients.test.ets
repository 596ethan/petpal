import { describe, it, expect } from '@ohos/hypium';
import { PetPalApiClient } from '../main/ets/services/PetPalApiClient';
import { PetPalHttpClient, PetPalHttpMethod } from '../main/ets/services/PetPalHttpClient';

export default function petPalServiceClientsTest() {
  describe('PetPalServiceClients', () => {
    it('configures api client and exposes typed http methods', 0, () => {
      PetPalApiClient.configure({
        baseUrl: 'http://127.0.0.1:18080/api',
        timeoutMs: 1000
      });

      const client = new PetPalHttpClient('http://127.0.0.1:18080/api', 1000);

      expect(client !== null).assertTrue();
      expect(PetPalHttpMethod.GET).assertEqual('GET');
      expect(PetPalHttpMethod.POST).assertEqual('POST');
      expect(PetPalHttpMethod.PUT).assertEqual('PUT');
    });
  });
}
