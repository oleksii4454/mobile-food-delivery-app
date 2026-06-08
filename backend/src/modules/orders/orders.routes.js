const express = require('express');
const router = express.Router();
const ordersController = require('./orders.controller');
const verifyToken = require('../../middleware/auth.middleware');

router.post('/', verifyToken, ordersController.createOrder);

module.exports = router;