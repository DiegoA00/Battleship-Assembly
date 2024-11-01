; Proyecto realizado por:
; Diego Enzo Javier Araujo Ortega
; Leidy Joselyn Barzola Rodriguez

.model small
.stack 100h
.data

; Constantes
ROWS equ 6
COLS equ 6

MAX_MISSILES equ 18

CARRIER_SIZE equ 5
CARRIER_CHAR equ 43h
is_sunken_carrier db 0    ; si es diferente de 0 entonces ya esta hundido

DESTROYER_SIZE equ 3
DESTROYER_CHAR equ 44h
is_sunken_destroyer db 0  ; si es diferente de 0 entonces ya esta hundido


SUBMARINE_SIZE equ 3
SUBMARINE_CHAR equ 53h
is_sunken_submarine db 0  ; si es diferente de 0 entonces ya esta hundido

SHIP_CHAR equ 7Eh

; Mensajes
newline db 0Dh, 0Ah, '$'
msg_title db 'BATALLA NAVAL$'
msg_subtitle db 'Tienes 18 misiles para destruir la flota enemiga$'
msg_start db 'Presiona ENTER para visualizar el tablero y ubicar los barcos aleatoriamente...$'
msg_turn db 'Misil 00, ingrese la celda a atacar: $'
msg_fail db '00.............Sin impacto$'
msg_succes db '00.............Impacto confirmado$'
msg_sunken_destroyer db 'Destructor hundido.$'
msg_sunken_carrier db 'Portaviones hundido.$'
msg_sunken_submarine db 'Submarino hundido.$'
msg_error db 'Coordenada invalida. Intente de nuevo.', 0Dh, 0Ah, '$'
msg_already_shot db 'Ya has disparado a esta celda. Intenta de nuevo.', 0Dh, 0Ah, '$'
msg_winner db 'Felicidades! Has ganado', 0Dh, 0Ah, '$'
msg_loser db 'Perdiste! Se terminaron los turnos', 0Dh, 0Ah, '$'
msg_restart db 'Quieres jugar de nuevo?', 0Dh, 0Ah, 'Ingresa 1 para reiniciar', 0Dh, 0Ah, 'Ingresa 0 o CTRL+E para salir', 0Dh, 0Ah, '$'


board db ROWS * COLS dup(' ')       ; tablero de 6x6 que no muestra la ubicacion de los barcos
board_ships db ROWS * COLS dup(' ') ; tablero de 6x6 con la ubicacion de los barcos
col_header db 'ABCDEF$'             ; cabecera del tablero

current_missile db 1    ; contador de misiles impactados por el jugador (turno del jugador)
input_coord db 2 dup(0) ; coordenada ingresada por el jugador
hits_required db 11     ; numero faltante de impactos para ganar


.code
.start up


menu:
    call clear_screen    
    
    show_menu:
    mov ah, 09h
    lea dx, msg_title
    int 21h
    lea dx, newline
    int 21h
    lea dx, msg_subtitle
    int 21h
    lea dx, newline
    int 21h
    lea dx, msg_start
    int 21h
    lea dx, newline
    int 21h
    
    input_start_game:
    mov ah, 01h
    int 21h
    cmp al, 05h         ; caracter de CTRL+E
    je final            ; si presiona CTRL+E sale del programa
    cmp al, 13          ; caracter ENTER
    je game             ; si presiona ENTER empieza el juego
    call clear_screen   ; si presiona otra tecla se limpia la pantalla
    jmp menu            ; y vuelve a mostrar el menu
    

game:
    call clear_board
    call clear_board_ships
    
    ; Colocacion aleatoria de los barcos
    ; Colocacion del portaviones
    mov cx, CARRIER_SIZE
    call put_carrier

    ; Colocacion del destructor
    mov cx, DESTROYER_SIZE
    call put_destroyer
    
    ; Colocacion del submarino
    mov cx, SUBMARINE_SIZE
    call put_submarine
    
    ; Inicializar contador de misiles y hits requeridos
    mov [current_missile], 1
    mov [hits_required], 11
    mov [is_sunken_carrier], 0
    mov [is_sunken_destroyer], 0
    mov [is_sunken_submarine], 0
    
;inicio turno
start_turn:
    call actualizar_msg_turno

turn_loop:
    call show_board 
    
    ; Muestra el mensaje para ingresar una coordenada        
    mov ah, 09h
    lea dx, msg_turn
    int 21h    

    ; Ingreso de coordenada

    mov ah, 01h
    int 21h
    cmp al, 05h             ; caracter de ctrl+E
    je final                ; si presiona CTRL+E sale del programa
    mov [input_coord], al   ; almacena letra
    
    int 21h
    cmp al, 05h                 ; caracter de ctrl+E
    je final                    ; si presiona CTRL+E sale del programa        
    mov [input_coord + 1], al   ; almacena numero
    
    mov ah, 09h
    lea dx, newline
    int 21h
    
    call validate_coord ; valida que la coordenada ingresada sea correcta
    jc turn_loop        ; si no es correcta se pide volver a ingresar la coordenada

    call check_hit      ; verifica si hubo un impacto y actualiza los tableros. Tambien maneja los casos en que se ingresa una coordenada ingresada anteriormente

    
    inc [current_missile]   ; incrementa el numero del turno del rival
    
    ;comparar si gano o si ya llego a los 18 misiles
    cmp [hits_required], 0  ; compara si ya  hundio todos los barcos
    je winner               ; si hundio todos los barcos termina el juego y muestra el mensaje de ganador
    
    cmp [current_missile], MAX_MISSILES+1   ; compara si ya terminaron los turnos del jugador
    jl start_turn                           ; si el jugador aun tiene turnos, se sigue al siguiente turno
    
    mov ah, 09h
    lea dx, newline
    int 21h
    
    jmp loser ; si el jugador se queda sin turnos termina el juego y muestra el mensaje de perdedor
    

winner:
    call show_board_ships   ; muestra el tablero con los intentos del jugador
    mov ah, 09h
    lea dx, msg_winner
    int 21h                 ; muestra el mensaje de ganador
    jmp restart             ; salta al menu de reinicio

loser:
    call show_board_ships   ; muestra el tablero con los intentos del jugador y los barcos que no se hundieron
    mov ah, 09h
    lea dx, msg_loser       ; muestra el mensaje de perdedor
    int 21h
    jmp restart             ; salta al menu de reinicio 

restart:
    mov ah, 09h
    lea dx, msg_restart     ; Muestra el menu de reinicio
    int 21h

    mov ah, 01h
    int 21h
    cmp al, 05h             ; caracter de CTRL+E
    je final                ; si presiona CTRL+E sale del programa

    cmp al, '1'
    je menu                 ; si ingresa '1', se vuelve al menu principal

    cmp al, '0' 
    je final                ; si ingresa '0', sale del programa

    mov ah, 09h
    lea dx, newline
    int 21h
    lea dx, newline
    int 21h
    jmp restart             ; si ingresa cualquier otro caracter, vuelve a mostrar el menu de reinicio

; Salida del programa    
final:
    mov ah, 4Ch
    int 21h

;Procedimientos o funciones

; Procedimiento para limpiar la pantalla
clear_screen proc
    mov ax, 0003h  ; AH = 00h (cambiar modo de video), AL = 03h (modo texto 80x25)
    int 10h
    ret
clear_screen endp

; Procedimiento para limpiar el tablero 
; sin los barcos con ' '
clear_board proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di    
    
    mov si, 0
    mov di, 35
    
    loop_clear_board:    
    cmp si, di
    jg end_clear_board
    
    mov [board + si], ' '
    inc si
    jmp loop_clear_board
    
    end_clear_board:
    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    ret
clear_board endp

; Procedimiento para limpiar el tablero 
; con los barcos con ' '
clear_board_ships proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di    
    
    mov si, 0
    mov di, 35
    
    loop_clear_board_ships:    
    cmp si, di
    jg end_clear_board_ships
    
    mov [board_ships + si], ' '
    inc si
    jmp loop_clear_board_ships
    
    end_clear_board_ships:
    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    ret
clear_board_ships endp


; Procedimiento para mostrar el tablero
; sin los barcos en pantalla
show_board proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; Mostrar letras de columnas
    mov ah, 02h  ; Función para imprimir un carácter
    mov dl, ' '
    int 21h
    int 21h
    
    mov si, 0
    mov cx, COLS
print_cols:
    mov dl, [col_header + si]
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop print_cols
    
    ; Nueva línea
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    ; Mostrar filas
    mov si, 0
    mov cx, ROWS
print_rows:
    push cx
    
    ; Número de fila
    mov ah, 02h
    mov dl, 7
    sub dl, cl
    add dl, '0'
    int 21h
    mov dl, ' '
    int 21h
    
    ; Contenido de las celdas
    mov cx, COLS
print_cells:
    mov dl, [board + si]
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop print_cells
    
    ; Nueva línea
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    pop cx
    loop print_rows

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_board endp


; Procedimiento para mostrar el tablero
; con los barcos en pantalla
show_board_ships proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; Mostrar letras de columnas
    mov ah, 02h  ; Función para imprimir un carácter
    mov dl, ' '
    int 21h
    int 21h
    
    mov si, 0
    mov cx, COLS
print_cols_ships:
    mov dl, [col_header + si]
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop print_cols_ships
    
    ; Nueva línea
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    ; Mostrar filas
    mov si, 0
    mov cx, ROWS
print_rows_ships:
    push cx
    
    ; Número de fila
    mov ah, 02h
    mov dl, 7
    sub dl, cl
    add dl, '0'
    int 21h
    mov dl, ' '
    int 21h
    
    ; Contenido de las celdas
    mov cx, COLS
print_cells_ships:
    mov dl, [board_ships + si]
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop print_cells_ships
    
    ; Nueva línea
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    pop cx
    loop print_rows_ships

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_board_ships endp
    

; UBICACION de barcos
put_carrier proc
    push ax
    push bx
    push cx
    push dx
    
    ; solo sirve para el barco de 5
    
    start_put_ships_5:
    call generate_random ; random en ax
    mov dx, 0000h
    mov dl, 2 ; division 2
    call get_mod ; obtiene ax%dl y lo guarda en dl
    cmp dl, 0 ; compara si es par o impar
    je put_horizontal_5
    jne put_vertical_5
    
    put_horizontal_5:
    mov dx, 0000h
    mov dl, 6 ; division 6
    call get_mod ; obtiene ax%dl y lo guarda en dl
    ;verificar si existe el espacio suficiente para el barco
    cmp dl, 0 
    je is_free_horizontal_5
    cmp dl, 1
    je is_free_horizontal_5
    jne start_put_ships_5 
    
    put_vertical_5:
    cmp al, 0
    jl start_put_ships_5 ; si es menor que 0
    cmp al, 11
    jg start_put_ships_5 ; si es mayor que 11
    
    jmp is_free_vertical_5 ; esta entra 0 y 11
    
    is_free_horizontal_5:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 4 ; indice final
    
    loop_is_free_horizontal_5:
    cmp si, di
    jg can_place_horizontal_5 ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_5 ; si no hay espacio regresa
    
    inc si
    jmp loop_is_free_horizontal_5
    
    can_place_horizontal_5:
    mov si, ax
    
    loop_can_place_horizontal_5:    
    cmp si, di
    jg end_put_ships_5
    
    mov dl, CARRIER_CHAR
    mov [board_ships + si], dl
    
    inc si
    jmp loop_can_place_horizontal_5
    
    is_free_vertical_5:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 24 ; indice final
    
    loop_is_free_vertical_5:
    cmp si, di
    jg can_place_vertical_5 ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_5 ; si no hay espacio regresa
    
    add si, 6
    jmp loop_is_free_vertical_5
    
    can_place_vertical_5:
    mov si, ax
    
    loop_can_place_vertical_5:
    cmp si, di
    jg end_put_ships_5
    
    mov dl, CARRIER_CHAR
    mov [board_ships + si], dl
    
    add si, 6
    jmp loop_can_place_vertical_5
    
    end_put_ships_5:
    
    pop ax    
    pop bx
    pop cx
    pop dx
    ret
        
put_carrier endp

put_destroyer proc
    push ax
    push bx
    push cx
    push dx
    
    ; solo sirve para el barco de 3
    
    start_put_ships_3:
    call generate_random ; random en ax
    mov dx, 0000h
    mov dl, 2 ; division 2
    call get_mod ; obtiene ax%dl y lo guarda en dl
    cmp dl, 0 ; compara si es par o impar
    je put_horizontal_3
    jne put_vertical_3
    
    put_horizontal_3:
    mov dx, 0000h
    mov dl, 6 ; division 6
    call get_mod ; obtiene ax%dl y lo guarda en dl
    ;verificar si existe el espacio suficiente para el barco
    cmp dl, 0 
    je is_free_horizontal_3
    cmp dl, 1
    je is_free_horizontal_3
    cmp dl, 2
    je is_free_horizontal_3
    cmp dl, 3
    je is_free_horizontal_3
    jne start_put_ships_3 
    
    put_vertical_3:
    cmp al, 0
    jl start_put_ships_3 ; si es menor que 0
    cmp al, 23
    jg start_put_ships_3 ; si es mayor que 23
    
    jmp is_free_vertical_3 ; esta entra 0 y 23
    
    is_free_horizontal_3:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 2 ; indice final
    
    loop_is_free_horizontal_3:
    cmp si, di
    jg can_place_horizontal_3 ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_3 ; si no hay espacio regresa
    
    inc si
    jmp loop_is_free_horizontal_3
    
    can_place_horizontal_3:
    mov si, ax
    
    loop_can_place_horizontal_3:    
    cmp si, di
    jg end_put_ships_3
    
    mov dl, DESTROYER_CHAR
    mov [board_ships + si], dl
    
    inc si
    jmp loop_can_place_horizontal_3
    
    is_free_vertical_3:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 12 ; indice final
    
    loop_is_free_vertical_3:
    cmp si, di
    jg can_place_vertical_3 ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_3 ; si no hay espacio regresa
    
    add si, 6
    jmp loop_is_free_vertical_3
    
    can_place_vertical_3:
    mov si, ax
    
    loop_can_place_vertical_3:
    cmp si, di
    jg end_put_ships_3
    
    mov dl, DESTROYER_CHAR
    mov [board_ships + si], dl
    
    add si, 6
    jmp loop_can_place_vertical_3
    
    end_put_ships_3:
    
    pop ax    
    pop bx
    pop cx
    pop dx
    ret
        
put_destroyer endp

put_submarine proc
    push ax
    push bx
    push cx
    push dx
    
    ; solo sirve para el barco de 3
    
    start_put_ships_s:
    call generate_random ; random en ax
    mov dx, 0000h
    mov dl, 2 ; division 2
    call get_mod ; obtiene ax%dl y lo guarda en dl
    cmp dl, 0 ; compara si es par o impar
    je put_horizontal_s
    jne put_vertical_s
    
    put_horizontal_s:
    mov dx, 0000h
    mov dl, 6 ; division 6
    call get_mod ; obtiene ax%dl y lo guarda en dl
    ;verificar si existe el espacio suficiente para el barco
    cmp dl, 0 
    je is_free_horizontal_s
    cmp dl, 1
    je is_free_horizontal_s
    cmp dl, 2
    je is_free_horizontal_s
    cmp dl, 3
    je is_free_horizontal_s
    jne start_put_ships_s 
    
    put_vertical_s:
    cmp al, 0
    jl start_put_ships_s ; si es menor que 0
    cmp al, 23
    jg start_put_ships_s ; si es mayor que 23
    
    jmp is_free_vertical_s ; esta entra 0 y 23
    
    is_free_horizontal_s:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 2 ; indice final
    
    loop_is_free_horizontal_s:
    cmp si, di
    jg can_place_horizontal_s ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_s ; si no hay espacio regresa
    
    inc si
    jmp loop_is_free_horizontal_s
    
    can_place_horizontal_s:
    mov si, ax
    
    loop_can_place_horizontal_s:    
    cmp si, di
    jg end_put_ships_s
    
    mov dl, SUBMARINE_CHAR
    mov [board_ships + si], dl
    
    inc si
    jmp loop_can_place_horizontal_s
    
    is_free_vertical_s:
    mov ah, 00h
    mov si, ax ; indice inicial
    mov di, ax
    add di, 12 ; indice final
    
    loop_is_free_vertical_s:
    cmp si, di
    jg can_place_vertical_s ; hay espacio en board para el barco
        
    mov dl, [board_ships + si]
    cmp dl, ' '
    jne start_put_ships_s ; si no hay espacio regresa
    
    add si, 6
    jmp loop_is_free_vertical_s
    
    can_place_vertical_s:
    mov si, ax
    
    loop_can_place_vertical_s:
    cmp si, di
    jg end_put_ships_s
    
    mov dl, SUBMARINE_CHAR
    mov [board_ships + si], dl
    
    add si, 6
    jmp loop_can_place_vertical_s
    
    end_put_ships_s:
    
    pop ax    
    pop bx
    pop cx
    pop dx
    ret
        
put_submarine endp    

; Procedimiento para actualizar el mensaje
; de ingreso de una coordenada
actualizar_msg_turno proc
    push ax
    push bx
    
    mov ax, 0000h

    mov al, [current_missile]
    mov bl, 10
    div bl  ; AL = cociente (decenas), AH = residuo (unidades)

    add al, '0'  ; Convertir decenas a ASCII
    mov [msg_turn + 6], al  ; Actualizar decenas en el mensaje

    add ah, '0'  ; Convertir unidades a ASCII
    mov [msg_turn + 7], ah  ; Actualizar unidades en el mensaje

    pop bx
    pop ax
    ret
actualizar_msg_turno endp    


; Procedimiento para validar la coordenada 
; ingresada por el usuario
validate_coord proc
    push ax
    
    ; Convierte en mayuscula las coordenadas ingresadas
    mov al, [input_coord]
    call to_upper
    mov [input_coord], al

    ; Valida que la columna ingresada sea A-F
    mov al, [input_coord]
    cmp al, 'A'
    jb invalid_coord
    cmp al, 'F'
    ja invalid_coord

    ; Valida que la fila ingresada sea 1-6
    mov al, [input_coord + 1]
    cmp al, '1'
    jb invalid_coord
    cmp al, '6'
    ja invalid_coord

    ; Caso en que la coordenada es valida
    clc  ; Limpiar carry flag (indica valido)
    pop ax
    ret

invalid_coord:
    push dx
    mov ah, 09h
    lea dx, msg_error   ; muestra el mensaje de coordenada invalida
    int 21h
    lea dx, newline
    int 21h
    pop dx

    stc  ; Establecer carry flag (indica invalido)
    pop ax
    ret
validate_coord endp



; Procedimiento para convertir un caracter a mayuscula
to_upper proc
    cmp al, 'a'
    jb done     ; Si es menor que 'a', no es minuscula
    cmp al, 'z'
    ja done     ; Si es mayor que 'z', no es minuscula
    sub al, 32  ; Convierte a mayuscula
done:
    ret
to_upper endp


; Procedimiento para generar un numero aleatorio entre
; 0 y 35, usando la hora del sistema
generate_random:
    push dx
    push cx
    
    mov ah, 00h ; obtiene hora del sistema
    int 1Ah     ; cx:dx contiene el numero de ticks del reloj desde la medianoche
    
    mov ax, dx  ; copia dx a ax
    xor dx, dx  ; limpiamos dx
    mov cx, 36  
    div cx      ; divide para 36 para obtener un numero entre 0-35
    
    mov ax, dx  ; Obtiene el numero aleatorio entre 0 y 35
    
    pop cx
    pop dx
    ret

; Procedimiento para colocar todos los barcos
place_all_ships proc
    push cx

    ; Colocar portaaviones (5 celdas)
    mov cx, CARRIER_SIZE
    ;call place_ship

    ; Colocar destructor (3 celdas)
    mov cx, DESTROYER_SIZE
    ;call place_ship

    ; Colocar submarino (3 celdas)
    mov cx, SUBMARINE_SIZE
    ;call place_ship

    pop cx
    ret
place_all_ships endp

; Procedimiento para verificar si hay impacto o no
; Tambien maneja el caso en que el usuario ingrese
; una coordenada ya impactada
; Ademas actualiza los tableros con los impactos
check_hit proc
    push ax
    push bx
    push cx
    push dx

    ; Convierte la coordenada ingresada en un indice en el tablero
    mov al, [input_coord + 1]   ; obtiene la fila (1-6)
    sub al, '1'                 ; convierte a 0-5
    mov bl, COLS                
    mul bl                      ; multiplica por 6
    
    mov cl, [input_coord]   ; obtiene la columna (A-F)
    sub cl, 'A'             ; convierte a 0-5
    add al, cl              ; obtenemos el indice en el tablero (0-35)
    
    xor ah, ah  ; limpiamos ah
    mov si, ax  ; si contiene el indice en el tablero    
    

    ; Verifica si hay un barco en esa posicion
    cmp [board_ships + si], CARRIER_CHAR
    je hit
    cmp [board_ships + si], DESTROYER_CHAR
    je hit
    cmp [board_ships + si], SUBMARINE_CHAR
    je hit
    jmp miss    ; si no hay un barco, no hay impaco

hit:
    ; Actualiza los tableros con el impacto exitoso
    mov [board + si], 'X'       ; X es impacto
    mov [board_ships + si], 'X' ; X es impacto

    ; Actualiza mensaje de impacto exitoso
    mov ax, 0000h
    mov al, [input_coord]
    mov [msg_succes], al
    mov al, [input_coord + 1]
    mov [msg_succes + 1], al

    ; Muestra mensaje de impacto exitoso
    mov ah, 09h
    lea dx, msg_succes
    int 21h
    lea dx, newline
    int 21h
    
    ; Verifica si todavia hay barcos en el tablero        
    carrier:
    cmp [is_sunken_carrier], 0
    jne destroyer
    
    ; Verifica si se ha hundido el portaviones
    ; recorriendo el tablero en busqueda de un 'C'
    sunken_carrier:
        
    mov si, 0
    mov di, 35
    
    loop_sunken_carrier:
    cmp si, di
    jg end_sunken_carrier
    
    cmp [board_ships + si], CARRIER_CHAR
    je destroyer
    inc si
    jne loop_sunken_carrier
    
    ; muestra el mensaje de que el portaviones se ha hundido
    end_sunken_carrier:
    mov ah, 09h
    lea dx, msg_sunken_carrier
    int 21h
    lea dx, newline
    int 21h
    mov [is_sunken_carrier], 1  ; cambiamos el estado para no mostrar el mensaje de nuevo
    jmp not_sunken
    
    destroyer:    
    cmp [is_sunken_destroyer], 0
    jne submarine
    
    ; Verifica si se ha hundido el destructor
    ; recorriendo el tablero en busqueda de un 'D'
    sunken_destroyer:
        
    mov si, 0
    mov di, 35
    
    loop_sunken_destroyer:
    cmp si, di
    jg end_sunken_destroyer
    
    cmp [board_ships + si], DESTROYER_CHAR
    je submarine
    inc si
    jne loop_sunken_destroyer
    
    ; muestra el mensaje de que el portaviones se ha hundido
    end_sunken_destroyer:
    mov ah, 09h
    lea dx, msg_sunken_destroyer
    int 21h
    lea dx, newline
    int 21h
    mov [is_sunken_destroyer], 1  ; cambiamos el estado para no mostrar el mensaje de nuevo
    jmp not_sunken
    
    submarine:    
    cmp [is_sunken_submarine], 0
    jne not_sunken
    
    ; Verifica si se ha hundido el submarino
    ; recorriendo el tablero en busqueda de un 'S'
    sunken_submarine:
        
    mov si, 0
    mov di, 35
    
    loop_sunken_submarine:
    cmp si, di
    jg end_sunken_submarine
    
    cmp [board_ships + si], SUBMARINE_CHAR
    je not_sunken 
    inc si
    jne loop_sunken_submarine
    
    ; muestra el mensaje de que el submarino se ha hundido
    end_sunken_submarine:
    mov ah, 09h
    lea dx, msg_sunken_submarine
    int 21h
    lea dx, newline
    int 21h
    mov [is_sunken_submarine], 1  ; cambiamos el estado para no mostrar el mensaje de nuevo
    jmp not_sunken
    
    not_sunken:     

    ; Actualiza el numero impactos para hundir todos los barcos
    dec [hits_required]
    jnz check_hit_end   ; si todavia quedan barcos, avanza al siguiente turno

    jmp winner          ; si ya se hundieron todos los barcos, el jugador gana
    
    jmp check_hit_end   ; si todavia quedan barcos, avanza al siguiente turno

miss:
    ; Verifica si ya se ha disparado a esta coordenada
    cmp [board + si], 'O'
    je already_shot
    cmp [board + si], 'X'
    je already_shot

    ; Actualiza los tableros con el impacto fallado
    mov [board + si], 'O'       ; O es fallo
    mov [board_ships + si], 'O' ; O es fallo
    

    ; Actualiza mensaje de impacto fallado
    mov ax, 0000h
    mov al, [input_coord]
    mov [msg_fail], al
    mov al, [input_coord + 1]
    mov [msg_fail + 1], al

    ; Muestra mensaje de impacto fallado
    mov ah, 09h
    lea dx, msg_fail
    int 21h
    lea dx, newline
    int 21h
    jmp check_hit_end
    
already_shot:
    ; Caso en la que se dispara a una coordenada ya impactada
    dec [current_missile]
    mov ah, 09h
    lea dx, msg_already_shot    ; muestra mensaje para que el usuario ingrese una nueva coordenada
    int 21h
    jmp check_hit_end               

check_hit_end:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_hit endp

; Procedimento para guardar el residuo en dl
; de una division ah/dl 
get_mod proc
        
        push bx
        push cx
        
        mov dh, al
        
        div dl
                
        mov dl, ah
        mov ah, 00h
        mov al, dh
        mov dh, 00h
        
        pop bx
        pop cx
        ret
        
get_mod endp