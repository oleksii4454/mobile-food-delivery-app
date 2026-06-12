const jwt = require('jsonwebtoken');
const db = require('../config/db');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Доступ заборонено. Токен відсутній.' });
  }

  try {
    const secret = process.env.JWT_SECRET || 'test';
    const decoded = jwt.verify(token, secret);

    const activeSession = await db.session.findUnique({
      where: { token: token },
    });

    if (!activeSession) {
      return res.status(401).json({ error: 'Сесія недійсна або ви вже вийшли з акаунту.' });
    }

    if (new Date() > new Date(activeSession.expires_at)) {
      await db.session.delete({ where: { token: token } }).catch(() => {});
      return res.status(401).json({ error: 'Термін дії сесії вичерпано.' });
    }

    req.user = decoded;
    next();
  } catch (error) {
    console.error('Помилка валідації токена:', error.message);
    return res.status(403).json({ error: 'Недійсний або прострочений токен.' });
  }
};

module.exports = authenticateToken;