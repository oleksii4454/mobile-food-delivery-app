const ordersService = require('./orders.service')

class OrdersController {
  async createOrder(req, res) {
    try {
      const orderData = req.body;
      
      const user = req.user; 

      console.log('[Контролер замовлень] Спроба створення замовлення. Юзер з токену:', user);

      if (!user || !user.id) {
        return res.status(401).json({ error: 'Користувача не ідентифіковано або ID відсутній у токені' });
      }

      const newOrder = await ordersService.createOrder(orderData, user);
      
      return res.status(201).json(newOrder);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }
}

module.exports = new OrdersController();