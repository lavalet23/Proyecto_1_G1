const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const DensidadVehicular = require('./models/DensidadVehicular');

const app = express();
const port = 3000; // Puerto en el que el servidor escuchará

// Habilitar CORS para todas las rutas
app.use(cors());

// Conectar a MongoDB usando Mongoose
mongoose.connect('colocar su linea de conexion de mongodb como se vio en clase', {
    //   useNewUrlParser: true,
    //   useUnifiedTopology: true
})
    .then(() => console.log('Conectado a MongoDB Atlas'))
    .catch((error) => console.log('Error al conectar a MongoDB:', error));

// Ruta para obtener los datos de la densidad vehicular
app.get('/api/beneficios', async (req, res) => {
    try {
        // Obtener los documentos desde MongoDB Atlas
        const datos = await DensidadVehicular.find();

        const laneData1 = datos
            .map(item =>
                item.lane_data
                    .filter(lane => lane.lane_id === 1) // Filtrar solo los objetos con el lane_id deseado
                    .map(lane => lane.density)  // Extraer solo la densidad
            ).flat(); // Aplanar el arreglo para que solo tengamos los números de densidad

        const laneData2 = datos
            .map(item =>
                item.lane_data
                    .filter(lane => lane.lane_id === 2) // Filtrar solo los objetos con el lane_id deseado
                    .map(lane => lane.density)  // Extraer solo la densidad
            ).flat(); // Aplanar el arreglo para que solo tengamos los números de densidad

        const laneData3 = datos
            .map(item =>
                item.lane_data
                    .filter(lane => lane.lane_id === 3) // Filtrar solo los objetos con el lane_id deseado
                    .map(lane => lane.density)  // Extraer solo la densidad
            ).flat(); // Aplanar el arreglo para que solo tengamos los números de densidad

        const timestamp = datos
            .map(item => {
                const fecha = new Date(item.timestamp);
                // Obtener día y mes
                const diaMes = fecha.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit' });
                // Obtener hora y minuto
                const horaMinuto = fecha.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
                return `${diaMes} ${horaMinuto}`;
            }
            )

        // Responder con los datos listos para la gráfica
        res.json({
            labels: timestamp, // Etiquetas (fechas)
            datasets: [laneData1, laneData2, laneData3]
        });
    } catch (error) {
        res.status(500).json({ error: 'Error al obtener los datos' });
    }
});

// Arrancar el servidor en el puerto 3000
app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
});
