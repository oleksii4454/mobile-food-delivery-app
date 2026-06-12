const authService = require('./auth.service');

class AuthController {
  async register(req, res) {
    try {
      const { email, password, name } = req.body;
      const result = await authService.registerUser(email, password, name);
      return res.status(201).json(result);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async login(req, res) {
    try {
      const { email, password } = req.body;
      const result = await authService.loginUser(email, password);
      return res.status(200).json(result);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async logout(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(400).json({ error: 'Токен відсутній або невірно сформований' });
      }

      const token = authHeader.split(' ')[1];

      await authService.deleteSessionByToken(token);

      return res.status(200).json({ success: true, message: 'Сесію успішно видалено' });
    } catch (error) {
      console.error('[Контролер авторизації] Помилка виходу:', error);
      return res.status(500).json({ error: 'Внутрішня помилка сервера при виході' });
    }
  }
}

module.exports = new AuthController();