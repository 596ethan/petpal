import http from '@ohos.net.http';
import util from '@ohos.util';
import { PetPalSessionStore } from './PetPalSessionStore';

export enum PetPalHttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT'
}

export interface PetPalHttpRequestOptions {
  auth?: boolean;
  headers?: Record<string, string>;
  query?: Record<string, string | number | boolean | undefined | null>;
  body?: string | Object | ArrayBuffer | null;
  timeoutMs?: number;
}

export interface PetPalHttpResponse<T> {
  statusCode: number;
  headers: Record<string, string>;
  rawBody: string;
  data: T;
}

export class PetPalHttpError extends Error {
  statusCode: number;
  rawBody: string;

  constructor(message: string, statusCode: number, rawBody: string) {
    super(message);
    this.name = 'PetPalHttpError';
    this.statusCode = statusCode;
    this.rawBody = rawBody;
  }
}

export class PetPalHttpClient {
  private readonly baseUrl: string;
  private readonly timeoutMs: number;
  private readonly decoder = util.TextDecoder.create('utf-8');

  constructor(baseUrl: string, timeoutMs: number = 15000) {
    this.baseUrl = this.normalizeBaseUrl(baseUrl);
    this.timeoutMs = timeoutMs;
  }

  async get<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>(PetPalHttpMethod.GET, path, options);
  }

  async post<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>(PetPalHttpMethod.POST, path, options);
  }

  async put<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>(PetPalHttpMethod.PUT, path, options);
  }

  async request<T>(method: PetPalHttpMethod, path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    const request = http.createHttp();
    const url = this.buildUrl(path, options.query);
    const requestHeaders = this.buildHeaders(options.auth !== false, options.headers);
    const requestOptions: http.HttpRequestOptions = {
      method: this.toRequestMethod(method),
      header: requestHeaders,
      connectTimeout: options.timeoutMs ?? this.timeoutMs,
      readTimeout: options.timeoutMs ?? this.timeoutMs,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false
    };

    if (options.body !== undefined && options.body !== null) {
      requestOptions.extraData = this.serializeBody(options.body);
    }

    try {
      const response = await request.request(url, requestOptions);
      const rawBody = this.readBody(response.result);
      const headers = this.normalizeHeaders(response.header);
      const statusCode = Number(response.responseCode);

      if (statusCode < 200 || statusCode >= 300) {
        throw new PetPalHttpError(`HTTP ${statusCode} for ${method} ${path}`, statusCode, rawBody);
      }

      return {
        statusCode: statusCode,
        headers: headers,
        rawBody: rawBody,
        data: this.parseBody<T>(rawBody)
      };
    } catch (error) {
      if (error instanceof PetPalHttpError) {
        throw error;
      }
      const message = error instanceof Error ? error.message : 'Request failed';
      throw new PetPalHttpError(message, 0, '');
    } finally {
      request.destroy();
    }
  }

  private normalizeBaseUrl(baseUrl: string): string {
    return baseUrl.replace(/\/+$/, '');
  }

  private buildUrl(path: string, query?: Record<string, string | number | boolean | undefined | null>): string {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    const queryString = this.buildQueryString(query);
    return `${this.baseUrl}${normalizedPath}${queryString}`;
  }

  private buildQueryString(query?: Record<string, string | number | boolean | undefined | null>): string {
    if (!query) {
      return '';
    }

    const pairs: string[] = [];
    const keys = Object.keys(query);
    for (let index = 0; index < keys.length; index++) {
      const key = keys[index];
      const value = query[key];
      if (value === undefined || value === null) {
        continue;
      }
      pairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
    }

    return pairs.length > 0 ? `?${pairs.join('&')}` : '';
  }

  private buildHeaders(includeAuth: boolean, headers?: Record<string, string>): Record<string, string> {
    const merged: Record<string, string> = {};
    merged['Accept'] = 'application/json';
    merged['Content-Type'] = 'application/json';

    if (includeAuth) {
      const authHeaders = PetPalSessionStore.getAuthHeaders();
      const authKeys = Object.keys(authHeaders);
      for (let index = 0; index < authKeys.length; index++) {
        const key = authKeys[index];
        merged[key] = authHeaders[key];
      }
    }

    if (headers) {
      const headerKeys = Object.keys(headers);
      for (let index = 0; index < headerKeys.length; index++) {
        const key = headerKeys[index];
        merged[key] = headers[key];
      }
    }

    return merged;
  }

  private serializeBody(body: string | Object | ArrayBuffer): string | Object | ArrayBuffer {
    if (typeof body === 'string' || body instanceof ArrayBuffer) {
      return body;
    }
    return JSON.stringify(body);
  }

  private readBody(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      return this.decoder.decode(new Uint8Array(result));
    }
    return JSON.stringify(result);
  }

  private parseBody<T>(rawBody: string): T {
    if (!rawBody) {
      return undefined as T;
    }

    try {
      return JSON.parse(rawBody) as T;
    } catch {
      return rawBody as T;
    }
  }

  private normalizeHeaders(headers: Object): Record<string, string> {
    const normalized: Record<string, string> = {};
    const source = headers as Record<string, string | string[] | number | boolean | null | undefined>;
    const keys = Object.keys(source);
    for (let index = 0; index < keys.length; index++) {
      const key = keys[index];
      const value = source[key];
      if (Array.isArray(value)) {
        normalized[key] = value.map((item) => String(item)).join(', ');
      } else if (value !== undefined && value !== null) {
        normalized[key] = String(value);
      }
    }
    return normalized;
  }

  private toRequestMethod(method: PetPalHttpMethod): http.RequestMethod {
    if (method === PetPalHttpMethod.POST) {
      return http.RequestMethod.POST;
    }
    if (method === PetPalHttpMethod.PUT) {
      return http.RequestMethod.PUT;
    }
    return http.RequestMethod.GET;
  }
}
