const pool = require('../../config/db');

class OrdersService {
  async createOrder(orderData, user) {
    const { establishment_id, delivery_address, items } = orderData;

    if (!items || items.length === 0) {
      throw new Error('Кошик порожній');
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let totalPrice = 0;
      for (const orderItem of items) {
        const itemResult = await client.query('SELECT price FROM items WHERE id = $1', [orderItem.item_id]);
        
        if (itemResult.rows.length === 0) {
          throw new Error(`Товар з ID ${orderItem.item_id} не знайдено в меню`);
        }
        
        totalPrice += Number(itemResult.rows[0].price) * orderItem.quantity;
      }

      const insertOrderQuery = `
        INSERT INTO orders (user_id, establishment_id, status, total_price, delivery_address) 
        VALUES ($1, $2, $3, $4, $5) 
        RETURNING id, status, total_price, delivery_address
      `;
      
      const orderResult = await client.query(insertOrderQuery, [
        user.id,               
        establishment_id, 
        'Опрацьовується', 
        totalPrice, 
        delivery_address
      ]);
      
      const newOrder = orderResult.rows[0];

      const insertOrderItemQuery = `
        INSERT INTO order_items (order_id, item_id, quantity) 
        VALUES ($1, $2, $3)
      `;

      for (const orderItem of items) {
        await client.query(insertOrderItemQuery, [
          newOrder.id,
          orderItem.item_id, 
          orderItem.quantity
        ]);
      }

      await client.query('COMMIT');

      console.log(`[PostgreSQL] Повноцінне замовлення #${newOrder.id} успішно збережено в таблиці orders та order_items!`);

      return {
        id: newOrder.id,
        status: newOrder.status,
        total_price: newOrder.total_price,
        message: 'Замовлення успішно сформовано та записано в БД!'
      };

    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Помилка всередині транзакції замовлення, робимо ROLLBACK:', error.message);
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new OrdersService();