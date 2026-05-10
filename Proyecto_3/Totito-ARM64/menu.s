.arch armv8-a

// System calls [linux/include/uapi/asm-generic/unistd.h]
.equ    SYS_read,   63 // read
.equ    SYS_write,  64 // write
.equ    SYS_exit,   93 // exit

// File descriptors
.equ    stdin,      0 
.equ    stdout,     1

// Gameplay
.equ    x_mark,     'X' // Player 1
.equ    o_mark,     'O' // Player 2

.data //.data para datos dinamicos
    board:          .byte   '-', '-', '-', '-', '-', '-', '-', '-', '-' // En total 9 espacios
    current_player: .byte   x_mark
    input_position: .byte   0, 0
    total_moves:    .byte   0
    space:          .byte   ' '
    new_line:       .byte   '\n'
    
    //Archivo de carga y guardado -----------------
    game_buffer:      .skip 10     // 9 caracteres + posible terminador


.section .rodata //.rodata para datos estaticos
    //Archivo de carga y guardado -----------------
    file_name:        
        .asciz "juego-g4.txt"         // nombre del archivo a cargar
    file_name_len = . - file_name

    //Error al abrir el archivo
    load_error_str:     
        .ascii  ">>> Error: No se pudo cargar el juego.\n"
    load_error_len = . - load_error_str

    //Error al guardar el archivo
    save_error_str:     
        .ascii  ">>> Error: No se pudo guardar el juego.\n"
    save_error_len = . - save_error_str

    //Mensajes ------------------------------------
    //Mensaje de confirmación de guardado
    save_success_str:     
        .ascii  ">>> Juego guardado exitosamente en 'juego-g4.txt'\n"
    save_success_len = . - save_success_str

    //Mensajes carga del juego
    msg_load_game:    
        .asciz "\nCargar juego\n"
    msg_file_not_found: 
        .asciz "No se encontró el archivo.\n"
    msg_read_error:   
        .asciz "Error al leer el archivo.\n"
    msg_game_loaded:  
        .asciz "Juego cargado exitosamente.\n"

    // Mensaje de opciones del menú principal
    menu_str:
        .asciz "\033[33m\n\n**Menú principal**\n1. Jugar\n2. Cargar juego\n3. Cambiar colores\n4. Salir\nOpción: "

    menu_len = . - menu_str

    //Para agregar color: 
    // \033[33m = amarillo
    // \033[36m = cian
    // \033[0m = resetear color
    // \033[31m = rojo
    // \033[32m = verde
    // \033[34m = azul

    // Mensajes de bienvenida
    welcome_str:     .ascii  "### Totito-ARM64 ###\n ===================== \n\033[36mUniversidad de San Carlos de Guatemala \nFacultad de Ingeniería \nArquitectura de Computadores y Ensambladores 1 \nSección A \nGrupo4\033[0m \nIntegrantes:\nRocio Samai Lopez Vasquez - 201709035 \nKeitlyn Valentina Tunchez Castañeda - 202201139 \nJosué Rodrigo Alvarado Castro - 202200382 \nAlvaro Gabriel Ramirez Alvarez - 202112674 \nJavier Alejandro Matías Guarcas - 202000896 \n ====================="
    welcome_str_len = . - welcome_str

    // Mensajes de opciones escogidas del menú
    start_game_str:     .ascii  "\n>>> Iniciando juego...\n\nCoordinadas:\n\n1 2 3\n4 5 6\n7 8 9\n\n"
    start_game_str_len = . - start_game_str

    load_game_str:     .ascii  "\n>>> Cargando juego...\n"
    load_game_str_len = . - load_game_str

    change_colors_str:     .ascii  "\n>>> Cambiando colores...\n"
    change_colors_str_len = . - change_colors_str

    exit_str:     .ascii  "\n>>> Saliendo del juego...\n"
    exit_str_len = . - exit_str

    // Mensajes de opciones de juego
    enter_position_str:     .ascii  "\nRealizar movimiento (1-9): "
    enter_position_str_len = . - enter_position_str

    invalid_str:     .ascii  ">>> Movimiento inválido, intenta de nuevo.\n"
    invalid_str_len = . - invalid_str

    win_str:     .ascii  "\n>>> Ganador:  "
    win_str_len = . - win_str

    gameover_str:     .ascii  "\n>>> Fin del Juego: Empate!\n"
    gameover_str_len = . - gameover_str


.section .bss
        .align 4
    input_option: .skip 2   // Para almacenar la entrada del usuario (1 byte + \n)

    // Variables del juego para carga y guardado de la partida
    board_var:            .skip 9        // tablero 3x3
    current_player_var:   .skip 1        // jugador actual ('X' o 'O')
    total_moves_var:      .skip 1        // número de jugadas realizadas



.section .text
.globl _start

_start:
    bl welcome          // Mostrar el mensaje de bienvenida

    .main_loop:
    bl show_menu           // Mostrar el menú
    // En este punto, el valor de la opción está en w2

    cmp w2, #1
    beq start_game

    cmp w2, #2
    beq load_game

    cmp w2, #3
    beq change_colors

    cmp w2, #4
    beq exit

    /*
    //Si no es ninguna válida, repetir el menú
    b show_menu 
    */
    

    b  .main_loop
    

welcome:
    // Imprimir el mensaje de bienvenida
    mov     x0, #1              // stdout
    ldr     x1, =welcome_str    // dirección del string de bienvenida
    mov     x2, welcome_str_len  // longitud del mensaje
    mov     x8, #64             // syscall write
    svc     #0

    ret

/* show_load_error:
    mov x0, stdout
    ldr x1, =load_error_str
    mov x2, #34       // o calcula la longitud exacta
    mov x8, SYS_write
    svc #0
    ret
 */

// Mostrar error si no se pudo cargar
show_load_error:
    mov     x0, #1                    // stdout
    ldr     x1, =load_error_str
    mov     x2, #38                   // longitud del mensaje
    mov     x8, #64                   // syscall: write
    svc     #0
    ret

// Mostrar error si no se pudo guardar
show_save_error:
    mov     x0, #1                // stdout
    ldr     x1, =save_error_str
    mov     x2, #39
    mov     x8, #64               // syscall: write
    svc     #0
    ret

show_menu:
    // Imprimir el menú
    mov     x0, #1              // stdout
    ldr     x1, =menu_str       // dirección del string del menú
    mov     x2, menu_len        // longitud del mensaje
    mov     x8, #64             // syscall write
    svc     #0                  // Llamada al sistema para escribir

    // Leer la opción del usuario
    mov     x0, #0              // stdin
    ldr     x1, =input_option   // dirección donde guardar la entrada
    mov     x2, #2              // leer 2 bytes (incluye \n)
    mov     x8, #63             // syscall read
    svc     #0

    // Convertir de ASCII a valor numérico (opcional para comparar luego)
    ldr     x1, =input_option
    ldrb    w2, [x1]            // w2 = carácter leído
    sub     w2, w2, #'0'        // Convertir '1'->1, '2'->2, etc.

    ret

/*
----------------------------------
            JUEGO
----------------------------------
 */

    start_game: 
        // Aquí iría la lógica del juego
        // Mensaje de inicio
        mov     x0, #1              // stdout
        ldr     x1, =start_game_str // dirección del string de inicio
        mov     x2, start_game_str_len  // longitud del mensaje
        mov     x8, #64             // syscall write
        svc     #0

        // Juego
        .loop_game:
        bl      make_move
        bl      draw_board
        bl      check_game_over
        bl      switch_player
        b       .loop_game  // Loop back to the start of the game

        // Aquí iría la lógica para hacer un movimiento
        check_game_over:
        ldr     x1, =current_player
        ldrb    w2, [x1]

        /* Load 3x3 board into the registers:

            w10  w11  w12

            w13  w14  w15

            w16  w17  w18
            
        */
        ldr     x9, =board
        ldrb    w10, [x9, #0]
        ldrb    w11, [x9, #1]
        ldrb    w12, [x9, #2]
        ldrb    w13, [x9, #3]
        ldrb    w14, [x9, #4]
        ldrb    w15, [x9, #5]
        ldrb    w16, [x9, #6]
        ldrb    w17, [x9, #7]
        ldrb    w18, [x9, #8]

        /*
        [ w10 ][ w11 ][ w12 ]  ← (0 1 2)
        [ w13 ][ w14 ][ w15 ]  ← (3 4 5)
        [ w16 ][ w17 ][ w18 ]  ← (6 7 8)

        */

        .win_case_1:
        /*
            X X X
            - - -
            - - -
        */
        cmp     w10, w2  // w10 = board[0], w2 = current_player
        bne     .win_case_2
        cmp     w11, w2 // w11 = board[1], w2 = current_player
        bne     .win_case_2
        cmp     w12, w2 // w12 = board[2], w2 = current_player
        bne     .win_case_2
        b       player_won

        .win_case_2:
        /*
            - - -
            X X X
            - - -
        */
        cmp     w13, w2
        bne     .win_case_3
        cmp     w14, w2
        bne     .win_case_3
        cmp     w15, w2
        bne     .win_case_3
        b       player_won

        .win_case_3:
        /*
            - - -
            - - -
            X X X
        */
        cmp     w16, w2
        bne     .win_case_4
        cmp     w17, w2
        bne     .win_case_4
        cmp     w18, w2
        bne     .win_case_4
        b       player_won

        .win_case_4:
        /*
            X - -
            X - -
            X - -
        */
        cmp     w10, w2
        bne     .win_case_5
        cmp     w13, w2
        bne     .win_case_5
        cmp     w16, w2
        bne     .win_case_5
        b       player_won

        .win_case_5:
        /*
            - X -
            - X -
            - X -
        */
        cmp     w11, w2
        bne     .win_case_6
        cmp     w14, w2
        bne     .win_case_6
        cmp     w17, w2
        bne     .win_case_6
        b       player_won

        .win_case_6:
        /*
            - - X
            - - X
            - - X
        */
        cmp     w12, w2
        bne     .win_case_7
        cmp     w15, w2
        bne     .win_case_7
        cmp     w18, w2
        bne     .win_case_7
        b       player_won

        .win_case_7:
        /*
            X - -
            - X -
            - - X
        */
        cmp     w10, w2
        bne     .win_case_8
        cmp     w14, w2
        bne     .win_case_8
        cmp     w18, w2
        bne     .win_case_8
        b       player_won

        .win_case_8:
        /*
            - - X
            - X -
            X - -
        */
        cmp     w12, w2
        bne     .return
        cmp     w14, w2
        bne     .return
        cmp     w16, w2
        bne     .return
        b       player_won

        .return:
        ret


    player_won:
        mov     x0, stdout
        ldr     x1, =win_str
        mov     x2, win_str_len
        mov     x8, SYS_write
        svc     #0

        mov     x0, stdout
        ldr     x1, =current_player
        mov     x2, #1
        mov     x8, SYS_write
        svc     #0

        mov     x0, stdout
        ldr     x1, =new_line
        mov     x2, #1
        mov     x8, SYS_write
        svc     #0

        // Returns to the menu
        b       .main_loop

    game_over:
        bl      draw_board
        
        mov     x0, stdout
        ldr     x1, =gameover_str
        mov     x2, gameover_str_len
        mov     x8, SYS_write
        svc     #0

        // Return to the menu
        b       .main_loop


    draw_board:
        mov     x9, #0 // counter

        .loop: 
        cmp     x9, #9
        bge     .end_loop

        mov     x0, stdout
        adr     x1, board
        add     x1, x1, x9
        mov     x2, #1
        mov     x8, SYS_write
        svc     #0

        adr     x1, space
        svc     #0

        cmp     x9, #2
        beq     .new_line
        cmp     x9, #5
        beq     .new_line
        cmp     x9, #8
        beq     .new_line
        b       .skip_print

        .new_line:
        mov     x0, stdout
        ldr     x1, =new_line
        mov     x2, #1
        mov     x8, SYS_write
        svc     #0

        .skip_print:
        add     x9, x9, #1
        b       .loop

        .end_loop:
        ret


    make_move:
        mov     x0, stdout
        ldr     x1, =enter_position_str
        mov     x2, enter_position_str_len
        mov     x8, SYS_write
        svc     #0

        mov     x0, stdin
        ldr     x1, =input_position
        mov     x2, #2
        mov     x8, SYS_read
        svc     #0

        mov     x13, x1
        ldrb    w14, [x13]
        sub     w14, w14, '1' // ASCII offset, now "1" = 0x01, "9" = 0x09

        // Check input is valid (1-9)
        cmp     w14, #0
        b.lt    .invalid_move
        cmp     w14, #9
        b.gt    .invalid_move

        ldr     x10, =board
        ldr     x11, =current_player
        ldrb    w12, [x11]

        // Check the desired slot is empty
        ldrb    w13, [x10, x14]
        cmp     x13, '-'
        bne     .invalid_move
        strb    w12, [x10, x14]

        // Increment total_moves
        ldr     x14, =total_moves
        ldrb    w15, [x14]
        add     w15, w15, #1
        strb    w15, [x14]

        // Check for draw (game over)
        cmp     w15, #9
        b.eq    game_over

        ret

        .invalid_move:
        mov     x0, stdout
        ldr     x1, =invalid_str
        mov     x2, invalid_str_len
        mov     x8, SYS_write
        svc     #0

        b       make_move


    switch_player:
        ldr     x11, =current_player
        ldrb    w12, [x11]

        cmp     w12, x_mark
        beq     .select_player_2
        bne     .select_player_1

        .select_player_1:
        mov     w12, x_mark
        strb    w12, [x11]
        ret

        .select_player_2:
        mov     w12, o_mark
        strb    w12, [x11]
        ret

/* 
    exit_game:
        mov     x0, #0 // EXIT_SUCCESS
        mov     x8, SYS_exit
        svc     #0
        ret
*/



/*  -----------------------------------------------
            CARGA DEL JUEGO
    -----------------------------------------------

// Abrir archivo en modo lectura
    mov x0, file_name      // Nombre del archivo
    mov x1, O_RDONLY       // O_RDONLY = 0 (Modo solo lectura)
    mov x2, 0              // Sin permisos adicionales
    mov x8, 56             // syscall open
    svc 0                  // llamada al sistema

    // Verificar si el archivo se abrió correctamente
    cbz x0, load_error     // Si x0 es 0, hubo un error al abrir

    // Leer el tablero
    mov x0, board
    mov x1, 9
    mov x8, 65             // syscall read
    svc 0                  // llamada al sistema

    // Leer el jugador actual
    mov x0, current_player
    mov x1, 1
    mov x8, 65             // syscall read
    svc 0                  // llamada al sistema

    // Leer el número de movimientos
    mov x0, total_moves
    mov x1, 1
    mov x8, 65             // syscall read
    svc 0                  // llamada al sistema

    // Cerrar el archivo
    mov x8, 57             // syscall close
    svc 0                  // llamada al sistema

    // Imprimir mensaje de éxito
    mov x0, msg_game_loaded
    bl print_string
    ret

load_error:
    mov x0, load_error_str
    bl print_string
    ret

/*
------------------------------------------------
        GUARDADO DEL JUEGO
------------------------------------------------

save_game:
    // Abrir archivo en modo escritura (crea archivo si no existe)
    mov x0, file_name      // Nombre del archivo
    mov x1, O_RDWR         // O_RDWR = 2 (Modo lectura-escritura)
    mov x2, S_IRUSR | S_IWUSR // Permiso de lectura y escritura
    mov x8, 56             // syscall open
    svc 0                  // llamada al sistema

    // Verificar si el archivo se abrió correctamente
    cbz x0, save_error     // Si x0 es 0, hubo un error al abrir

    // Guardar el tablero
    mov x0, board
    mov x1, 9
    mov x8, 64             // syscall write
    svc 0                  // llamada al sistema

    // Guardar el jugador actual
    mov x0, current_player
    mov x1, 1
    mov x8, 64             // syscall write
    svc 0                  // llamada al sistema

    // Guardar el número de movimientos
    mov x0, total_moves
    mov x1, 1
    mov x8, 64             // syscall write
    svc 0                  // llamada al sistema

    // Cerrar el archivo
    mov x8, 57             // syscall close
    svc 0                  // llamada al sistema

    // Imprimir mensaje de éxito
    mov x0, save_success_str
    bl print_string
    ret

save_error:
    mov x0, save_error_str
    bl print_string
    ret

/*
------------------------------------------------
        CAMBIO DE COLORES
------------------------------------------------
 */
change_colors:
    // Aquí iría la lógica para cambiar colores
    // Por ahora solo vamos a imprimir un mensaje de cambio de colores
    mov     x0, #1              // stdout
    ldr     x1, =change_colors_str  // dirección del string de cambio de colores
    mov     x2, change_colors_str_len  // longitud del mensaje
    mov     x8, #64             // syscall write
    svc     #0

    ret

load_game:
    // Aquí iría la lógica para cambiar colores
    // Por ahora solo vamos a imprimir un mensaje de cambio de colores
    mov     x0, #1              // stdout
    ldr     x1, =load_game_str  // dirección del string de cambio de colores
    mov     x2, load_game_str_len  // longitud del mensaje
    mov     x8, #64             // syscall write
    svc     #0

    ret

exit:
    // Aquí iría la lógica para salir del juego
    // Por ahora solo vamos a imprimir un mensaje de salida
    mov     x0, #1              // stdout
    ldr     x1, =exit_str       // dirección del string de salida
    mov     x2, exit_str_len    // longitud del mensaje
    mov     x8, #64             // syscall write
    svc     #0

    // Salir del programa
    mov     x0, #0              // código de salida
    mov     x8, #93             // syscall exit
    svc     #0


    // Código de salida (opcional)  
/*
    mov     x0, #0 // EXIT_SUCCESS
    mov     x8, SYS_exit
    svc     #0
    ret
    */