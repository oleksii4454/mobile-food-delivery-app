const db = require('../../config/db');

const insertEstablishment = async (name, type, address) => {
  return await db.establishment.create({
    data: {
      name,
      type,
      address,
    },
  });
};

const getAllEstablishments = async () => {
  return await db.establishment.findMany({
    orderBy: { name: 'asc' }
  });
};

module.exports = {
    insertEstablishment,
    getAllEstablishments
};