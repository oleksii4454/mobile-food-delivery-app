const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const db = require('../../config/db');

class AuthService {
  async loginUser(email, password) {
    const user = await db.user.findFirst({
      where: { email: email }
    });

    if (!user) {
      throw new Error('Невірний email або пароль');
    }

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

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1);

    await db.session.create({
      data: {
        user_id: user.id,
        token: token,
        expires_at: expiresAt
      }
    });

    return { token, role: user.role };
  }

  async registerUser(email, password, name) {
    const existingUserCount = await db.user.count({
      where: { email: email }
    });

    if (existingUserCount > 0) {
      throw new Error('Користувач з таким email вже зареєстрований');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const newUser = await db.user.create({
      data: {
        name,
        email,
        password_hash: hashedPassword,
        role: 'Клієнт'
      },
      select: { id: true, name: true, email: true }
    });

    console.log(`[Prisma] Зареєстровано користувача: ${newUser.name} (${newUser.email})`);

    return {
      message: 'Реєстрація пройшла успішно! Тепер ви можете увійти.',
      user: newUser
    };
  }

  async deleteSessionByToken(token) {
    if (!token) throw new Error('Token payload is required');
    
    try {
      return await db.session.delete({
        where: { token: token }
      });
    } catch (error) {
      if (error.code === 'P2025') return null;
      throw error;
    }
  }
}

module.exports = new AuthService();