const establishmentsService = require('./establishments.service');

const createEstablishment = async (req, res) => {
  const { name, type, address } = req.body;

  if (!name || !type || !address) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const newEstablishment = await establishmentsService.insertEstablishment(name, type, address);
    res.status(201).json(newEstablishment);
  } catch (error) {
    res.status(500).json({ error: 'Database operational failure' });
  }
};

const getActiveEstablishments = async (req, res) => {
  try {
    const establishments = await establishmentsService.getAllEstablishments();
    res.json(establishments);
  } catch (error) {
    res.status(500).json({ error: 'Database operational failure' });
  }
};

module.exports = { 
  createEstablishment,
  getActiveEstablishments
};