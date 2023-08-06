%include "./library/global.asm"
%include "./library/kernel_functions.asm"
%include "./library/macros.asm"
jmp _main

_main:
    INIT_DRAWMODE
    DRAW_BOX 10,10,250,180,9
    ;PRINT string0
    .main_loop:
        
        READ_INPUT ; reads input until enter is pressed
        STRING_TO_NUMBER buffer
        NUMBER_TO_STRING buffer,ax
        
        PRINT buffer
        call print_newline
        
    jmp .main_loop 

    .main_loop_end:

    call print_newline
    ;loop_end
    
jmp $

string0: db "hello world!",10,13,0