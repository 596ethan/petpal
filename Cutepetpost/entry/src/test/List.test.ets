import localUnitTest from './LocalUnit.test';
import petPalRepositoryTest from './PetPalRepository.test';

export default function testsuite() {
  localUnitTest();
  petPalRepositoryTest();
}
