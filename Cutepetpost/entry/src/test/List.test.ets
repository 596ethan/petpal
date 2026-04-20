import localUnitTest from './LocalUnit.test';
import petPalRepositoryTest from './PetPalRepository.test';
import petPalServiceClientsTest from './PetPalServiceClients.test';

export default function testsuite() {
  localUnitTest();
  petPalRepositoryTest();
  petPalServiceClientsTest();
}
