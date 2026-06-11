const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('../generated');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
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