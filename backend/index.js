require('dotenv').config();
require('./src/config/db');

const express = require('express');
const cors = require('cors');
const authRoutes = require('./src/modules/auth/auth.routes');
const ordersRoutes = require('./src/modules/orders/orders.routes');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/orders', ordersRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Сервер запущено на порту ${PORT}`));