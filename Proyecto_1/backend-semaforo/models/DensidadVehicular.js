const mongoose = require('mongoose');

// Definimos el esquema para el "lane_data"
const laneDataSchema = new mongoose.Schema({
  lane_id: { type: Number, required: true },
  density: { type: Number, required: true }
});

// Esquema principal para la colección densidad_vehicular
const densidadVehicularSchema = new mongoose.Schema({
  timestamp: { type: Date, required: true },
  intersection_id: { type: String, required: true },
  lane_data: [laneDataSchema]
}, { collection: 'densidad_vehicular' }); // Aquí especificamos el nombre exacto de la colección

// Creamos el modelo basado en el esquema
const DensidadVehicular = mongoose.model('DensidadVehicular', densidadVehicularSchema);

module.exports = DensidadVehicular;
