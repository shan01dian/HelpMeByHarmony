const mysql = require('mysql2/promise');

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'help_me_db',
  connectionLimit: 10,
  queueLimit: 0,
  waitForConnections: true,
  dateStrings: true,
};

const pool = mysql.createPool(dbConfig);

module.exports = pool;
