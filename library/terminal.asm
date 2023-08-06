%include "./library/global.asm"

print_string:
    .loop_start:
        mov al,[si]
        cmp al , 0
        je .loop_end
        

        mov ah ,0x0e ;Teletype Mode
        mov bx,text_color
        int 0x10

        inc si
        jmp .loop_start
    .loop_end:
ret

print_newline:
        mov ah ,0x0e ;Teletype Mode
        mov al,10
        mov bx,text_color
        int 0x10

        mov al,13
        mov bx,text_color
        int 0x10
ret

get_key:
    pusha
    mov ah,0
    int 0x16
    mov [key_press_char],al
    mov [key_press_scancode],ah
    popa
ret




read_input:
    pusha
    mov bx,buffer
    mov si,0
    .loop:

    ;mov ah,0x00 ; wait for input
    ;int 0x16 ;get input
    call get_key
    ;left arrow 4B
    ;right arrow 4D
    cmp byte [key_press_scancode], 0x04B ;left
    jne .not_pressed_left
        dec word [cursor_x]
        dec si
        call move_cursor
        jmp .loop
    .not_pressed_left:

    cmp byte [key_press_scancode], 0x04D ;right
    jne .not_pressed_right
        inc word [cursor_x]
        inc si
        call move_cursor
        jmp .loop
    .not_pressed_right:

    cmp byte [key_press_scancode], 0x00E ;back space
    jne .not_pressed_back
        dec word [cursor_x]
        dec si
        mov byte [bx+si],255
        call move_cursor
        ;call .concentrate_string
        jmp .loop
    .not_pressed_back:

    cmp byte [key_press_char],13 ;backspace / newline
    je .loop_end  ; jump if newline
    
    cmp si, input_buffer_size-1 ; yeah overwriting memory is not good
    jge .loop ;just keep going back until the idiot press enter. He should figure it out
    mov cx,[key_press_char]
    mov [bx+si],cx ; al = key_press_char
    inc si ; increase buffer length
    
    ;print char-----
    push bx
    mov bx,text_color
    call move_cursor
    inc word [cursor_x]
    mov al,[key_press_char]
    mov ah ,0x0e ;Teletype Mode
    int 0x10
    pop bx
    ;---------------
    jmp .loop ; loop back

    .loop_end:
    ;add null terminator
    mov [bx+si],byte 0x00
    popa
    ret

        
    ret

move_cursor:
    pusha
        mov ah,2
        mov bh,0 ; video page
        mov dh,[cursor_y] ; row (y; 0 is top)
        mov dl,[cursor_x] ; col (x; 0 is left)
        int 10h
    popa
ret

clear_screen:
    pusha
    mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
    mov bh, 0x07    ; character attribute = white on black
    mov cx, 0x0000  ; row = 0, col = 0
    mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
    int 0x10        ; call BIOS video interrupt
    popa
ret