// 应用配置管理器
export class AppConfig {
  // 后端服务器地址配置
  private static backendUrl: string = 'http://192.168.3.115:3000'

  // 获取后端服务器地址
  static getBackendUrl(): string {
    return AppConfig.backendUrl
  }

  // 设置后端服务器地址
  static setBackendUrl(url: string): void {
    AppConfig.backendUrl = url
    console.log(`[AppConfig] 设置后端地址为: ${url}`)
  }

  // 获取API完整路径
  static getApiUrl(path: string): string {
    const baseUrl = AppConfig.backendUrl.replace(/\/$/, '') // 移除末尾斜杠
    const apiPath = path.startsWith('/') ? path : `/${path}`
    return `${baseUrl}${apiPath}`
  }
}