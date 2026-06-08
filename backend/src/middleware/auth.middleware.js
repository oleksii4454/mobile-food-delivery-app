const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Доступ заборонено: токен відсутній' });
  }

  try {
    const secret = process.env.JWT_SECRET || 'test';
    const decoded = jwt.verify(token, secret);
    
    req.user = decoded;
    
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Невалідний або протермінований токен' });
  }
}

module.exports = verifyToken;