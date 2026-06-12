const express = require('express');
const router = express.Router();
const ordersController = require('./orders.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', ordersController.createOrder);
router.get('/', ordersController.getUserOrders);

const checkAdmin = (req, res, next) => {
  if (req.user && (req.user.role === 'Адмін')) {
    return next();
  }
  return res.status(403).json({ error: 'Доступ заборонено: Необхідні права адміністратора' });
};

const checkCourierOrAdmin = (req, res, next) => {
  if (req.user && (req.user.role === 'Кур\'єр' || req.user.role === 'Адмін')) return next();
  return res.status(403).json({ error: 'Доступ заборонено: Необхідні права кур\'єра або адміна' });
};

router.get('/admin', checkAdmin, ordersController.getAdminOrders);

router.get('/courier', checkCourierOrAdmin, ordersController.getAdminOrders);
router.patch('/:id/status', checkCourierOrAdmin, ordersController.updateOrderStatus);

module.exports = router;