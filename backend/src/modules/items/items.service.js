const db = require('../../config/db');

const insertItem = async (establishmentId, name, price, description) => {
  return await db.item.create({
    data: {
      establishment_id: parseInt(establishmentId, 10),
      name,
      price: parseFloat(price),
      description,
    },
  });
};

const getEstablishmentsList = async () => {
  return await db.establishment.findMany({
    select: { id: true, name: true }
  });
};

const getItemsByEstablishment = async (establishmentId) => {
  return await db.item.findMany({
    where: {
      establishment_id: parseInt(establishmentId, 10),
    },
    orderBy: { name: 'asc' },
  });
};

module.exports = { 
  insertItem, 
  getEstablishmentsList, 
  getItemsByEstablishment 
};