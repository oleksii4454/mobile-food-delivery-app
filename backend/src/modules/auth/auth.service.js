const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const pool = require('../../config/db');

class AuthService {
  async loginUser(email, password) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await pool.query(query, [email]);

    if (result.rows.length === 0) {
      throw new Error('Невірний email');
    }

    const user = result.rows[0];

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordValid) {
      throw new Error('Невірний email або пароль');
    }

    const secret = process.env.JWT_SECRET || 'test';
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      secret,
      { expiresIn: '1h' }
    );

    return { token, role: user.role };
  }

  async registerUser(email, password, name) {
    const checkQuery = 'SELECT id FROM users WHERE email = $1';
    const checkResult = await pool.query(checkQuery, [email]);

    if (checkResult.rows.length > 0) {
      throw new Error('Користувач з таким email вже зареєстрований');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const insertQuery = `
      INSERT INTO users (name, email, password_hash, role) 
      VALUES ($1, $2, $3, $4) 
      RETURNING id, name, email, role
    `;
    
    const insertResult = await pool.query(insertQuery, [name, email, hashedPassword, 'Клієнт']);
    const newUser = insertResult.rows[0];

    console.log(`[PostgreSQL] Зареєстровано користувача: ${newUser.name} (${newUser.email})`);

    return {
      message: 'Реєстрація пройшла успішно! Тепер ви можете увійти.',
      user: { id: newUser.id, name: newUser.name, email: newUser.email }
    };
  }
}

module.exports = new AuthService();