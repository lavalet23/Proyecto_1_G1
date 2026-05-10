# Manual Técnico - Tic-Tac-Toe en AArch64 Assembly

##  Índice

1. [Descripción General](#descripción-general)
2. [Requerimientos](#requerimientos)
3. [Estructura del Programa](#estructura-del-programa)
4. [Variables y Datos Globales](#variables-y-datos-globales)
5. [Funciones y Directivas](#funciones-y-directivas)

   * [`_start`](#_start)
   * [`welcome`](#welcome)
   * [`make_move`](#make_move)
   * [`draw_board`](#draw_board)
   * [`check_game_over`](#check_game_over)
   * [`player_won`](#player_won)
   * [`game_over`](#game_over)
   * [`switch_player`](#switch_player)
   * [`exit`](#exit)
6. [Casos de Victoria](#casos-de-victoria)
7. [Manejo de Errores](#manejo-de-errores)
8. [Flujo del Programa](#flujo-del-programa)
9. [Notas Finales](#notas-finales)

---

##  Descripción General

Este programa implementa el juego clásico de *Totito* utilizando el conjunto de instrucciones AArch64 en lenguaje ensamblador. El jugador elige una posición del 1 al 9 para colocar su marca (`X` o `O`) hasta que uno gane o se complete el tablero.


##  Requerimientos

* Arquitectura: ARM64 (AArch64)
* Sistema operativo: Linux
* Ensamblador: `as`
* Vinculador: `ld`
* Terminal: Capaz de leer entrada y mostrar salida estándar

---

##  Estructura del Programa

El programa se compone de:

* Sección `.text`: donde se definen las funciones ejecutables.
* Sección `.data` o `.rodata`: para almacenar cadenas de texto, tablero y marcas.
* Sección `.bss`: para definir variables como el tablero y el jugador actual.

---

##  Variables y Datos Globales

* `board`: Arreglo de 9 bytes que representa el tablero.
* `current_player`: Byte que indica si el turno es de 'X' o 'O'.
* `total_moves`: Contador de movimientos realizados.
* Cadenas: `welcome_str`, `win_str`, `gameover_str`, `invalid_str`, etc.

---

##  Funciones y Directivas

### `_start`

Punto de entrada principal. Ejecuta:

1. `welcome`
2. Bucle principal (`main_loop`): realizar jugada, dibujar tablero, verificar victoria o empate, cambiar de jugador.

---

### `welcome`

Imprime un mensaje de bienvenida usando `SYS_write`.

---

### `make_move`

Solicita al jugador que ingrese una posición (1-9). Verifica si es válida y si el espacio está disponible. Si es válido, coloca el símbolo y aumenta `total_moves`.

---

### `draw_board`

Imprime el estado actual del tablero, agregando espacios y saltos de línea después de cada fila.

---

### `check_game_over`

Verifica si el jugador actual tiene alguna de las 8 combinaciones ganadoras.

---

### `player_won`

Muestra el mensaje de victoria para el jugador actual y termina el programa.

---

### `game_over`

Se ejecuta cuando hay empate (9 movimientos sin ganador). Imprime el tablero y mensaje final.

---

### `switch_player`

Alterna entre `'X'` y `'O'`.

---

### `exit`

Finaliza la ejecución del programa con `SYS_exit`.

---

##  Casos de Victoria

El programa evalúa 8 posibles combinaciones:

* 3 horizontales:  

        X X X    - - -    - - -
        - - -    X X X    - - -
        - - -    - - -    X X X
        Caso 1   Caso 2    Caso3

* 3 verticales:

        X - -    - X -    - - X
        X - -    - X -    - - X
        X - -    - X -    - - X
        Caso 4   Caso 5    Caso 6

* 2 diagonales

        X - -    - - X    
        - X -    - X -    
        - - X    X - -    
        Caso 7   Caso 8    

---

##  Manejo de Errores

* Movimiento inválido (posición fuera de rango o ya ocupada): muestra mensaje y permite reintento.

---

##  Flujo del Programa

```plaintext
_start
 ├─> welcome
 └─> main_loop:
       ├─> make_move
       ├─> draw_board
       ├─> check_game_over
       │    └─> player_won (si hay victoria)
       ├─> switch_player
       └─> [bucle]
       └─> game_over (si hay empate)
```

---

##  Notas Finales

* Se utilizan llamadas al sistema (`SYS_write`, `SYS_read`, `SYS_exit`) para la entrada/salida estándar.
* El uso de registros está organizado para cargar y comparar valores del tablero.
* El programa no requiere librerías externas, solo ensamblador puro y llamadas del sistema Linux.

