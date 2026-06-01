import { httpPost, setToken, setSession, clearToken, clearSession, getSession, getToken } from './HttpUtil'

// 用户会话接口
export interface Session {
  id: number
  name: string
  role: string
}

// 登录响应接口
export interface LoginResponse {
  token: string
  user: Session
}

// 注册请求接口
export interface RegisterRequest {
  phone: string
  code: string
  userName: string
  realName: string
  idCardNumber: string
  birthDate: string
  avatar: string
  introduction?: string
}

// 布尔结果接口
export interface BoolResult {
  registered: boolean
}

// 验证码校验结果接口
export interface VerifyCodeResult {
  codeValid: boolean
  registered: boolean
}

/**
 * 发送短信验证码
 */
export async function sendCode(phone: string, captchaToken: string): Promise<void> {
  const body: Record<string, string> = { 'phone': phone, 'captchaToken': captchaToken }
  await httpPost<Record<string, string>>('/send-code', body)
}

/**
 * 校验验证码
 */
export async function verifyCode(phone: string, code: string): Promise<boolean> {
  const body: Record<string, string> = { 'phone': phone, 'code': code }
  const res = await httpPost<VerifyCodeResult>('/verify-code', body)
  return res.codeValid
}

/**
 * 检查手机号是否已注册
 */
export async function checkPhone(phone: string): Promise<boolean> {
  const body: Record<string, string> = { 'phone': phone }
  const res = await httpPost<BoolResult>('/check-phone', body)
  return res.registered
}

/**
 * 用户登录
 */
export async function login(phone: string, code: string): Promise<LoginResponse> {
  const body: Record<string, string> = { 'phone': phone, 'code': code }
  const res = await httpPost<LoginResponse>('/login', body)
  await setToken(res.token)
  await setSession(res.user)
  return res
}

/**
 * 用户注册
 */
export async function register(formData: RegisterRequest): Promise<LoginResponse> {
  const res = await httpPost<LoginResponse>('/register', formData)
  await setToken(res.token)
  await setSession(res.user)
  return res
}

/**
 * 获取当前会话
 */
export async function getCurrentSession(): Promise<Session | null> {
  return await getSession<Session>()
}

/**
 * 检查是否已登录
 */
export async function isLoggedIn(): Promise<boolean> {
  const token = await getToken()
  return token !== null
}

/**
 * 退出登录
 */
export async function logout(): Promise<void> {
  await clearToken()
  await clearSession()
}
