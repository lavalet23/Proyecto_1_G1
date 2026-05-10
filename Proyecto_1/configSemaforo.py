import RPi.GPIO as GPIO
import paho.mqtt.client as paho
import threading
import time

from paho import mqtt

from send_to_mongo import connect_to_mongo, registrar_densidad

# Topicos
TOPIC_ALERT_SEMAFORO1 = "arqui1/rasp-1/alert/"  # Tema al que publicar los estados
TOPIC_ALERT_SEMAFORO2 = "arqui1/rasp-2/alert/"  # Tema al que publicar los estados
TOPIC_ALERT_SEMAFORO3 = "arqui1/rasp-3/alert/"  # Tema al que publicar los estados
TOPIC_REINICIAR_SEMAFOROS = 'arqui1/rasp-reiniciar' # Tema para suscribirse al reiniciar semaforos
CLIENT_ID = "raspberry_pi_control"

collection = connect_to_mongo() # coleccion de densidad_vehicular

# Configuración de los pines GPIO
GPIO.setmode(GPIO.BCM)

# Pines de los botones
boton_stop_pin1 = 2
boton_stop_pin2 = 3
boton_stop_pin3 = 4

# Pines de los semáforos
sensor_pin = 18

# Pines LED's RGB
semaforo1_red_pin = 17
semaforo1_green_pin = 27
semaforo2_red_pin = 21
semaforo2_green_pin = 20
semaforo3_red_pin = 26
semaforo3_green_pin = 19

# Configuración de pines como salida
GPIO.setup(semaforo1_red_pin, GPIO.OUT)
GPIO.setup(semaforo1_green_pin, GPIO.OUT)
GPIO.setup(semaforo2_red_pin, GPIO.OUT)
GPIO.setup(semaforo2_green_pin, GPIO.OUT)
GPIO.setup(semaforo3_red_pin, GPIO.OUT)
GPIO.setup(semaforo3_green_pin, GPIO.OUT)

# Configurar el pin del sensor como entrada
GPIO.setup(sensor_pin, GPIO.IN)

# Configurar los pines de los botones como entrada con pull-down
GPIO.setup(boton_stop_pin1, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(boton_stop_pin3, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(boton_stop_pin2, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Variables de control
stop_event = threading.Event() # Evento para poder manejar el ciclo de los semaforos parar/reiniciar
restart_cycle = False # Variable para reiniciar el ciclo del semaforo

# Configurar el PWM en cada pin con frecuencia de 1000Hz
# El PWM sirve para modular la intensidad de las luces en este caso
# es una técnica que se utiliza para controlar la cantidad de energía entregada a una carga mediante la variación del ancho de los pulsos de una señal digital.
pwm1_red = GPIO.PWM(semaforo1_red_pin, 1000)
pwm1_green = GPIO.PWM(semaforo1_green_pin, 1000)
pwm2_red = GPIO.PWM(semaforo2_red_pin, 1000)
pwm2_green = GPIO.PWM(semaforo2_green_pin, 1000)
pwm3_red = GPIO.PWM(semaforo3_red_pin, 1000)
pwm3_green = GPIO.PWM(semaforo3_green_pin, 1000)

# Iniciar PWM apagado
pwm1_red.start(0)
pwm1_green.start(0)
pwm2_red.start(0)
pwm2_green.start(0)
pwm3_red.start(0)
pwm3_green.start(0)

# Función para cambiar los colores con PWM
def set_color_pwm(pwm_red, pwm_green, red, green):
    pwm_red.ChangeDutyCycle(red) # Ciclo de trabajo duty cycle
    pwm_green.ChangeDutyCycle(green) # Ciclo de trabajo duty cycle

# Función para detener el ciclo y poner todos los semáforos en rojo
# parametro channel se envia por defecto, y es el pin desde donde se activo
def stop_semaforos(channel):
    if channel == 2:
        client.publish(TOPIC_ALERT_SEMAFORO1, 'ALERT') # Enviar alerta al topico conrrespondiente
    if channel == 3:
        client.publish(TOPIC_ALERT_SEMAFORO2, 'ALERT') # Enviar alerta al topico conrrespondiente
    elif channel == 4:
        client.publish(TOPIC_ALERT_SEMAFORO3, 'ALERT') # Enviar alerta al topico conrrespondiente

    stop_event.set() # Cambia el estado del evento a TRUE
    print("Ciclo detenido: Todos los semáforos en rojo")
    # Semaforos en rojo
    set_color_pwm(pwm1_red, pwm1_green, 100, 0)
    set_color_pwm(pwm2_red, pwm2_green, 100, 0)
    set_color_pwm(pwm3_red, pwm3_green, 100, 0)

# Función para reiniciar el ciclo
def restart_semaforos_broker():
    global restart_cycle # Variable global
    stop_event.clear() # Cambia el estado del Event a "desactivado"
    restart_cycle = True
    print("Reiniciando ciclo de semáforos...")

# Función para reiniciar el ciclo
def restart_semaforos(channel):
    global restart_cycle # Variable global
    stop_event.clear() # Cambia el estado del Event a "desactivado"
    restart_cycle = True
    print("Reiniciando ciclo de semáforos...")

# Asociar botones con eventos
# pinbtn, flanco que detecta, funcion a ejecutar, tiempo para evitar rebote milisegundos
GPIO.add_event_detect(boton_stop_pin1, GPIO.RISING, callback=stop_semaforos, bouncetime=300)
GPIO.add_event_detect(boton_stop_pin2, GPIO.RISING, callback=stop_semaforos, bouncetime=300)
GPIO.add_event_detect(boton_stop_pin3, GPIO.RISING, callback=restart_semaforos, bouncetime=300)

# Función para el ciclo de semáforos con interrupciones
def ciclo_semaforos():
    global restart_cycle
    while True:
        if stop_event.is_set(): # Si el evento esta en true, se queda aqui y no ejecuta nada mas
            time.sleep(1)
            continue

        if restart_cycle: # Creo que esta demás
            restart_cycle = False

        sensor_densidad75 = GPIO.input(sensor_pin) # Sensor que detecta el 75% de densidad del trafico
        tiempo_verde_sem1 = 60 if not sensor_densidad75 else 10 # 60 segundos para el 75% y para el resto 10 segundos

        # Ciclo de semáforos con interrupciones
        def wait_with_interrupt(seconds):
            start_time = time.time() #  obtiene el tiempo actual en segundos
            while time.time() - start_time < seconds: # sigue ejecutándose mientras el tiempo transcurrido desde start_time sea menor que el valor de seconds
                if stop_event.is_set(): # Si se activa alerta entra aqui
                    return # sale del ciclo

        print("Caso 1: Semáforo 1 verde, 2 y 3 rojo")
        set_color_pwm(pwm1_red, pwm1_green, 0, 100)
        set_color_pwm(pwm2_red, pwm2_green, 100, 0)
        set_color_pwm(pwm3_red, pwm3_green, 100, 0)
        wait_with_interrupt(tiempo_verde_sem1)

        set_color_pwm(pwm1_red, pwm1_green, 50, 50)
        wait_with_interrupt(5)

        print("Todos rojos")
        set_color_pwm(pwm1_red, pwm1_green, 100, 0)
        set_color_pwm(pwm2_red, pwm2_green, 100, 0)
        set_color_pwm(pwm3_red, pwm3_green, 100, 0)
        wait_with_interrupt(3)

        print("Caso 2: Semáforo 2 verde, 1 y 3 rojo")
        set_color_pwm(pwm1_red, pwm1_green, 100, 0)
        set_color_pwm(pwm2_red, pwm2_green, 0, 100)
        set_color_pwm(pwm3_red, pwm3_green, 100, 0)
        wait_with_interrupt(10)

        set_color_pwm(pwm2_red, pwm2_green, 50, 50)
        wait_with_interrupt(5)

        print("Todos rojos")
        set_color_pwm(pwm1_red, pwm1_green, 100, 0)
        set_color_pwm(pwm2_red, pwm2_green, 100, 0)
        set_color_pwm(pwm3_red, pwm3_green, 100, 0)
        wait_with_interrupt(3)

        print("Caso 3: Semáforo 3 verde, 1 y 2 rojo")
        set_color_pwm(pwm1_red, pwm1_green, 100, 0)
        set_color_pwm(pwm2_red, pwm2_green, 100, 0)
        set_color_pwm(pwm3_red, pwm3_green, 0, 100)
        wait_with_interrupt(10)

        set_color_pwm(pwm3_red, pwm3_green, 50, 50)
        wait_with_interrupt(5)

        print("Todos rojos")
        set_color_pwm(pwm1_red, pwm1_green, 100, 0)
        set_color_pwm(pwm2_red, pwm2_green, 100, 0)
        set_color_pwm(pwm3_red, pwm3_green, 100, 0)
        wait_with_interrupt(3)


# Función para registrar la densidad cada 10 minutos
def registrar_densidad_periodicamente():
    while True:
        time.sleep(15)  # Espera 10 minutos (600 segundos)
        lane_data = [] # Arreglo para guardar info de todos los semaforos y carriles

        # Semaforo 1
        sensor_densidad75 = GPIO.input(sensor_pin)  # Leer el valor del sensor
        data_line1 = {
            "lane_id": 1,
            "density": 75 if not sensor_densidad75 else 25
        }

        # Semaforo 2
        data_line2 = {
            "lane_id": 2,
            "density": 25
        }

        # Semaforo 3
        data_line3 = {
            "lane_id": 3,
            "density": 75
        }

        lane_data.append(data_line1)
        lane_data.append(data_line2)
        lane_data.append(data_line3)
        # registrar_densidad(collection, "Avenida USAC", lane_data)  # Llamar la función para registrar los datos


# Iniciar el hilo para registrar los datos en MongoDB cada 10 minutos
thread_registro = threading.Thread(target=registrar_densidad_periodicamente)
thread_registro.daemon = True # Esta línea establece que el hilo debe ser un hilo daemon.
thread_registro.start()

# Función que se llama cuando el cliente se conecta al broker
def on_connect(client, userdata, flags, rc, properties=None):
    print(f"Conectado con resultado {rc}")
    client.subscribe(TOPIC_REINICIAR_SEMAFOROS, qos=1)

# Función que se llama cuando se recibe un mensaje MQTT
def on_message(client, userdata, msg):
    print(f"Mensaje recibido en el tema {msg.topic}: {msg.payload.decode()}")

    # Control de reinicio de los semaforos
    if msg.topic == TOPIC_REINICIAR_SEMAFOROS:
        if msg.payload.decode() == "TRUE":
            restart_semaforos_broker()
  
# Conexion hacia HiveMQ
client = paho.Client(client_id=CLIENT_ID, userdata=None, protocol=paho.MQTTv5)
client.on_connect = on_connect # Cuando se conecta
client.on_message = on_message # Cuando recibe un mensaje de las suscripciones

# Habilitar TLS para conexión segura
client.tls_set(tls_version=mqtt.client.ssl.PROTOCOL_TLS)
# Configurar las credenciales para HiveMQ Cloud
client.username_pw_set("Josue", "Usac2025") # Colocar sus datos
# Conectar a HiveMQ Cloud
client.connect("ec99a16a62004993833c6f8de56a05b7.s1.eu.hivemq.cloud:8883", 8883) # Colocar su url del cluster en HiveMQ

# Iniciar el bucle de comunicación MQTT
client.loop_start()

# Llamada principal al ciclo de semáforos
try:
    while True:
        ciclo_semaforos()
except KeyboardInterrupt:
    pass
finally:
    # Apagar semáforos antes de salir
    set_color_pwm(pwm1_red, pwm1_green, 0, 0)
    set_color_pwm(pwm2_red, pwm2_green, 0, 0)
    set_color_pwm(pwm3_red, pwm3_green, 0, 0)
    pwm1_red.stop()
    pwm1_green.stop()
    pwm2_red.stop()
    pwm2_green.stop()
    pwm3_red.stop()
    pwm3_green.stop()
    GPIO.cleanup()