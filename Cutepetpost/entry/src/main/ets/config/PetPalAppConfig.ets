// 外网环境临时地址，保留备查；需要外用时手动切回。
// export const PETPAL_DEV_SERVER_ORIGIN: string = 'http://172.16.174.161:18080';
export const PETPAL_DEV_SERVER_ORIGIN: string = 'http://192.168.1.3:18080';
export const PETPAL_PROD_SERVER_ORIGIN: string = 'https://api.petpal.example.com';

// 真机联调时，如需切换网络环境，把 PETPAL_DEV_SERVER_ORIGIN 改成当前后端机器的可访问地址。
export const PETPAL_SERVER_ORIGIN: string = PETPAL_DEV_SERVER_ORIGIN;
export const PETPAL_API_BASE_URL: string = `${PETPAL_SERVER_ORIGIN}/api`;
