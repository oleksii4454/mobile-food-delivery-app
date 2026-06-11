const express = require('express');
const router = express.Router();
const itemsController = require('./items.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.get('/', itemsController.getPublicItems);

router.post('/', authenticateToken, itemsController.createItemRoute);
router.get('/admin/lookup', authenticateToken, itemsController.getEstablishmentsDropdown);

module.exports = router;