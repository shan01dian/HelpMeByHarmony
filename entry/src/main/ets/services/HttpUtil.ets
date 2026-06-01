import http from '@ohos.net.http'
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { AppConfig } from '../config/AppConfig'

// API 基础地址
const API_BASE: string = AppConfig.getBackendUrl()

// 请求参数类型
export type RequestParams = Record<string, string>

// 全局 HTTP 单例
let httpRequest: http.HttpRequest = http.createHttp()

// ==================== HTTP 请求封装 ====================

/**
 * 封装 GET 请求
 */
export async function httpGet<T>(path: string, params?: RequestParams): Promise<T> {
  let url = `${API_BASE}${path}`
  if (params) {
    const entries = Object.entries(params)
    const queryParts: string[] = []
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i]
      queryParts.push(`${encodeURIComponent(entry[0])}=${encodeURIComponent(entry[1])}`)
    }
    if (queryParts.length > 0) {
      url += '?' + queryParts.join('&')
    }
  }

  const token = await getToken()
  const header: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.GET,
    header: header,
    readTimeout: 15000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    return JSON.parse(response.result as string) as T
  } else if (response.responseCode === 401) {
    await clearToken()
    throw new Error('UNAUTHORIZED')
  } else {
    throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
  }
}

/**
 * 封装 POST 请求
 */
export async function httpPost<T>(path: string, body?: object): Promise<T> {
  const url = `${API_BASE}${path}`
  const token = await getToken()
  const header: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const extraData: string = body ? JSON.stringify(body) : ''

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.POST,
    header: header,
    extraData: extraData,
    readTimeout: 15000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    try {
      return JSON.parse(response.result as string) as T
    } catch {
      throw new Error(`服务器响应格式异常: ${response.result}`)
    }
  } else if (response.responseCode === 401) {
    await clearToken()
    throw new Error('UNAUTHORIZED')
  } else {
    let errMsg: string = `HTTP ${response.responseCode}`
    try {
      const errBody = JSON.parse(response.result as string) as Record<string, string>
      errMsg = errBody['error'] || errMsg
    } catch {
      errMsg = `服务器错误(${response.responseCode})`
    }
    throw new Error(errMsg)
  }
}

/**
 * 封装 PUT 请求
 */
export async function httpPut<T>(path: string, body?: object): Promise<T> {
  const url = `${API_BASE}${path}`
  const token = await getToken()
  const header: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const extraData: string = body ? JSON.stringify(body) : ''

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.PUT,
    header: header,
    extraData: extraData,
    readTimeout: 15000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    return JSON.parse(response.result as string) as T
  } else {
    const errBody = JSON.parse(response.result as string) as Record<string, string>
    throw new Error(errBody['error'] || `HTTP ${response.responseCode}`)
  }
}

/**
 * 封装 PATCH 请求
 */
export async function httpPatch<T>(path: string, body?: object): Promise<T> {
  const url = `${API_BASE}${path}`
  const token = await getToken()
  const header: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const extraData: string = body ? JSON.stringify(body) : ''

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.PUT,
    header: header,
    extraData: extraData,
    readTimeout: 15000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    return JSON.parse(response.result as string) as T
  } else {
    const errBody = JSON.parse(response.result as string) as Record<string, string>
    throw new Error(errBody['error'] || `HTTP ${response.responseCode}`)
  }
}

/**
 * 封装 DELETE 请求
 */
export async function httpDelete<T>(path: string): Promise<T> {
  const url = `${API_BASE}${path}`
  const token = await getToken()
  const header: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.DELETE,
    header: header,
    readTimeout: 15000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    return JSON.parse(response.result as string) as T
  } else {
    const errBody = JSON.parse(response.result as string) as Record<string, string>
    throw new Error(errBody['error'] || `HTTP ${response.responseCode}`)
  }
}

/**
 * 封装 multipart/form-data 文件上传
 * @param path 接口路径
 * @param fieldName 表单字段名
 * @param filePath 本地文件路径
 * @param fileName 文件名
 */
export async function httpUpload<T>(path: string, fieldName: string, filePath: string, fileName: string): Promise<T> {
  const url = `${API_BASE}${path}`
  const token = await getToken()
  const header: Record<string, string> = {}
  if (token) {
    header['Authorization'] = `Bearer ${token}`
  }

  const response = await httpRequest.request(url, {
    method: http.RequestMethod.POST,
    header: header,
    multiFormDataList: [
      {
        name: fieldName,
        filePath: filePath,
        remoteFileName: fileName,
        contentType: 'application/octet-stream'
      }
    ],
    readTimeout: 30000,
    connectTimeout: 15000
  })

  if (response.responseCode === 200) {
    return JSON.parse(response.result as string) as T
  } else if (response.responseCode === 401) {
    await clearToken()
    throw new Error('UNAUTHORIZED')
  } else {
    const errBody = JSON.parse(response.result as string) as Record<string, string>
    throw new Error(errBody['error'] || `HTTP ${response.responseCode}`)
  }
}

// ==================== Token 管理（使用 Preferences） ====================

const PREFERENCES_NAME = 'help_me_prefs'
const TOKEN_KEY = 'jwt_token'
const SESSION_KEY = 'user_session'

let prefStore: preferences.Preferences | null = null

async function getPreferences(): Promise<preferences.Preferences> {
  if (!prefStore) {
    const context = getContext() as common.UIAbilityContext
    prefStore = await preferences.getPreferences(context, PREFERENCES_NAME)
  }
  return prefStore as preferences.Preferences
}

/**
 * 获取 JWT Token
 */
export async function getToken(): Promise<string | null> {
  try {
    const store = await getPreferences()
    const token = await store.get(TOKEN_KEY, '') as string
    return token.length > 0 ? token : null
  } catch {
    return null
  }
}

/**
 * 设置 JWT Token
 */
export async function setToken(token: string): Promise<void> {
  const store = await getPreferences()
  await store.put(TOKEN_KEY, token)
  await store.flush()
}

/**
 * 清除 JWT Token
 */
export async function clearToken(): Promise<void> {
  const store = await getPreferences()
  await store.delete(TOKEN_KEY)
  await store.flush()
}

/**
 * 获取用户会话信息
 */
export async function getSession<T>(): Promise<T | null> {
  try {
    const store = await getPreferences()
    const json = await store.get(SESSION_KEY, '') as string
    if (json.length > 0) {
      return JSON.parse(json) as T
    }
    return null
  } catch {
    return null
  }
}

/**
 * 设置用户会话信息
 */
export async function setSession<T>(session: T): Promise<void> {
  const store = await getPreferences()
  await store.put(SESSION_KEY, JSON.stringify(session))
  await store.flush()
}

/**
 * 清除用户会话信息
 */
export async function clearSession(): Promise<void> {
  const store = await getPreferences()
  await store.delete(SESSION_KEY)
  await store.flush()
}

/**
 * 检查是否已登录
 */
export async function isLoggedIn(): Promise<boolean> {
  const token = await getToken()
  return token !== null
}

/**
 * 清除所有认证信息（退出登录时使用）
 */
export async function clearAuth(): Promise<void> {
  await clearToken()
  await clearSession()
}
