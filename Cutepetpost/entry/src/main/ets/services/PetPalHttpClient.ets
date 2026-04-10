import http from '@ohos.net.http';
import util from '@ohos.util';
import { PetPalSessionStore } from './PetPalSessionStore';

export type PetPalHttpMethod = 'GET' | 'POST' | 'PUT';

export interface PetPalHttpRequestOptions {
  auth?: boolean;
  headers?: Record<string, string>;
  query?: Record<string, string | number | boolean | undefined | null>;
  body?: string | Record<string, unknown> | ArrayBuffer | null;
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
  private readonly decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });

  constructor(baseUrl: string, timeoutMs: number = 15000) {
    this.baseUrl = this.normalizeBaseUrl(baseUrl);
    this.timeoutMs = timeoutMs;
  }

  async get<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>('GET', path, options);
  }

  async post<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>('POST', path, options);
  }

  async put<T>(path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    return this.request<T>('PUT', path, options);
  }

  async request<T>(method: PetPalHttpMethod, path: string, options: PetPalHttpRequestOptions = {}): Promise<PetPalHttpResponse<T>> {
    const request = http.createHttp();
    const url = this.buildUrl(path, options.query);
    const requestHeaders = this.buildHeaders(options.auth === true, options.headers);
    const requestOptions: http.HttpRequestOptions = {
      method: this.toRequestMethod(method),
      header: requestHeaders,
      connectTimeout: options.timeoutMs ?? this.timeoutMs,
      readTimeout: options.timeoutMs ?? this.timeoutMs,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false
    };

    if (options.body !== undefined && options.body !== null) {
      requestOptions.extraData = this.serializeBody(options.body) as string | Object | ArrayBuffer;
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
    for (const key in query) {
      const value = query[key];
      if (value === undefined || value === null) {
        continue;
      }
      pairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
    }

    return pairs.length > 0 ? `?${pairs.join('&')}` : '';
  }

  private buildHeaders(includeAuth: boolean, headers?: Record<string, string>): Record<string, string> {
    const merged: Record<string, string> = {
      Accept: 'application/json',
      'Content-Type': 'application/json'
    };

    if (includeAuth) {
      Object.assign(merged, PetPalSessionStore.getAuthHeaders());
    }

    if (headers) {
      Object.assign(merged, headers);
    }

    return merged;
  }

  private serializeBody(body: string | Record<string, unknown> | ArrayBuffer): string | Record<string, unknown> | ArrayBuffer {
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
    const source = headers as Record<string, unknown>;
    for (const key in source) {
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
    if (method === 'POST') {
      return http.RequestMethod.POST;
    }
    if (method === 'PUT') {
      return http.RequestMethod.PUT;
    }
    return http.RequestMethod.GET;
  }
}
