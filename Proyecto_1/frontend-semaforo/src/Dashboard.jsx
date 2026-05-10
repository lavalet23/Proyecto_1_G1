import { useEffect, useState } from 'react'
import { LinesChart } from "./LinesChart";
import mqtt from 'mqtt';

const options = {
  protocol: "wss",
  username: "gabriel",
  password: "123",
  clientId: `mqttjs_${Math.random().toString(16).substring(2, 8)}`,
};

const MQTT_URL = 'xxxx'; // URL del broker HiveMQ
const TOPIC_ALERT_SEMAFORO1 = "arqui1/rasp-1/alert/";
const TOPIC_ALERT_SEMAFORO2 = "arqui1/rasp-2/alert/";
const TOPIC_ALERT_SEMAFORO3 = "arqui1/rasp-3/alert/";
const TOPIC_REINICIAR_SEMAFOROS = 'arqui1/rasp-reiniciar';

function App() {
  
  const [dataGrafica, setDataGrafica] = useState(null)
  const [client, setClient] = useState(null);
  const [msgAlet, setMsgAlert] = useState(null);

  // Conectar con el broker MQTT
  useEffect(() => {
    const mqttClient = mqtt.connect(MQTT_URL, options);

    mqttClient.on('connect', () => {
      console.log('Conectado al broker MQTT');
      mqttClient.subscribe(TOPIC_ALERT_SEMAFORO1, { qos: 1 });
      mqttClient.subscribe(TOPIC_ALERT_SEMAFORO2);
      mqttClient.subscribe(TOPIC_ALERT_SEMAFORO3);
    });

    mqttClient.on('message', (topic, message) => {
      if (topic === TOPIC_ALERT_SEMAFORO1) {
        console.log(message.toString());
        setMsgAlert('ALERTA ACTIVADA Semaforo 1')
      }
      else if (topic === TOPIC_ALERT_SEMAFORO2) {
        console.log(message.toString());
        setMsgAlert('ALERTA ACTIVADA Semaforo 2')
      }
      else if (topic === TOPIC_ALERT_SEMAFORO3) {
        console.log(message.toString());
        setMsgAlert('ALERTA ACTIVADA Semaforo 3')
      }
    });

    setClient(mqttClient);

    return () => {
      mqttClient.end();
    };
  }, []);
  

  const fetchData = async () => {
    const response = await fetch('http://localhost:3000/api/beneficios');
    const data = await response.json();
    const midata = {
      labels: data.labels,
      datasets: [
        {
          label: 'Semaforo 1',
          data: data.datasets[0],
          fill: true,
          borderColor: 'rgb(255, 99, 132)',
          backgroundColor: 'rgba(255, 99, 132, 0.5)',
          pointBorderColor: 'rgba(255, 99, 132)',
          pointBackgroundColor: 'rgba(255, 99, 132)',
        },
        {
          label: 'Semaforo 2',
          data: data.datasets[1],
          fill: true,
          borderColor: 'rgb(99, 255, 107)',
          backgroundColor: 'rgb(4, 117, 10, 0.5)',
          pointBorderColor: 'rgb(4, 117, 10)',
          pointBackgroundColor: 'rgb(4, 117, 10)',
        },
        {
          label: 'Semaforo 3',
          data: data.datasets[2],
          fill: true,
        },
      ],
    };
    setDataGrafica(midata)
    return midata;
  }

  useEffect(() => {
    fetchData()
  }, [])

  // Enviar mensaje para encender o apagar LED verde
  const reiniciarSemaforos = (action) => {
    if (client) {
      client.publish(TOPIC_REINICIAR_SEMAFOROS, action);  // "TRUE"
      setMsgAlert(null)
    }
  };
  
  return (
    <>
      <div>
        <h1 className="text-center">Dashboard Semaforos</h1>
        { msgAlet !== null ? 
          (
            <div>
              <h2>{msgAlet}</h2>
              <h2>Reiniciar Alertas</h2>
              <button onClick={() => reiniciarSemaforos('TRUE')}>Reiniciar Semaforos</button>
            </div>

          ) : 
          'No hay alertas' }
        <p className="m-2"><b>Semaforo Avenida USAC </b></p>
        <div className="bg-light mx-auto px-2 border border-2 border-primary" style={{ backgroundColor: 'white', width: "450px", height: "230px" }}>
          {dataGrafica !== null ? <LinesChart dataSets={dataGrafica} /> : 'Cargando'}
        </div>
      </div>

    </>
  )
  
}

export default App