const express = require('express');

// CORS中间件配置
const corsMiddleware = (req, res, next) => {
  // 允许所有来源访问（生产环境应限制为特定域名）
  res.header('Access-Control-Allow-Origin', '*');
  
  // 允许的HTTP方法
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  
  // 允许的请求头
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  // 允许携带凭证（如cookies）
  res.header('Access-Control-Allow-Credentials', 'true');
  
  // 预检请求处理
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
};

module.exports = corsMiddleware;