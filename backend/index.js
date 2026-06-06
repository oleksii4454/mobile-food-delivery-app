require('dotenv').config();

const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

app.get('/api/orders', async (req, res) => {
  try {
    const dbTime = await pool.query('SELECT NOW()');
    res.json({ 
      message: "test",
      db_status: "connected",
      time: dbTime.rows[0].now 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.APP_PORT || 3000;
app.listen(PORT, () => console.log('Server started at port 3000'));