const express = require('express');
const router = express.Router();
const establishmentsController = require('./establishments.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', establishmentsController.createEstablishment);
router.get('/', establishmentsController.getActiveEstablishments);

module.exports = router;