 %macro PRINT 1
    mov si, %1
    call print_string
 %endmacro

  %macro DRAW_BOX 5
    mov cx,%1 ;300 width
    mov dx,%2 ;200 height
    mov si,%3
    mov di,%4
    mov al,%5
    call draw_box ;cx = xpos , dx = ypos, si = x-length, di = y-length, al = color
 %endmacro


%macro READ_INPUT 0
    call read_input ; reads input until enter is pressed
%endmacro

%macro STRING_TO_NUMBER 1
    mov si,%1

    call string_to_number ; get number ; ax is returns
%endmacro



%macro NUMBER_TO_STRING 2
    mov si,%1
    mov ax,%2
    call number_to_string
%endmacro


%macro INIT_DRAWMODE 0

    ;draw pixel test
    mov ah, 0   ;Set display mode
    mov al, 13h ;13h = 320x200, 256 colors
    int  0x10   ;Video BIOS Services
%endmacro