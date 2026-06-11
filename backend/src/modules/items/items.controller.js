const itemsService = require('./items.service');

const getEstablishmentsDropdown = async (req, res) => {
  try {
    const establishments = await itemsService.getEstablishmentsList();
    return res.json(establishments);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

const createItemRoute = async (req, res) => {
  try {
    const { establishment_id, name, price, description } = req.body;
    
    if (!establishment_id || !name || !price) {
      return res.status(400).json({ error: 'Missing required item fields.' });
    }

    const newItem = await itemsService.insertItem(establishment_id, name, price, description);
    return res.status(201).json({ success: true, data: newItem });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to create menu item.' });
  }
};

const getPublicItems = async (req, res) => {
  const { establishment_id } = req.query;

  if (!establishment_id) {
    return res.status(400).json({ error: 'Query parameter establishment_id is required' });
  }

  try {
    const items = await itemsService.getItemsByEstablishment(establishment_id);
    return res.json(items);
  } catch (error) {
    return res.status(500).json({ error: 'Database operational failure' });
  }
};

module.exports = { 
  createItemRoute, 
  getEstablishmentsDropdown, 
  getPublicItems 
};