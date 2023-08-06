%ifndef _BOOT_FUNCTIONS_ASM
%define _BOOT_FUNCTIONS_ASM
[org 0x7c00]
bits 16      ; tell the assembler we want 16 bit code

;32*2 chars


get_key:
    mov ah,0
    int 0x16
    mov [key_press_char],al
    mov [key_press_scancode],ah
ret
;    mov word bx,buffer
;    mov al,[key_press_char]
;    mov [bx],al

print_newline:
    inc word [cursor_y]
    mov [cursor_x], word 1
    ;draw cursor on newline
    call move_cursor
    mov al,'_'
    mov ah ,0x0e ;Teletype Mode
    int 0x10
    mov [cursor_x], word 0
ret

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

read_input:

    mov bx,buffer
    mov si,0
    .loop:
        mov ah,0x00 ; wait for input
        int 0x16 ;get input
        
        cmp al,13 ;backspace / newline
        je .func_end  ; jump if newline
        
        cmp ah,0x0e ; delete char?
        je .delete_char  ; jump if newline

        cmp si, input_buffer_size-1 ; yeah overwriting memory is not good
        jge .loop ;just keep going back until the idiot press enter. He should figure it out

        mov [bx+si],al ; al = key_press_char
        inc si ; increase buffer write pos
        
        ;print char-----
        push bx
        mov bx,text_color
        inc word [cursor_x]
        call move_cursor
        mov ah ,0x0e ;Teletype Mode
        int 0x10
        inc word [cursor_x]
        call move_cursor

        mov al,'_'
        int 0x10
        dec word [cursor_x]

        pop bx
        ;---------------

        jmp .loop ; loop back

    .loop_end:

    .delete_char:
        cmp si, 0 ; yeah overwriting memory is not good
        je .loop ;just go back
        push bx
        mov ah ,0x0e ;Teletype Mode
        ;remove cursor
        inc word [cursor_x]
        call move_cursor
        mov al,' '
        int 0x10
        dec word [cursor_x]
        call move_cursor
        ;remove char from screen
        mov bx,text_color
        mov al,'_'
        int 0x10
        dec word [cursor_x]
        dec si

        pop bx
        jmp .loop ; loop back
    .func_end:
    ;remove cursor
    inc word [cursor_x]
    call move_cursor
    mov ah ,0x0e ;Teletype Mode
    mov al,' '
    int 0x10
    ;add null terminator
    mov [bx+si],word 0
ret

string_to_number:
    xor dx,dx
    xor bx,bx
    .loop_start:
    mov al,[si]
    cmp al , 0
    je .loop_end

        
    cmp al,'-' ;minus
    jne .done
            mov bx,1 ;set ax to 1 to make number minus later
            inc si        
    jmp .loop_start

    .done:
    sub al,48    ; ASCII value --> numeric value
    mov ah,0     ; AX = numeric value of digit
    add dx,dx    ; DX = 2 * original DX
    add ax,dx    ; AX = 2 * original DX + digit
    add dx,dx    ; DX = 4 * original DX
    add dx,dx    ; DX = 8 * original DX
    add dx,ax    ; DX = 10 * original DX + digit

    inc si
    jmp .loop_start
    .loop_end:
    ;set to minus if - char
    cmp bx,1
    jne .not
        neg dx
    .not:
    mov ax,dx ;ax is return value
ret

shut_down:
    mov ax, 5301h
    xor bx, bx
    int 15h ; Connect BIOS APM

    mov ax, 530fh
    mov bx, 1
    mov cx, 1
    int 15h ; Engage BIOS APM

    mov ax, 5307h
    mov bx, 1
    mov cx, 3
    int 15h ; Shut down !!!
ret

number_to_string:
   xor    di, di   
   mov   bx,10   ;For Division
   cmp   ax,0    ;Check if number is negative
   jge    .ZC2
   neg    ax        ;Turn positive
   mov   [si], byte 45 ;Add - to the string
   inc    si
.ZC2: 

   xor    dx, dx
   div   bx        ;Divide the number by 10 to get the next digit
   add   dx,48   ;Add 48 to convert to ASCII
   ;mov [si], dx
   push dx
   inc di
   cmp   ax,0   
   jnz    .ZC2
ZC3:
   pop bx ;      #Pop the ASCII-value from the stack and store it in (%rcx)
   mov [si],bx
   inc    si     
   dec    di

   cmp   di,0
   jnz    ZC3
   ret

   ret      


;------------------------------------------------------
;cx = xpos , dx = ypos, si = x-length, di = y-length, al = color
draw_box:
	push si               ;save x-length
	.for_x:
		push di           ;save y-length
		.for_y:
			pusha
			mov bh, 0     ;page number (0 is default)
			add cx, si    ;cx = x-coordinate
			add dx, di    ;dx = y-coordinate
			mov ah, 0xC   ;write pixel at coordinate
			int 0x10      ;draw pixel!
			popa
		sub di, 1         ;decrease di by one and set flags
		jnz .for_y        ;repeat for y-length times
		pop di            ;restore di to y-length
	sub si, 1             ;decrease si by one and set flags
	jnz .for_x            ;repeat for x-length times
	pop si                ;restore si to x-length  -> starting state restored
	ret
;------------------------------------------------------

move_cursor:
    pusha
        mov ah,2
        mov bh,0 ; video page
        mov dh,[cursor_y] ; row (y; 0 is top)
        mov dl,[cursor_x] ; col (x; 0 is left)
        int 10h
    popa
ret
%endif
