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

  async getUserOrders(req, res) {
    try {
      const user = req.user;

      if (!user || !user.id) {
        return res.status(401).json({ error: 'Необхідна авторизація' });
      }

      const orders = await ordersService.getOrdersByUserId(user.id);
      return res.status(200).json(orders);
    } catch (error) {
      console.error('[Контролер замовлень] Помилка отримання історії:', error);
      return res.status(500).json({ error: 'Помилка сервера при отриманні замовлень' });
    }
  }
}

module.exports = new OrdersController();