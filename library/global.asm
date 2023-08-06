;32*2 chars
%ifndef _GLOBAL_ASM
%define _GLOBAL_ASM
%define input_buffer_size 32 
%define text_color 3

HW_EQUIP_PS2     equ 4          ; PS2 mouse installed?
MOUSE_PKT_BYTES  equ 3          ; Number of bytes in mouse packet
MOUSE_RESOLUTION equ 3          ; Mouse resolution 8 counts/mm



cursor_x: dw  0
cursor_y: dw 0
key_press_char: db 0
key_press_scancode: db 0
buffer: times input_buffer_size+1 db 0

%endif