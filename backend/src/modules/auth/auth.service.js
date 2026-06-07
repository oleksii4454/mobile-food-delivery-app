const jwt = require('jsonwebtoken');

const MOCK_USER = {
  email: 'test@delivery.com',
  password: 'password123',
  role: 'клієнт'
};

class AuthService {
  async loginUser(email, password) {
    if (email !== MOCK_USER.email || password !== MOCK_USER.password) {
      throw new Error('Невірний email або пароль');
    }

    const secret = process.env.JWT_SECRET || 'test';
    
    const token = jwt.sign(
      { email: MOCK_USER.email, role: MOCK_USER.role },
      secret,
      { expiresIn: '15m' }
    );

    return {
      token,
      role: MOCK_USER.role
    };
  }
}

module.exports = new AuthService();