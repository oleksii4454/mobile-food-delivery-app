const db = require('../../config/db'); 

class OrdersService {
  async createOrder(orderData, user) {
    const { establishment_id, delivery_address, items } = orderData;

    if (!items || items.length === 0) {
      throw new Error('Кошик порожній');
    }

    return await db.$transaction(async (tx) => {
      let totalPrice = 0;
      const verifiedItems = [];

      for (const orderItem of items) {
        const item = await tx.item.findUnique({
          where: { id: parseInt(orderItem.item_id, 10) }
        });

        if (!item) {
          throw new Error(`Товар з ID ${orderItem.item_id} не знадено в меню`);
        }

        totalPrice += Number(item.price) * orderItem.quantity;
        
        verifiedItems.push({
          item_id: parseInt(orderItem.item_id, 10),
          quantity: parseInt(orderItem.quantity, 10)
        });
      }

      const newOrder = await tx.order.create({
        data: {
          user_id: parseInt(user.id, 10),
          establishment_id: parseInt(establishment_id, 10) || null,
          status: 'Опрацьовується',
          total_price: totalPrice,
          delivery_address: delivery_address || ''
        }
      });

      await tx.orderItem.createMany({
        data: verifiedItems.map(item => ({
          order_id: newOrder.id,
          item_id: item.item_id,
          quantity: item.quantity
        }))
      });

      console.log(`[Prisma] Повноцінне замовлення #${newOrder.id} успішно збережено в таблиці orders та order_items!`);

      return {
        id: newOrder.id,
        status: newOrder.status,
        total_price: newOrder.total_price,
        message: 'Замовлення успішно сформовано та записано в БД!'
      };
    });
  }

  async getOrdersByUserId(userId) {
    return await db.order.findMany({
      where: {
        user_id: parseInt(userId, 10)
      },
      include: {
        order_items: { 
          include: {
            item: true
          }
        }
      },
      orderBy: {
        id: 'desc'
      }
    });
  }

  
  async getAllOrdersForAdmin() {
    return await db.order.findMany({
      include: {
        order_items: {
          include: {
            item: true
          }
        }
      },
      orderBy: {
        id: 'desc'
      }
    });
  }

  
  async updateOrderStatus(orderId, newStatus) {
    return await db.order.update({
      where: {
        id: parseInt(orderId, 10)
      },
      data: {
        status: newStatus
      }
    });
  }
}

module.exports = new OrdersService();