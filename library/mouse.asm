; Function: mouse_initialize
;           Initialize the mouse if present
;
; Inputs:   None
; Returns:  CF = 1 if error, CF=0 success
; Clobbers: AX

mouse_initialize:
    push es
    push bx

    int 0x11                    ; Get equipment list
    test ax, HW_EQUIP_PS2       ; Is a PS2 mouse installed?
    jz .no_mouse                ;     if not print error and end

    mov ax, 0xC205              ; Initialize mouse
    mov bh, MOUSE_PKT_BYTES     ; 3 byte packets
    int 0x15                    ; Call BIOS to initialize
    jc .no_mouse                ;    If not successful assume no mouse

    mov ax, 0xC203              ; Set resolution
    mov bh, MOUSE_RESOLUTION    ; 8 counts / mm
    int 0x15                    ; Call BIOS to set resolution
    jc .no_mouse                ;    If not successful assume no mouse

    push cs
    pop es                      ; ES = segment where code and mouse handler reside

    mov bx, mouse_callback_dummy
    mov ax, 0xC207              ; Install a default null handler (ES:BX)
    int 0x15                    ; Call BIOS to set callback
    jc .no_mouse                ;    If not successful assume no mouse

    clc                         ; CF=0 is success
    jmp .finished
.no_mouse:
    stc                         ; CF=1 is error
.finished:
    pop bx
    pop es
    ret

; Function: mouse_enable
;           Enable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouse_enable:
    push es
    push bx

    call mouse_disable          ; Disable mouse before enabling

    push cs
    pop es
    mov bx, mouse_callback
    mov ax, 0xC207              ; Set mouse callback function (ES:BX)
    int 0x15                    ; Call BIOS to set callback

    mov ax, 0xC200              ; Enable/Disable mouse
    mov bh, 1                   ; BH = Enable = 1
    int 0x15                    ; Call BIOS to disable mouse

    pop bx
    pop es
    ret

; Function: mouse_disable
;           Disable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouse_disable:
    push es
    push bx

    mov ax, 0xC200              ; Enable/Disable mouse
    xor bx, bx                  ; BH = Disable = 0
    int 0x15                    ; Call BIOS to disable mouse

    mov es, bx
    mov ax, 0xC207              ; Clear callback function (ES:BX=0:0)
    int 0x15                    ; Call BIOS to set callback

    pop bx
    pop es
    ret

; Function: mouse_callback (FAR)
;           called by the interrupt handler to process a mouse data packet
;           All registers that are modified must be saved and restored
;           Since we are polling manually this handler does nothing
;
; Inputs:   SP+4  = Unused (0)
;           SP+6  = MovementY
;           SP+8  = MovementX
;           SP+10 = Mouse Status
;
; Returns:  None
; Clobbers: None

ARG_OFFSETS      equ 6          ; Offset of args from BP

mouse_callback:
    push bp                     ; Function prologue
    mov bp, sp
    push ds                     ; Save registers we modify
    push ax
    push bx
    push cx
    push dx

    push cs
    pop ds                      ; DS = CS, CS = where our variables are stored

    mov al,[bp+ARG_OFFSETS+6]
    mov bl, al                  ; BX = copy of status byte
    mov cl, 3                   ; Shift signY (bit 5) left 3 bits
    shl al, cl                  ; CF = signY
                                ; Sign bit of AL = SignX
    sbb dh, dh                  ; CH = SignY value set in all bits
    cbw                         ; AH = SignX value set in all bits
    mov dl, [bp+ARG_OFFSETS+2]  ; CX = movementY
    mov al, [bp+ARG_OFFSETS+4]  ; AX = movementX

    ; new mouse X_coord = X_Coord + movementX
    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [mouseY]
    add dx, cx                  ; DX = new mouse Y_coord
    mov cx, [mouseX]
    add ax, cx                  ; AX = new mouse X_coord

    ; Status
    mov [curStatus], bl         ; Update the current status with the new bits
    mov [mouseX], ax            ; Update current virtual mouseX coord
    mov [mouseY], dx            ; Update current virtual mouseY coord

    pop dx                      ; Restore all modified registers
    pop cx
    pop bx
    pop ax
    pop ds
    pop bp                      ; Function epilogue

mouse_callback_dummy:
    retf                        ; This routine was reached via FAR CALL. Need a FAR RET

; Function: poll_mouse
;           Poll the mouse state and display the X and Y coordinates and the status byte
;
; Inputs:   None
; Returns:  None
; Clobbers: None

poll_mouse:
    push ax
    push bx
    push dx

    mov bx, 0x0002              ; Set display page to 0 (BH) and color green (BL)

    cli
    mov ax, [mouseX]            ; Retrieve current mouse coordinates. Disable interrupts
    mov dx, [mouseY]            ; So that these two variables are read atomically
    sti

    call print_word_hex         ; Print the mouseX coordinate
    mov si, delimCommaSpc
    call print_string

    mov ax, dx
    call print_word_hex         ; Print the mouseY coordinate
    mov si, delimCommaSpc
    call print_string

    mov al, [curStatus]
    call print_byte_hex         ; Print the last read mouse state byte

    mov al, 0x0d
    call print_char             ; Print carriage return to return to beginning of line

    pop dx
    pop bx
    pop ax
    ret