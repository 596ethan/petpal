import { AppointmentStatus, PetGender, PetSpecies, ProviderType } from '../models/PetPalModels';

export class PetPalTheme {
  static readonly background: string = '#FEFCF4';
  static readonly surface: string = '#F5F4EB';
  static readonly surfaceRaised: string = '#FFFFFF';
  static readonly surfaceWarm: string = '#F3E8DB';
  static readonly surfaceAccent: string = '#F6E0CE';
  static readonly overlay: string = '#FFF9F1';
  static readonly primary: string = '#A44A00';
  static readonly primaryStrong: string = '#7E3602';
  static readonly primarySoft: string = '#F7D8BF';
  static readonly primaryGlow: string = '#F9873E';
  static readonly accent: string = '#70857A';
  static readonly accentSoft: string = '#DDE6DE';
  static readonly tertiary: string = '#E4B74B';
  static readonly tertiarySoft: string = '#F7EDC9';
  static readonly text: string = '#383833';
  static readonly textMuted: string = '#706859';
  static readonly textSubtle: string = '#A19684';
  static readonly success: string = '#6F8A68';
  static readonly successSoft: string = '#E4EEE0';
  static readonly warning: string = '#B68035';
  static readonly warningSoft: string = '#F8E8C8';
  static readonly danger: string = '#A35E4E';
  static readonly dangerSoft: string = '#F1DDD5';
  static readonly radiusHero: number = 32;
  static readonly radiusPanel: number = 28;
  static readonly radiusCard: number = 24;
  static readonly radiusChip: number = 999;
  static readonly radiusImage: number = 18;
  static readonly pagePadding: number = 18;
}

export function statusText(status: AppointmentStatus): string {
  switch (status) {
    case AppointmentStatus.CONFIRMED:
      return '已确认';
    case AppointmentStatus.PENDING_CONFIRM:
      return '待确认';
    case AppointmentStatus.COMPLETED:
      return '已完成';
    case AppointmentStatus.CANCELLED:
      return '已取消';
    default:
      return '已过期';
  }
}

export function statusTone(status: AppointmentStatus): string {
  switch (status) {
    case AppointmentStatus.CONFIRMED:
      return PetPalTheme.primary;
    case AppointmentStatus.PENDING_CONFIRM:
      return PetPalTheme.warning;
    case AppointmentStatus.COMPLETED:
      return PetPalTheme.success;
    case AppointmentStatus.CANCELLED:
      return PetPalTheme.danger;
    default:
      return PetPalTheme.textMuted;
  }
}

export function statusSurface(status: AppointmentStatus): string {
  switch (status) {
    case AppointmentStatus.CONFIRMED:
      return PetPalTheme.primarySoft;
    case AppointmentStatus.PENDING_CONFIRM:
      return PetPalTheme.warningSoft;
    case AppointmentStatus.COMPLETED:
      return PetPalTheme.successSoft;
    case AppointmentStatus.CANCELLED:
      return PetPalTheme.dangerSoft;
    default:
      return PetPalTheme.surfaceWarm;
  }
}

export function speciesText(species: PetSpecies): string {
  switch (species) {
    case PetSpecies.DOG:
      return '狗狗';
    case PetSpecies.CAT:
      return '猫咪';
    case PetSpecies.RABBIT:
      return '兔兔';
    case PetSpecies.BIRD:
      return '鸟类';
    default:
      return '其他';
  }
}

export function genderText(gender: PetGender): string {
  switch (gender) {
    case PetGender.MALE:
      return '公';
    case PetGender.FEMALE:
      return '母';
    default:
      return '未知';
  }
}

export function providerTypeText(type: ProviderType): string {
  switch (type) {
    case ProviderType.HOSPITAL:
      return '医疗';
    case ProviderType.GROOMING:
      return '美容';
    default:
      return '寄养';
  }
}

export function providerTone(type: ProviderType): string {
  switch (type) {
    case ProviderType.HOSPITAL:
      return PetPalTheme.primary;
    case ProviderType.GROOMING:
      return PetPalTheme.accent;
    default:
      return PetPalTheme.tertiary;
  }
}

export function providerSurface(type: ProviderType): string {
  switch (type) {
    case ProviderType.HOSPITAL:
      return PetPalTheme.primarySoft;
    case ProviderType.GROOMING:
      return PetPalTheme.accentSoft;
    default:
      return PetPalTheme.tertiarySoft;
  }
}

export function petAvatarLabel(name: string): string {
  return name.length > 0 ? name.substring(0, 1) : '宠';
}
