import { httpGet, RequestParams } from './HttpUtil'
import { EventCardData, SearchResponse } from '../model/EventModel'

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
  // 销毁服务实例，释放资源
  destroy(): void {
    console.info('[HttpService] 服务实例已销毁')
  }

  // 搜索事件 - 使用真实的 /api/cards 接口
  async searchEvents(keyword: string, type?: string): Promise<EventCardData[]> {
    console.info(`[HttpService] 开始搜索: keyword="${keyword}", type="${type}"`)

    try {
      let params: Record<string, string> = {}
      if (keyword && keyword.trim().length > 0 && type && type.trim().length > 0) {
        params = { 'search': keyword.trim(), 'type': type.trim() }
      } else if (keyword && keyword.trim().length > 0) {
        params = { 'search': keyword.trim() }
      } else if (type && type.trim().length > 0) {
        params = { 'type': type.trim() }
      }

      const rawData: BackendCardsResponse | SearchResponse[] = await httpGet<BackendCardsResponse | SearchResponse[]>('/api/cards', params)
      console.info(`[HttpService] 从后端获取到数据`)

      // 后端返回的数据结构是数组，而不是{value: [...]}
      let data: SearchResponse[] = []
      if (Array.isArray(rawData)) {
        data = rawData as SearchResponse[]
      } else {
        const response = rawData as BackendCardsResponse
        if (response.value && Array.isArray(response.value)) {
          data = response.value
        }
      }

      console.info(`[HttpService] 从后端解析到 ${data.length} 条记录`)
      return this.transformData(data)
    } catch (error) {
      console.error(`[HttpService] 后端请求失败:`, error)
      return []
    }
  }

  // 获取事件详情 - 使用 /events/:id 接口
  async getEventDetail(eventId: string): Promise<EventCardData | null> {
    console.info(`[HttpService] 获取事件详情: ${eventId}`)

    try {
      const result: BackendEventResponse = await httpGet<BackendEventResponse>(`/events/${eventId}`)
      if (result.success && result.event) {
        console.info(`[HttpService] 从后端获取到事件详情`)
        return this.transformEventToCardData(result.event)
      }
    } catch (error) {
      console.error(`[HttpService] 后端获取详情失败:`, error)
    }

    return null
  }

  private transformData(data: SearchResponse[]): EventCardData[] {
    const result: EventCardData[] = []
    for (let i = 0; i < data.length; i++) {
      const item = data[i]
      // 优先使用cardImage字段，如果没有则尝试解析photos字段
      let firstImage: string = ''
      if (item.cardImage) {
        firstImage = item.cardImage
      } else if (item.photos) {
        try {
          const photosArr: string[] = JSON.parse(item.photos) as string[]
          firstImage = photosArr.length > 0 ? photosArr[0] : ''
        } catch {
          firstImage = item.photos
        }
      }

      const cardData: EventCardData = {
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
      result.push(cardData)
    }
    return result
  }

  private transformEventToCardData(event: BackendEventDetail): EventCardData {
    let firstImage: string = ''
    if (event.Photos) {
      try {
        const photosArr: string[] = JSON.parse(event.Photos) as string[]
        firstImage = photosArr.length > 0 ? photosArr[0] : ''
      } catch {
        firstImage = event.Photos
      }
    }

    const cardData: EventCardData = {
      id: String(event.EventId),
      creatorId: Number(event.CreatorId),
      cardImage: firstImage,
      title: event.EventTitle || '无标题',
      icon: 'navigate-outline',
      distance: '未知距离',
      name: '未知用户',
      address: event.Location || '位置未知',
      demand: event.EventDetails || '暂无描述',
      price: event.Price ? String(event.Price) : '0.00',
      createTime: event.CreateTime || '',
      avatar: ''
    }
    return cardData
  }
}
