import http from '@ohos.net.http'
import { EventCardData, SearchResponse } from '../model/EventModel'
import { AppConfig } from '../config/AppConfig'

// 后端事件详情接口
export interface BackendEventDetail {
  EventId: number
  CreatorId: number
  EventTitle: string
  EventType: number
  EventCategory: string
  Photos: string
  Location: string
  Price: number
  EventDetails: string
  CreateTime: string
}

// 后端事件详情响应接口
export interface BackendEventResponse {
  success: boolean
  event: BackendEventDetail
}

// 后端卡片列表响应接口
export interface BackendCardsResponse {
  value?: SearchResponse[]
  Count?: number
}

export class HttpService {
  // 使用配置管理器获取后端服务器地址
  private baseUrl: string = AppConfig.getBackendUrl()
  private httpRequest: http.HttpRequest | null = null

  constructor(baseUrl?: string) {
    if (baseUrl) {
      this.baseUrl = baseUrl
      console.log(`[HttpService] 使用自定义后端地址: ${this.baseUrl}`)
    }
  }

  // 搜索事件 - 使用真实的 /api/cards 接口
  async searchEvents(keyword: string, type?: string): Promise<EventCardData[]> {
    console.log(`[HttpService] 开始搜索: keyword="${keyword}", type="${type}"`)
    console.log(`[HttpService] 当前后端地址: ${this.baseUrl}`)
    
    // 直接使用真实后端接口
    try {
      const realData = await this.searchRealBackend(keyword, type)
      console.log(`[HttpService] 从真实后端获取到 ${realData.length} 条数据`)
      return realData
    } catch (error) {
      console.error(`[HttpService] 后端请求失败:`, error)
      // 请求失败时返回空数组
      return []
    }
  }

  // 从真实后端搜索 - 使用 /api/cards 接口
  private async searchRealBackend(keyword: string, type?: string): Promise<EventCardData[]> {
    // 如果没有关键词，获取所有卡片
    let url = AppConfig.getApiUrl('/api/cards')
    let params: string[] = []
    
    if (keyword && keyword.trim() !== '') {
      params.push(`search=${encodeURIComponent(keyword.trim())}`)
    }
    if (type && type.trim() !== '') {
      params.push(`type=${type.trim()}`)
    }
    
    if (params.length > 0) {
      url += '?' + params.join('&')
    } else {
      // 如果没有搜索条件，获取所有卡片
      url += '?search='
    }

    console.log(`[HttpService] 请求后端URL: ${url}`)

    this.httpRequest = http.createHttp()
    
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 8000, // 8秒超时
        readTimeout: 8000
      })
      
      console.log(`[HttpService] 后端响应状态码: ${response.responseCode}`)
      
      if (response.responseCode === 200) {
        console.log(`[HttpService] 后端原始响应数据: ${response.result}`)
        const rawData: BackendCardsResponse | SearchResponse[] = JSON.parse(response.result as string)
        console.log(`[HttpService] 解析后的结果结构:`, rawData)
        
        // 后端返回的数据结构是数组，而不是{value: [...]}
        let data: SearchResponse[] = []
        if (Array.isArray(rawData)) {
          // 直接是数组
          data = rawData as SearchResponse[]
        } else if (rawData.value && Array.isArray(rawData.value)) {
          // 包含value字段的对象
          data = rawData.value as SearchResponse[]
        }
        
        console.log(`[HttpService] 从后端解析到 ${data.length} 条记录`)
        return this.transformData(data)
      } else {
        throw new Error(`HTTP ${response.responseCode}`)
      }
    } finally {
      if (this.httpRequest) {
        this.httpRequest.destroy()
        this.httpRequest = null
      }
    }
  }

  // 获取事件详情 - 使用 /events/:id 接口
  async getEventDetail(eventId: string): Promise<EventCardData | null> {
    console.log(`[HttpService] 获取事件详情: ${eventId}`)
    
    try {
      const realData = await this.getRealEventDetail(eventId)
      if (realData) {
        console.log(`[HttpService] 从后端获取到事件详情`)
        return realData
      }
    } catch (error) {
      console.error(`[HttpService] 后端获取详情失败:`, error)
    }
    
    return null
  }

  // 从真实后端获取事件详情
  private async getRealEventDetail(eventId: string): Promise<EventCardData | null> {
    const url = `${this.baseUrl}/events/${eventId}`
    console.log(`[HttpService] 请求后端详情URL: ${url}`)

    this.httpRequest = http.createHttp()
    
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 5000,
        readTimeout: 5000
      })
      
      if (response.responseCode === 200) {
        const result: BackendEventResponse = JSON.parse(response.result as string)
        if (result.success && result.event) {
          const eventData: BackendEventDetail = result.event
          // 将后端返回的事件数据转换为前端需要的格式
          const transformedData = this.transformEventToCardData(eventData)
          return transformedData
        }
      } else {
        throw new Error(`HTTP ${response.responseCode}`)
      }
    } finally {
      if (this.httpRequest) {
        this.httpRequest.destroy()
        this.httpRequest = null
      }
    }
    return null
  }

  private transformData(data: SearchResponse[]): EventCardData[] {
    return data.map((item: SearchResponse) => {
      // 优先使用cardImage字段，如果没有则尝试解析photos字段
      let firstImage: string = ''
      if (item.cardImage) {
        firstImage = item.cardImage
      } else if (item.photos) {
        try {
          const photosArr: string[] = JSON.parse(item.photos)
          firstImage = Array.isArray(photosArr) && photosArr.length > 0 ? photosArr[0] : ''
        } catch {
          firstImage = item.photos
        }
      }
      
      const result: EventCardData = {
        id: String(item.id),
        creatorId: Number(item.creatorId) || 0,
        cardImage: firstImage,
        title: item.title || '无标题',
        icon: 'navigate-outline',
        distance: item.distance || '未知距离',
        name: item.name || '匿名用户',
        address: item.address || '位置未知',
        demand: item.demand || '暂无描述',
        price: item.price ? String(item.price) : '0.00',
        createTime: item.createTime || '',
        avatar: item.avatar || ''
      }
      
      return result
    })
  }

  private transformEventToCardData(event: BackendEventDetail): EventCardData {
    let firstImage: string | null = null
    if (event.Photos) {
      try {
        const photosArr: string[] = JSON.parse(event.Photos)
        firstImage = Array.isArray(photosArr) && photosArr.length > 0 ? photosArr[0] : null
      } catch {
        firstImage = event.Photos
      }
    }
    
    return {
      id: String(event.EventId),
      creatorId: Number(event.CreatorId),
      cardImage: firstImage || '',
      title: event.EventTitle || '无标题',
      icon: 'navigate-outline',
      distance: '未知距离',
      name: '未知用户', // 需要从用户表查询
      address: event.Location || '位置未知',
      demand: event.EventDetails || '暂无描述',
      price: event.Price ? String(event.Price) : '0.00',
      createTime: event.CreateTime || '',
      avatar: ''
    }
  }

  // 销毁HTTP请求
  destroy() {
    if (this.httpRequest) {
      this.httpRequest.destroy()
      this.httpRequest = null
    }
  }

  // 设置后端服务器地址
  setBaseUrl(url: string): void {
    this.baseUrl = url
    console.log(`[HttpService] 设置后端地址为: ${url}`)
  }

  // 获取当前后端地址
  getBaseUrl(): string {
    return this.baseUrl
  }
}