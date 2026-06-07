const authService = require('./auth.service');

class AuthController {
  async login(req, res) {
    try {
      const { email, password } = req.body;
      const result = await authService.loginUser(email, password);
      
      return res.status(200).json(result);
    } catch (error) {
      return res.status(401).json({ error: error.message });
    }
  }
}

module.exports = new AuthController();