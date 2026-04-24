export const PETPAL_DEV_SERVER_ORIGIN: string = 'http://192.168.1.3:18080';
export const PETPAL_PROD_SERVER_ORIGIN: string = 'https://api.petpal.example.com';

// For real-device development, replace PETPAL_DEV_SERVER_ORIGIN with the backend machine's LAN IP.
export const PETPAL_SERVER_ORIGIN: string = PETPAL_DEV_SERVER_ORIGIN;
export const PETPAL_API_BASE_URL: string = `${PETPAL_SERVER_ORIGIN}/api`;
