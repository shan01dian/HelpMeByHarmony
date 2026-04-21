export interface EventCardData {
  id: string
  creatorId: number
  cardImage: string
  title: string
  icon: string
  distance: string
  name: string
  address: string
  demand: string
  price: string
  createTime: string
  avatar: string
}

export interface SearchResponse {
  id: string | number
  photos?: string
  cardImage?: string
  address: string
  title: string
  demand: string
  price: number | string
  createTime: string
  name: string
  avatar: string
  creatorId: number
  distance?: string
}

// 搜索页面状态接口
export interface SearchResultPage {
  searchResults: EventCardData[]
  isLoading: boolean
  searchText: string
  hasSearched: boolean
}