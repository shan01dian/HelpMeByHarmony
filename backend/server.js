const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 模拟数据
const mockEvents = [
  {
    id: "1",
    photos: '["https://via.placeholder.com/300x200"]',
    address: "北京市朝阳区",
    title: "电脑维修服务",
    demand: "专业电脑维修，快速解决各种问题",
    price: 50,
    createTime: "2024-01-15",
    name: "张师傅",
    avatar: "",
    creatorId: 101
  },
  {
    id: "2", 
    photos: '["https://via.placeholder.com/300x200"]',
    address: "上海市浦东新区",
    title: "英语学习辅导",
    demand: "专业英语辅导，提高口语和写作能力",
    price: 80,
    createTime: "2024-01-16",
    name: "李老师",
    avatar: "",
    creatorId: 102
  },
  {
    id: "3",
    photos: '["https://via.placeholder.com/300x200"]',
    address: "广州市天河区",
    title: "搬家服务",
    demand: "专业搬家团队，安全高效",
    price: 200,
    createTime: "2024-01-17",
    name: "王师傅",
    avatar: "",
    creatorId: 103
  }
];

// 搜索接口
app.get('/api/events', (req, res) => {
  console.log('收到搜索请求，参数:', req.query);
  
  const { search } = req.query;
  let results = mockEvents;
  
  if (search) {
    const searchLower = search.toLowerCase();
    results = mockEvents.filter(event => 
      event.title.toLowerCase().includes(searchLower) ||
      event.demand.toLowerCase().includes(searchLower) ||
      event.name.toLowerCase().includes(searchLower)
    );
  }
  
  console.log(`返回 ${results.length} 条结果`);
  res.json(results);
});

// 获取事件详情接口
app.get('/api/events/:id', (req, res) => {
  const eventId = req.params.id;
  console.log('获取事件详情:', eventId);
  
  const event = mockEvents.find(e => e.id === eventId);
  if (event) {
    res.json(event);
  } else {
    res.status(404).json({ error: '事件不存在' });
  }
});

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: '服务器运行正常' });
});

app.listen(port, () => {
  console.log(`后端服务器运行在 http://localhost:${port}`);
  console.log('可用接口:');
  console.log('  GET /api/events?search=关键词 - 搜索事件');
  console.log('  GET /api/events/:id - 获取事件详情');
  console.log('  GET /health - 健康检查');
});