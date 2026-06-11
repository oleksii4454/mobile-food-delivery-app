const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('../generated');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT || '5432', 10),
});

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Помилка підключення до бази даних:', err.message);
  } else {
    console.log('Успішно підключено до бази через Prisma Adapter. Час бази даних:', res.rows[0].now);
  }
});

prisma.query = (text, params, callback) => pool.query(text, params, callback);
prisma.connect = (callback) => pool.connect(callback);
prisma.on = (event, callback) => pool.on(event, callback);
prisma.end = () => pool.end();

module.exports = prisma;