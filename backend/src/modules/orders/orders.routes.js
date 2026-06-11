const express = require('express');
const router = express.Router();
const ordersController = require('./orders.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', ordersController.createOrder);
router.get('/', ordersController.getUserOrders);

module.exports = router;