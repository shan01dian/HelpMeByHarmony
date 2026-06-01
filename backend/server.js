const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const cors = require('cors');
const pool = require('./db.config');

const app = express();
const port = 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 测试数据库连接
async function testDbConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ 数据库连接成功');
    connection.release();
  } catch (error) {
    console.error('❌ 数据库连接失败:', error.message);
    console.log('请确保 MySQL 服务已启动，并检查 .env 文件中的数据库配置');
  }
}

// ==================== 搜索接口 ====================
app.get('/api/cards', async (req, res) => {
  try {
    const { search, type, page = 1, pageSize = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(pageSize);

    let query = `
      SELECT
        e.EventId AS id,
        e.CreatorId AS creatorId,
        e.EventTitle AS title,
        e.EventType AS eventType,
        e.EventCategory AS eventCategory,
        e.Photos AS photos,
        e.Location AS address,
        e.Price AS price,
        e.EventDetails AS demand,
        e.CreateTime AS createTime,
        u.UserName AS name,
        u.UserAvatar AS avatar
      FROM Events e
      LEFT JOIN Users u ON e.CreatorId = u.UserId
      WHERE e.Status = 0
    `;

    const params = [];

    if (search && search.trim()) {
      query += ` AND (e.EventTitle LIKE ? OR e.EventDetails LIKE ? OR e.EventCategory LIKE ?)`;
      const searchTerm = `%${search.trim()}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    if (type !== undefined && type !== '') {
      query += ` AND e.EventType = ?`;
      params.push(parseInt(type));
    }

    query += ` ORDER BY e.CreateTime DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(pageSize), offset);

    const [rows] = await pool.query(query, params);

    // 转换数据格式
    const cards = rows.map(row => ({
      id: String(row.id),
      creatorId: row.creatorId,
      title: row.title || '无标题',
      photos: row.photos || '[]',
      address: row.address || '位置未知',
      demand: row.demand || '暂无描述',
      price: row.price || 0,
      createTime: row.createTime || '',
      name: row.name || '匿名用户',
      avatar: row.avatar || '',
      cardImage: '',
      distance: '未知距离',
      icon: 'navigate-outline'
    }));

    res.json(cards);
  } catch (error) {
    console.error('搜索事件失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// ==================== 获取事件详情 ====================
app.get('/events/:id', async (req, res) => {
  try {
    const eventId = req.params.id;

    const [rows] = await pool.query(`
      SELECT
        e.*,
        u.UserName AS CreatorName,
        u.UserAvatar AS CreatorAvatar,
        u.Introduction AS CreatorIntroduction,
        p.ProviderRole AS CreatorProviderRole,
        p.ServiceRanking AS CreatorServiceRanking,
        p.OrderCount AS CreatorOrderCount
      FROM Events e
      LEFT JOIN Users u ON e.CreatorId = u.UserId
      LEFT JOIN Providers p ON e.CreatorId = p.ProviderId
      WHERE e.EventId = ?
    `, [eventId]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: '事件不存在' });
    }

    const event = rows[0];

    // 获取标签
    const [tags] = await pool.query(
      'SELECT Tag FROM EventTags WHERE EventId = ?',
      [eventId]
    );

    res.json({
      success: true,
      event: {
        EventId: event.EventId,
        CreatorId: event.CreatorId,
        EventTitle: event.EventTitle,
        EventType: event.EventType,
        EventCategory: event.EventCategory,
        Photos: event.Photos,
        Location: event.Location,
        Price: event.Price,
        EventDetails: event.EventDetails,
        CreateTime: event.CreateTime,
        CreatorName: event.CreatorName,
        CreatorAvatar: event.CreatorAvatar,
        CreatorIntroduction: event.CreatorIntroduction,
        CreatorProviderRole: event.CreatorProviderRole,
        CreatorServiceRanking: event.CreatorServiceRanking,
        CreatorOrderCount: event.CreatorOrderCount,
        Tags: tags.map(t => t.Tag)
      }
    });
  } catch (error) {
    console.error('获取事件详情失败:', error);
    res.status(500).json({ success: false, error: '服务器错误' });
  }
});

// ==================== 认证接口 ====================

// 发送验证码
app.post('/send-code', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.length !== 11) {
      return res.status(400).json({ error: '请输入正确的手机号' });
    }

    // 开发环境使用固定验证码
    const verifyCode = process.env.NODE_ENV === 'development'
      ? process.env.DEV_VERIFY_CODE || '1234'
      : Math.floor(1000 + Math.random() * 9000).toString();

    // 存储验证码（这里简化处理，实际应该存到数据库或 Redis）
    // TODO: 实现验证码存储和过期逻辑

    console.log(`[验证码] 手机号: ${phone}, 验证码: ${verifyCode}`);

    res.json({ success: true, message: '验证码已发送' });
  } catch (error) {
    console.error('发送验证码失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// 检查手机号是否已注册
app.post('/check-phone', async (req, res) => {
  try {
    const { phone } = req.body;

    const [rows] = await pool.query(
      'SELECT UserId FROM Users WHERE PhoneNumber = ?',
      [phone]
    );

    res.json({ registered: rows.length > 0 });
  } catch (error) {
    console.error('检查手机号失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// 用户登录
app.post('/login', async (req, res) => {
  try {
    const { phone, code } = req.body;

    // 开发环境验证固定验证码
    if (process.env.NODE_ENV === 'development') {
      if (code !== (process.env.DEV_VERIFY_CODE || '1234')) {
        return res.status(400).json({ error: '验证码错误' });
      }
    }

    // 查找用户
    const [users] = await pool.query(
      'SELECT UserId, UserName, UserAvatar FROM Users WHERE PhoneNumber = ?',
      [phone]
    );

    if (users.length === 0) {
      return res.status(400).json({ error: '用户不存在，请先注册' });
    }

    const user = users[0];

    // 生成简单的 token（实际应使用 JWT）
    const token = `token_${user.UserId}_${Date.now()}`;

    res.json({
      token: token,
      user: {
        id: user.UserId,
        name: user.UserName,
        role: 'user'
      }
    });
  } catch (error) {
    console.error('登录失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// 用户注册
app.post('/register', async (req, res) => {
  try {
    const { phone, code, userName, realName, idCardNumber, birthDate, location, avatar, introduction } = req.body;

    // 开发环境验证固定验证码
    if (process.env.NODE_ENV === 'development') {
      if (code !== (process.env.DEV_VERIFY_CODE || '1234')) {
        return res.status(400).json({ error: '验证码错误' });
      }
    }

    // 检查手机号是否已注册
    const [existing] = await pool.query(
      'SELECT UserId FROM Users WHERE PhoneNumber = ?',
      [phone]
    );

    if (existing.length > 0) {
      return res.status(400).json({ error: '该手机号已注册' });
    }

    // 插入新用户
    const [result] = await pool.query(
      `INSERT INTO Users (UserName, PhoneNumber, RealName, IdCardNumber, UserAvatar, Location, BirthDate, Introduction)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userName, phone, realName, idCardNumber, avatar || '', location, birthDate, introduction || '']
    );

    const userId = result.insertId;

    // 同时创建 Consumer 记录
    await pool.query(
      'INSERT INTO Consumers (ConsumerId) VALUES (?)',
      [userId]
    );

    // 生成简单的 token
    const token = `token_${userId}_${Date.now()}`;

    res.json({
      token: token,
      user: {
        id: userId,
        name: userName,
        role: 'user'
      }
    });
  } catch (error) {
    console.error('注册失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// ==================== 用户接口 ====================

// 获取用户资料
app.get('/users/:id/profile', async (req, res) => {
  try {
    const userId = req.params.id;

    const [users] = await pool.query(`
      SELECT
        u.UserId,
        u.UserName,
        u.UserAvatar,
        u.RealName,
        u.PhoneNumber,
        u.Location,
        u.BirthDate,
        u.Introduction,
        u.FollowerCount,
        p.ProviderRole,
        p.ServiceRanking,
        p.OrderCount,
        c.BuyerRanking
      FROM Users u
      LEFT JOIN Providers p ON u.UserId = p.ProviderId
      LEFT JOIN Consumers c ON u.UserId = c.ConsumerId
      WHERE u.UserId = ?
    `, [userId]);

    if (users.length === 0) {
      return res.status(404).json({ error: '用户不存在' });
    }

    const user = users[0];

    res.json({
      userId: user.UserId,
      userName: user.UserName,
      userAvatar: user.UserAvatar,
      realName: user.RealName,
      phoneNumber: user.PhoneNumber,
      location: user.Location,
      birthDate: user.BirthDate,
      introduction: user.Introduction,
      followerCount: user.FollowerCount || 0,
      providerRole: user.ProviderRole || 0,
      serviceRanking: user.ServiceRanking || 0,
      orderCount: user.OrderCount || 0,
      buyerRanking: user.BuyerRanking || 0
    });
  } catch (error) {
    console.error('获取用户资料失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// ==================== 根路由 - API 文档 ====================
app.get('/', (req, res) => {
  res.json({
    name: 'HelpMe 后端 API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      'GET /api/cards': '搜索事件 (参数: search, type, page, pageSize)',
      'GET /events/:id': '获取事件详情',
      'POST /send-code': '发送验证码 (body: { phone })',
      'POST /check-phone': '检查手机号是否已注册 (body: { phone })',
      'POST /login': '用户登录 (body: { phone, code })',
      'POST /register': '用户注册 (body: { phone, code, userName, ... })',
      'GET /users/:id/profile': '获取用户资料',
      'GET /health': '健康检查'
    },
    note: 'POST 接口需要使用 Postman 或前端应用调用，不能直接在浏览器访问'
  });
});

// ==================== 健康检查 ====================
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', message: '服务器运行正常', database: 'connected' });
  } catch (error) {
    res.json({ status: 'warning', message: '服务器运行正常', database: 'disconnected' });
  }
});

// 启动服务器
app.listen(port, async () => {
  console.log(`\n🚀 后端服务器运行在 http://localhost:${port}`);
  console.log('\n可用接口:');
  console.log('  GET  /api/cards?search=关键词&type=类型 - 搜索事件');
  console.log('  GET  /events/:id - 获取事件详情');
  console.log('  POST /send-code - 发送验证码');
  console.log('  POST /check-phone - 检查手机号');
  console.log('  POST /login - 用户登录');
  console.log('  POST /register - 用户注册');
  console.log('  GET  /users/:id/profile - 获取用户资料');
  console.log('  GET  /health - 健康检查');

  await testDbConnection();
});
