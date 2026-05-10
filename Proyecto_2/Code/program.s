.section .data
// Constantes para syscalls
.equ SYS_EXIT, 93
.equ SYS_READ, 63
.equ SYS_WRITE, 64
.equ SYS_OPEN, 56
.equ SYS_CLOSE, 57
.equ STDIN, 0
.equ STDOUT, 1

// Mensajes del programa
header:
    .ascii "Universidad de San Carlos de Guatemala\n"
    .ascii "Facultad de Ingeniería\n"
    .ascii "Escuela de Ciencias y Sistemas\n"
    .ascii "Arquitectura de Computadores y Ensambladores 1\n"
    .ascii "Sección A\n"
    .ascii "Javier Matías - 202000896\n"
    .ascii "Grupo 1\n\n"
    .ascii "Presione ENTER para continuar...\n"
header_len = . - header

main_menu:
    .ascii "\nGrupo 1: Menú principal para calculadora básica\n\n"
    .ascii "1. Operaciones Aritméticas\n"
    .ascii "2. Operaciones Lógicas (Booleanas)\n"
    .ascii "3. Operaciones de Manipulación de Bits\n"
    .ascii "4. Operaciones Estadísticas\n"
    .ascii "5. Cálculo con memoria\n"
    .ascii "6. Finalizar calculadora\n"
    .ascii "Seleccione una opción: "
main_menu_len = . - main_menu

arithmetic_menu:
    .ascii "\nMenú Operaciones Aritméticas\n\n"
    .ascii "1. Suma\n"
    .ascii "2. Resta\n"
    .ascii "3. Multiplicación\n"
    .ascii "4. División\n"
    .ascii "5. Potencia\n"
    .ascii "6. Cambiar signo a un numero\n"
    .ascii "7. Cálculo con memoria\n"
    .ascii "8. Regresar\n"
    .ascii "Seleccione una opción: "
arithmetic_menu_len = . - arithmetic_menu

logic_menu:
    .ascii "\nMenú Operaciones Lógicas\n\n"
    .ascii "1. AND\n"
    .ascii "2. OR\n"
    .ascii "3. NOT\n"
    .ascii "4. XOR\n"
    .ascii "5. Regresar\n"
    .ascii "Seleccione una opción: "
logic_menu_len = . - logic_menu

bits_menu:
    .ascii "\nMenú Manipulación de Bits\n\n"
    .ascii "1. Desplazamientos\n"
    .ascii "2. Rotaciones\n"
    .ascii "3. Regresar\n"
    .ascii "Seleccione una opción: "
bits_menu_len = . - bits_menu

stats_menu:
    .ascii "\nMenú Operaciones Estadísticas\n\n"
    .ascii "1. Promedio\n"
    .ascii "2. Máximo\n"
    .ascii "3. Mínimo\n"
    .ascii "4. Regresar\n"
    .ascii "Seleccione una opción: "
stats_menu_len = . - stats_menu

input_prompt:
    .ascii "Ingrese la operación completa: "
input_prompt_len = . - input_prompt

result_msg:
    .ascii "Resultado: "
result_msg_len = . - result_msg

continue_msg:
    .ascii "\nPresione ENTER para continuar..."
continue_msg_len = . - continue_msg

error_msg:
    .ascii "Error: Entrada inválida\n"
error_msg_len = . - error_msg

div_zero_msg:
    .ascii "Error: No se puede dividir entre cero\n"
div_zero_msg_len = . - div_zero_msg

exit_msg:
    .ascii "\nCalculadora finalizada. ¡Hasta luego!\n"
exit_msg_len = . - exit_msg
// impl

msg_resultado: 
    .asciz "El resultado de la operacion es: "
    lenMsgResultado = .- msg_resultado



value:  .asciz "00000000000000000000"
    lenValue = .- value // Se encargara de guardar los valores a imprimir en pantalla luego de una operacion (20 Espacios)

espacio:  .asciz "  "
    lenEspacio = .- espacio

salto:  .asciz "\n"
    lenSalto = .- salto

ingresoComando:
    .asciz ":"
    lenIngresoComando = .- ingresoComando   // Unicamente se colocan 2 pts para pedir el ingreso del comando


newline:
    .ascii "\n"
newline_len = . - newline

// Buffers para entrada/salida
.bss
input:  .skip 4   // Reservamos espacio para la opción seleccionada

num:
    .space 22   // Variable encargada de guardar los parametros que ingrese el usuario

comando:
    .skip 50    // Encargado de guardar el comando que ingresa el usuario

tipo_comando: .zero 1

param1:
    .skip 8         // Reservar 8 bytes (64 bits) sin inicializar, variable que guarda un numero de 64 bits, uso general

param2:
    .skip 8         // Reservar 8 bytes (64 bits) sin inicializar, variable que guarda un numero de 64 bits, uso general

input_buffer: .space 256
number_buffer: .space 32
result_buffer: .space 32

.section .text

.macro mPrint reg, len
    MOV x0, 1
    LDR x1, =\reg
    MOV x2, \len
    MOV x8, 64
    SVC 0
.endm

// Macro para limpiar la variable value y regresarla a 20 ceros
.macro mLimpiarValue
    MOV w6, 0
    // Se define una etiqueta local
    1:
        STRB w6, [x1], 1
        SUB w7, w7, 1
        CBNZ w7, 1b
.endm

// Macro para pedirle una entrada al usuario
.macro mRead stdin, buffer, len
    MOV x0, \stdin
    LDR x1, =\buffer
    MOV x2, \len
    MOV x8, 63
    SVC 0
.endm

limpiarVariables:
    clear_loop:
        strb w26, [x25], #1    // Guardar byte 0 en la posición actual y avanzar
        subs x27, x27, #1      // Decrementar contador
        b.ne clear_loop      // Si no es cero, seguir limpiando
    RET

getComando:
    mPrint ingresoComando, lenIngresoComando
    mRead 0, comando, 50
    RET
verificarParametro:
    // Retorna en w4, el tipo de parametro
    /*
    w4=1=numero
    */
    
    LDR x10, =num   // Direccion en memoria donde se almacena el parametro
    MOV x4, 0   // x4=tipo de parametro puede ser: Numero
                // En el procedimiento, x4 tambien nos servira para llevar el control de caracteres leidos
    v_exit:
        LDRB w20, [x0], #1  // Se Carga en w20 lo que sigue del comando, se espera que ya sea algun parametro
        ADD x4, x4, 1   // Numero de caracteres leidos se aumenta
        CMP w20, #'e'             // Compara w20 con 'e'
        BNE v_analizar_numero_resta        // Si w20 != 'e', salta a evaluar el numero
        
        LDRB w20, [x0], #1
        ADD x4, x4, 1   // Numero de caracteres leidos se aumenta
        CMP w20, #'x'             // Compara w20 con 'x'
        BNE v_analizar_numero_resta        // Si w20 != 'x', salta fuera del rango (deberia de dar error)
        
        LDRB w20, [x0], #1
        ADD x4, x4, 1   // Numero de caracteres leidos se aumenta
        CMP w20, #'i'             // Compara w20 con 'i'
        BNE v_analizar_numero_resta        // Si w20 != 'i', salta fuera del rango (deberia de dar error)
        
        LDRB w20, [x0], #1
        ADD x4, x4, 1   // Numero de caracteres leidos se aumenta
        CMP w20, #'t'             // Compara w20 con 't'
        BNE v_analizar_numero_resta        // Si w20 != 't', salta fuera del rango (deberia de dar error)
        
        MOV w4, 2
        B v_fin
    v_analizar_numero_resta:
        // En este caso como se evaluo primero la palabra "exit" y ya hizo avance en el buffer
        // Se debe restar lo que leyo para que pueda leer el numero completo en caso sea numero
        SUB x0, x0, x4
        MOV x4, 0 // Se reinicia las lecturas que se estan haciendo
        MOV w22, #0              // Flag: ¿ya hubo un '-'? (0 = no, 1 = sí)
    v_analizar_numero:
        LDRB w20, [x0], #1

        CMP w20, #'-'          // Compara el carácter con ' '
        BEQ verificar_guion           // Si es igual, salta a v_retornar_numero
        CMP w20, #'0'          // Compara el valor en w20 con 0
        BLT v_retornar_numero // Si el valor es menor que 0, salta a v_retornar_numero
        CMP w20, #'9'          // Compara el valor en w20 con 0
        BGT v_retornar_numero // Si el valor es mayor que 9, salta a v_retornar_numero

        B continuar_numero
    verificar_guion:
        CMP w22, #1              // ¿Ya hubo un '-'?
        BEQ v_retornar_numero    // Si sí, error (no permitir dos guiones)

        CMP x4, #0               // ¿Es el primer carácter?
        BNE v_retornar_numero    // Si no es el primero, error

        MOV w22, #1              // Marcar que hubo un '-'
    continuar_numero:
        STRB w20, [x10], 1
        ADD x4, x4, 1   // Numero de caracteres leidos se aumenta
        B v_analizar_numero
    v_retornar_numero:
        MOV w4, 1
        B v_fin
    v_fin:
    RET
itoa:
    // params: x0 => number, x1 => buffer address
    MOV x8, 0 // contador de numeros
    MOV x3, 10 // base
    MOV w17, 1 // Control para ver si el numero es negativo
    i_negativo:
        TST x0, #0x8000000000000000
        BNE i_complemento_2
        B i_convertirAscii
    i_complemento_2:
        MVN x0, x0
        ADD x0, x0, 1
        MOV w17, 0
    i_convertirAscii:
        UDIV x16, x0, x3        // DIVISION
        MSUB x6, x16, x3, x0    // Sacar el residuo de la division
        ADD w6, w6, 48          // Sumarle 48 al residuo para que sea un numero en ascci

        // GUARDAR EN PILA
        SUB sp, sp, #8      // Reservar 16 bytes (por alineación) en la pila
        STR w6, [sp, #0]     // Almacenar el valor de w6 en la pila en la dirección apuntada por sp

        ADD x8, x8, 1   // Sumamos la cantidad de numeros leidos
        MOV x0, x16     // Movemos el resultado de la division (cociente) para x0 para la siguiente iteracion agarre el nuevo valor
        CBNZ x16, i_convertirAscii

        CBZ w17, i_agregar_signo
        B i_almacenar
    i_agregar_signo:
        MOV w6, 45
        // GUARDAR EN PILA
        SUB sp, sp, #8      // Reservar 16 bytes (por alineación) en la pila
        STR w6, [sp, #0]     // Almacenar el valor de w6 en la pila en la dirección apuntada por sp
        ADD x8, x8, 1
    i_almacenar:
        // Cargar el valor de vuelta desde la pila
        LDR w6, [sp, #0]     // Cargar el valor almacenado en la pila a w7
        STRB w6, [x1], 1
        // Limpiar el espacio de la pila
        ADD sp, sp, #8      // Recuperar los 16 bytes de la pila

        SUB x8, x8, 1   // Restamos el contador de la pila
        CBNZ x8, i_almacenar
        // B i_almacenar
    i_endConversion:
        RET
atoi:  // ascii to int
    // X12 -> DIRECCION DE MEMORIA DE LA CADENA A CONVERTIR
    mov x3, 0              // Inicializamos el número resultante en 0
    mov x21, 10             // Multiplicador
    mov x5, 0               // Guardara el caracter que se esta leyendo
    a_leerChar:
        LDRB w5, [x12], 1 // cargamos caracter por caracter a w5

        cmp w5, #45             // Verificar si es el carácter '-'
        beq a_signo_menos     // Si es '-', saltamos a "a_signo_menos"
        
        CMP w5, #'0'          // Compara el valor en w5 con 0
        BLT a_endConvertir // Si el valor es menor que 0, salta a a_endConvertir
        CMP w5, #'9'          // Compara el valor en w5 con 0
        BGT a_endConvertir // Si el valor es menor que 0, salta a a_endConvertir

        B a_seguir_conversion
    a_signo_menos:
        MOV x7, 1   // Bandera del signo pasa a 1
        B a_leerChar // Se continua leyendo

    a_seguir_conversion:
        sub w5, w5, 48         // Restar '0' (48 en ASCII) para convertir el carácter a número
        mul x3, x3, x21         // Multiplicar el número acumulado por 10 (shiftar un dígito a la izquierda)
        add x3, x3, x5         // Añadir el valor del dígito al número final

        b a_leerChar
    a_negativeNum:
        MOV x7, 0
        NEG x3, x3
    a_endConvertir:
        CMP x7, 1   
        BEQ a_negativeNum   // Si la bandera del signo esta activa, se salta a "a_negativeNum"
        STR x3, [x8] // usando 32 bits
    
    RET

parametroNumero:
    CMP w4, 01
    BEQ parametro_numero
    B retornar_parametro
    parametro_numero:
        // El numero de celda estara en w4
        ldr x12, =num
        STP x29, x30, [SP, -16]!     // Guardar x29 y x30 antes de la llamada
        BL atoi
        LDP x29, x30, [SP], 16       // Restaurar x29 y x30 después de la llamada
        B retornar_parametro
    retornar_parametro:
        RET

verificarOperacion:
    // Retorna en w4, el tipo de operacion encontrada
    MOV w4, 1 // w4=1 operaciion "+" encontrada
    CMP w20, #'+'          // Compara el carácter con '+'
    BEQ fin_verificar_intermedia           // Si es igual, termina de verificar

    MOV w4, 2 // w4=2 operaciion "-" encontrada
    CMP w20, #'-'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia           // Si es igual, termina de verificar

    MOV w4, 3 // w4=2 operaciion "-" encontrada
    CMP w20, #'*'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 4 // w4=2 operaciion "-" encontrada
    CMP w20, #'>'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 5 // w4=2 operaciion "-" encontrada
    CMP w20, #'<'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 6 // w4=2 operaciion "-" encontrada
    CMP w20, #'^'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 7 // w4=2 operaciion "-" encontrada
    CMP w20, #'!'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 8 // w4=2 operaciion "-" encontrada
    CMP w20, #'/'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 9 // w4=2 operaciion "-" encontrada
    CMP w20, #'&'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 10 // w4=2 operaciion "-" encontrada
    CMP w20, #'|'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 11 // w4=2 operaciion "-" encontrada
    CMP w20, #'~'          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 

    MOV w4, 12 // w4=2 operaciion "-" encontrada
    CMP w20, #','          // Compara el carácter con '-'
    BEQ fin_verificar_intermedia 
    
    MOV w4, 0
    B fin_verificar_intermedia
    fin_verificar_intermedia:
    RET
    
    // Retorna en w4 el tipo de operación encontrada:
    // 1 = '+', 2 = '-', 3 = '*', 4 = '>', 5 = '<'

    // x0 debe contener la dirección base del comando
    /*LDRB w3, [x0, w20, SXTW]    // w3 = carácter actual del string

    MOV w4, 1
    CMP w3, #'+'                // '+'
    BEQ fin_verificar_op

    MOV w4, 2
    CMP w3, #'-'                // '-'
    BEQ fin_verificar_op

    MOV w4, 3
    CMP w3, #'*'                // '*'
    BEQ fin_verificar_op

    MOV w4, 4
    CMP w3, #'>'                // '>'
    BEQ fin_verificar_op

    MOV w4, 5
    CMP w3, #'<'
    BEQ fin_verificar_op

    MOV w4, 0                   // No reconocida

fin_verificar_op:
    RET
    */
imprimirValue:
    // Limpiamos el valor
    LDR x1, =value // Direccion del value
    MOV w7, 20 // Largo del Buffer a limpiar
    mLimpiarValue

    LDR x1, =value
    STP x29, x30, [SP, -16]!     // Guardar x29 y x30 antes de la llamada al procedimiento
    BL itoa                     // Llamada a procedimiento ITOA
    LDP x29, x30, [SP], 16       // Restaurar x29 y x30 después de la llamada
    mPrint value, 20
    mPrint salto, lenSalto
    RET


.global _start

_start:
    // Mostrar encabezado
    mov x0, STDOUT
    ldr x1, =header
    ldr x2, =header_len
    mov x8, SYS_WRITE
    svc 0

    // Esperar ENTER
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 1
    mov x8, SYS_READ
    svc 0

    // Limpiar pantalla (simulado con nuevas líneas)
    mov x0, STDOUT
    ldr x1, =newline
    ldr x2, =newline_len
    mov x8, SYS_WRITE
    svc 0
    svc 0
    svc 0
    svc 0
    svc 0

main_loop:
    // Mostrar menú principal
    mov x0, STDOUT
    ldr x1, =main_menu
    ldr x2, =main_menu_len
    mov x8, SYS_WRITE
    svc 0

    // Leer selección
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 2
    mov x8, SYS_READ
    svc 0

    // Procesar selección
    ldrb w3, [x1]
    cmp w3, '1'
    b.eq arithmetic_menu_show
    cmp w3, '2'
    b.eq logic_menu_show
    cmp w3, '3'
    b.eq bits_menu_show
    cmp w3, '4'
    b.eq stats_menu_show
    cmp w3, '5'
    b.eq memory_calc
    cmp w3, '6'
    b.eq exit_program
    b main_loop

arithmetic_menu_show:
    // Mostrar menú aritmético
    mov x0, STDOUT
    ldr x1, =arithmetic_menu
    ldr x2, =arithmetic_menu_len
    mov x8, SYS_WRITE
    svc 0

    // Leer selección
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 2
    mov x8, SYS_READ
    svc 0

    // Procesar selección
    ldrb w3, [x1]
    cmp w3, '1'
    b.eq addition
    cmp w3, '2'
    b.eq subtraction
    cmp w3, '3'
    b.eq multiplication
    cmp w3, '4'
    b.eq division
    cmp w3, '5'
    b.eq power_loop
    cmp w3, '6'
    b.eq change_sign
    cmp w3, '7'
    b.eq memory_calc
    cmp w3, '8'
    b.eq main_loop
    b arithmetic_menu_show

// Operaciones aritméticas
addition:
    //mPrint clear_screen, lenClear
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    /*CMP w2, 1
    BEQ hacer_suma
    CMP w2, 2
    BEQ hacer_resta
    CMP w2, 3
    BEQ hacer_mul*/
    //B ingreso_comando
    CMP w2, 1
    BEQ do_suma
    bl show_error
    b wait_and_return_arithmetic

do_suma:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    ADDS x0, x9, x10
    BL imprimirValue
    //B ingreso_comando
    //b _start
    
    b wait_and_return_arithmetic

subtraction:
    
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    CMP w2, 2
    BEQ do_resta
    bl show_error
    b wait_and_return_arithmetic

do_resta:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    cmp x10, #0
    bge hacer_resta_normal         // Si b es positivo, hacemos a - b
    NEG x10, x10
    add x0, x9, x10
    BL imprimirValue
    //B ingreso_comando
    //b _start
    b wait_and_return_arithmetic
hacer_resta_normal:
    SUB x0, x9, x10
    BL imprimirValue
        //B ingreso_comando
    b wait_and_return_arithmetic

multiplication:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    cmp w2, 3
    BEQ do_mul
    bl show_error
    b wait_and_return_arithmetic

do_mul:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    mul x0, x9, x10
    BL imprimirValue
    //B ingreso_comando
    //b _start
    b wait_and_return_arithmetic

division:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    cmp w2, 8
    BEQ do_div
    bl show_error
    b wait_and_return_arithmetic

do_div:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    cmp x10, #0
    beq division_by_zero
    sdiv x0, x9, x10
    BL imprimirValue
    //B ingreso_comando
    //b _start
    b wait_and_return_arithmetic

division_by_zero:
    mov x0, STDOUT
    ldr x1, =div_zero_msg
    ldr x2, =div_zero_msg_len
    mov x8, SYS_WRITE
    svc 0
    b wait_and_return_arithmetic

power_loop:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    
        
    CMP w2, 6
    BEQ do_potencia
    bl show_error
    b wait_and_return_arithmetic
    
    //B ingreso_comando
    //b _start
    
do_potencia:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]

    MOV x0, #1              // Inicializamos el resultado = 1
    CBZ x10, power_done     // Si exponente == 0, el resultado es 1 y salimos
power_repeat:
    MUL x0, x0, x9        // resultado *= base
    SUB x10, x10, #1      // exponente--
    CBNZ x10, power_repeat

power_done:
    BL imprimirValue
    b wait_and_return_arithmetic
    

change_sign:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    
        
    CMP w2, 7
    BEQ do_negate
    bl show_error
    b wait_and_return_arithmetic

do_negate:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    // Realizar la operación de negación
    NEG x0, x9                 // Negar el valor de x9 y almacenar en x0

    // Imprimir el valor resultante
    BL imprimirValue
    B wait_and_return_arithmetic
// Operaciones lógicas
logic_menu_show:
    mov x0, STDOUT
    ldr x1, =logic_menu
    ldr x2, =logic_menu_len
    mov x8, SYS_WRITE
    svc 0

    // Leer selección
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 2
    mov x8, SYS_READ
    svc 0

    // Procesar selección
    ldrb w3, [x1]
    cmp w3, '1'
    b.eq and_operation
    cmp w3, '2'
    b.eq or_operation
    cmp w3, '3'
    b.eq not_operation
    cmp w3, '4'
    b.eq xor_operation
    cmp w3, '5'
    b.eq main_loop
    b logic_menu_show

and_operation:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    cmp w2, 9
    BEQ do_and
    bl show_error
    b wait_and_return_logic

do_and:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    and x0, x9, x10
    BL imprimirValue
    b wait_and_return_logic

or_operation:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    cmp w2, 10
    BEQ do_or
    bl show_error
    b wait_and_return_logic

do_or:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    orr x0, x9, x10
    BL imprimirValue
    b wait_and_return_logic

not_operation:
        // Limpiar buffer de comando
    LDR x25, =comando
    MOV x26, #0
    MOV x27, #50
    BL limpiarVariables

    // Leer comando (un solo número, ej: "4")
    BL getComando
    LDR x0, =comando

    // Verificar tipo de parámetro
    BL verificarParametro
    CMP w4, 2              // ¿Es retorno? Si es así, salir
    BEQ exit_program

    // Convertir a número
    LDR x8, =param1
    BL parametroNumero     // param1 ya contiene el número en memoria

    // Cargar el valor de param1
    
    LDR x9, =param1
    LDR x9, [x9]           // x9 = número ingresado
    
    // Aplicar NOT bit a bit
    MVN x0, x9             // x0 = ~x9
    
    // Imprimir resultado
    BL imprimirValue

    B wait_and_return_logic


xor_operation:
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer pamPrint msg_resultado, lenMsgResultado
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // fin ingresar_comando
    //  
    cmp w2, 11
    BEQ do_xor
    bl show_error
    b wait_and_return_logic
    
do_xor:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    eor x0, x9, x10
    BL imprimirValue
    
    b wait_and_return_logic

// Manipulación de bits
bits_menu_show:
    mov x0, STDOUT
    ldr x1, =bits_menu
    ldr x2, =bits_menu_len
    mov x8, SYS_WRITE
    svc 0

    // Leer selección
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 2
    mov x8, SYS_READ
    svc 0

    // Procesar selección
    ldrb w3, [x1]
    cmp w3, '1'
    b.eq shift_operations
    cmp w3, '2'
    b.eq rotate_operations
    cmp w3, '3'
    b.eq main_loop
    b bits_menu_show

shift_operations:
        // Limpiar buffers
    // impiar buffer: poner 0 en las 50 posiciones
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // Imprimir mensaje antes del resultado (opcional)
    //mPrint msg_resultado, lenMsgResultado
    
    // Realizar operación LSL o LSR según tipo_comando
    CMP w2, 4
    BEQ do_lsr

    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]

    LDR x10, =param2
    LDR x10, [x10]

    
    LSL x0, x9, x10     // si tipo_comando = 1 (>)
    B done

do_lsr:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]

    LDR x10, =param2
    LDR x10, [x10]
    LSR x0, x9, x10     // si tipo_comando = 2 (<)

done:
    BL imprimirValue
    B wait_and_return_bits


rotate_operations:
        // Limpiar buffers
    // impiar buffer: poner 0 en las 50 posiciones
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    // Imprimir mensaje antes del resultado (opcional)
    //mPrint msg_resultado, lenMsgResultado
    
    // Realizar operación LSL o LSR según tipo_comando
    CMP w2, 5
    BEQ do_rol

    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]

    LDR x10, =param2
    LDR x10, [x10]

    
    ROR x0, x9, x10    
    B doneR

do_rol:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]

    LDR x10, =param2
    LDR x10, [x10]
    MOV x3, #64
    SUB x4, x3, x10       // x4 = 64 - x10

    LSL x5, x9, x10       // parte izquierda
    LSR x6, x9, x4        // parte derecha

    ORR x0, x5, x6        // x0 = resultado del ROL


doneR:
    BL imprimirValue
    B wait_and_return_bits

// Operaciones estadísticas
stats_menu_show:
    mov x0, STDOUT
    ldr x1, =stats_menu
    ldr x2, =stats_menu_len
    mov x8, SYS_WRITE
    svc 0

    // Leer selección
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 2
    mov x8, SYS_READ
    svc 0

    // Procesar selección
    ldrb w3, [x1]
    cmp w3, '1'
    b.eq average_operation
    cmp w3, '2'
    b.eq max_operation
    cmp w3, '3'
    b.eq min_operation
    cmp w3, '4'
    b.eq main_loop
    b stats_menu_show

average_operation:
    // Limpiar buffers
    ldr x25, =comando         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #50          // x27 = contador
    BL limpiarVariables
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    BL getComando
    LDR x0, =comando
    // Apartir de aqui en w20 estara el recorrido del comando ingresado (11234+1230)
    // El valor de x0 no se debe perder ya que tiene la direccion de memoria del comando
    // Si en el proceso de lectura del comando se usa x0, se debera de usar la pila para no perder el valor de x0
    // Este es el primer parametro
    BL verificarParametro // Se verifica el tipo de parametro (Numero, Celda o Retorno) y guarda el valor del parametro para luego procesarlo
    CMP w4, 2
    BEQ exit_program
    LDR x8, =param1
    BL parametroNumero
    BL verificarOperacion
    ADR x5, tipo_comando
    STRB w4, [x5]
    ldr x25, =num         // x25 = dirección base del buffer
    mov x26, #0           // x26 = byte a escribir (0)
    mov x27, #22          // x27 = contador
    BL limpiarVariables
    // Este es el segundo parametro
    BL verificarParametro
    LDR x8, =param2
    BL parametroNumero
    ADR x0, tipo_comando
    LDRB w2, [x0]
    /*CMP w2, 1
    BEQ hacer_suma
    CMP w2, 2
    BEQ hacer_resta
    CMP w2, 3
    BEQ hacer_mul*/
    //B ingreso_comando
    CMP w2, 12
    BEQ do_sumaProm
    bl show_error
    b wait_and_return_arithmetic

do_sumaProm:
    mPrint msg_resultado, lenMsgResultado
    LDR x9, =param1
    LDR x9, [x9]
    LDR x10, =param2
    LDR x10, [x10]
    ADD x0, x9, x10
    //BL imprimirValue
    //B ingreso_comando
    //b _start
    
    //b wait_and_return_arithmetic
    b calcular_promedio

calcular_promedio:
    mov x7, #2
    sdiv x0, x0, x7       // promedio = suma / cantidad
    BL imprimirValue
    b wait_and_return_stats


average_loop:
    cmp x23, x21
    b.ge average_done
    ldr x24, [x20, x23, lsl 3]
    add x22, x22, x24
    add x23, x23, 1
    b average_loop
average_done:
    sdiv x19, x22, x21
    bl print_result
    b wait_and_return_stats

max_operation:
    bl get_number_list
    // x20 = puntero a números, x21 = cantidad
    ldr x19, [x20]  // primer número como máximo inicial
    mov x22, 1
max_loop:
    cmp x22, x21
    b.ge wait_and_return_stats
    ldr x23, [x20, x22, lsl 3]
    cmp x19, x23
    b.ge max_next
    mov x19, x23
max_next:
    add x22, x22, 1
    b max_loop

min_operation:
    bl get_number_list
    // x20 = puntero a números, x21 = cantidad
    ldr x19, [x20]  // primer número como mínimo inicial
    mov x22, 1
min_loop:
    cmp x22, x21
    b.ge wait_and_return_stats
    ldr x23, [x20, x22, lsl 3]
    cmp x19, x23
    b.le min_next
    mov x19, x23
min_next:
    add x22, x22, 1
    b min_loop

// Cálculo con memoria
memory_calc:
    mov x25, 0   // resultado inicial
memory_loop:
    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Verificar si es comando de salida
    ldr x3, =input_buffer
    ldr w4, [x3]
    ldr w5, =0x6F757067  // "grupo" en little endian
    cmp w4, w5
    b.ne parse_memory_operation

    // Es comando de salida, verificar si es "grupo1-exit"
    ldr w4, [x3, 4]
    ldr w5, =0x31702D6F  // "1-po" en little endian
    cmp w4, w5
    b.ne parse_memory_operation
    ldr w4, [x3, 8]
    ldr w5, =0x74697865  // "tixe" en little endian
    cmp w4, w5
    b.ne parse_memory_operation

    // Es "grupo1-exit", salir
    b main_loop

parse_memory_operation:
    // Parsear operación
    bl parse_operation
    cmp x0, 0
    b.ne memory_error

    // Realizar operación
    cmp x1, '+'
    b.eq memory_add
    cmp x1, '-'
    b.eq memory_sub
    cmp x1, '*'
    b.eq memory_mul
    cmp x1, '/'
    b.eq memory_div
    b memory_error

memory_add:
    add x25, x25, x2
    b memory_show_result

memory_sub:
    sub x25, x25, x2
    b memory_show_result

memory_mul:
    mul x25, x25, x2
    b memory_show_result

memory_div:
    cmp x2, 0
    b.eq memory_div_zero
    sdiv x25, x25, x2
    b memory_show_result

memory_div_zero:
    mov x0, STDOUT
    ldr x1, =div_zero_msg
    ldr x2, =div_zero_msg_len
    mov x8, SYS_WRITE
    svc 0
    b memory_loop

memory_show_result:
    mov x19, x25
    bl print_result
    b memory_loop

memory_error:
    mov x0, STDOUT
    ldr x1, =error_msg
    ldr x2, =error_msg_len
    mov x8, SYS_WRITE
    svc 0
    b memory_loop

show_error:
    mov x0, STDOUT
    ldr x1, =error_msg
    ldr x2, =error_msg_len
    mov x8, SYS_WRITE
    svc 0
    RET
// Funciones de utilidad
get_two_numbers:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Parsear números
    bl parse_two_numbers
    cmp x0, 0
    b.ne get_numbers_error

    ldp x29, x30, [sp], 16
    ret

get_one_number:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Parsear número
    bl parse_one_number
    cmp x0, 0
    b.ne get_numbers_error

    ldp x29, x30, [sp], 16
    ret

get_shift_operation:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Parsear operación de desplazamiento
    bl parse_shift_operation
    cmp x0, 0
    b.ne get_numbers_error

    ldp x29, x30, [sp], 16
    ret

get_rotate_operation:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Parsear operación de rotación
    bl parse_rotate_operation
    cmp x0, 0
    b.ne get_numbers_error

    ldp x29, x30, [sp], 16
    ret

get_number_list:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar prompt
    mov x0, STDOUT
    ldr x1, =input_prompt
    ldr x2, =input_prompt_len
    mov x8, SYS_WRITE
    svc 0

    // Leer entrada
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 256
    mov x8, SYS_READ
    svc 0

    // Parsear lista de números
    bl parse_number_list
    cmp x0, 0
    b.ne get_numbers_error

    ldp x29, x30, [sp], 16
    ret

get_numbers_error:
    mov x0, STDOUT
    ldr x1, =error_msg
    ldr x2, =error_msg_len
    mov x8, SYS_WRITE
    svc 0
    ldp x29, x30, [sp], 16
    ret

print_result:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Convertir resultado a cadena
    ldr x0, =result_buffer
    mov x1, x19
    bl int_to_string

    // Mostrar "Resultado: "
    mov x0, STDOUT
    ldr x1, =result_msg
    ldr x2, =result_msg_len
    mov x8, SYS_WRITE
    svc 0

    // Mostrar resultado
    mov x0, STDOUT
    ldr x1, =result_buffer
    mov x2, x0  // longitud de la cadena
    mov x8, SYS_WRITE
    svc 0

    // Mostrar nueva línea
    mov x0, STDOUT
    ldr x1, =newline
    ldr x2, =newline_len
    mov x8, SYS_WRITE
    svc 0

    ldp x29, x30, [sp], 16
    ret

wait_and_return_arithmetic:
    bl wait_enter
    b arithmetic_menu_show

wait_and_return_logic:
    bl wait_enter
    b logic_menu_show

wait_and_return_bits:
    bl wait_enter
    b bits_menu_show

wait_and_return_stats:
    bl wait_enter
    b stats_menu_show

wait_enter:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Mostrar mensaje
    mov x0, STDOUT
    ldr x1, =continue_msg
    ldr x2, =continue_msg_len
    mov x8, SYS_WRITE
    svc 0

    // Esperar ENTER
    mov x0, STDIN
    ldr x1, =input_buffer
    mov x2, 1
    mov x8, SYS_READ
    svc 0

    ldp x29, x30, [sp], 16
    ret

exit_program:
    // Mostrar mensaje de salida
    mov x0, STDOUT
    ldr x1, =exit_msg
    ldr x2, =exit_msg_len
    mov x8, SYS_WRITE
    svc 0

    // Salir
    mov x0, 0
    mov x8, SYS_EXIT
    svc 0

// Funciones de parseo
parse_two_numbers:
    // Implementación de parseo de dos números
    // Retorna x0=0 (éxito), x1=operador, x20=num1, x21=num2
    // Para simplificar, asumimos formato "num1opnum2"
    ret

parse_one_number:
    // Implementación de parseo de un número
    // Retorna x0=0 (éxito), x20=num
    ret

parse_shift_operation:
    // Implementación de parseo de operación de desplazamiento
    // Retorna x0=0 (éxito), x20=num, x21=cantidad, x22=dirección (0=izq, 1=der)
    ret

parse_rotate_operation:
    // Implementación de parseo de operación de rotación
    // Retorna x0=0 (éxito), x20=num, x21=cantidad, x22=dirección (0=izq, 1=der)
    ret

parse_number_list:
    // Implementación de parseo de lista de números
    // Retorna x0=0 (éxito), x20=puntero a números, x21=cantidad
    ret

parse_operation:
    // Implementación de parseo de operación general
    // Retorna x0=0 (éxito), x1=operador, x2=operando
    ret

// Funciones de conversión
int_to_string:
    // Implementación de conversión de entero a cadena
    ret

string_to_int:
    // Implementación de conversión de cadena a entero
    ret