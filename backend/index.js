const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({
  user: 'admin',
  host: 'localhost',
  database: 'delivery_db',
  password: 'admin',
  port: 5432,
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

app.listen(3000, () => console.log('Server started at port 3000'));