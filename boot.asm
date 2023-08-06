[org 0x7c00] 
bits 16
mov [BOOT_DISK], dl       
; 4 * 512          
%define segments_to_read 8
%define dead_code 0x0dead                            
xor ax, ax                          
mov es, ax
mov ds, ax
mov bp, 0x8000
mov sp, bp

mov bx, 0x7e00

mov ah, 2
mov al, segments_to_read ;number of segments to read
mov ch, 0
mov dh, 0
mov cl, 2 ;what to rad
mov dl, [BOOT_DISK]
int 0x13

mov ah, 0x0e
mov al, [0x7e00]
int 0x10
jmp _init_stack
BOOT_DISK: db 0 ; the disk that booted the system

times 510-($-$$) db 0 ;empty all bytes that are not used
dw 0xaa55 ;signature key to tell its a bootloader

EMPTY_SPACE: 
times 1024 * 16 resb 0

KERNEL_STACK_BUFFER:
_init_stack:
mov sp, KERNEL_STACK_BUFFER

jmp _main ; 0x7e00

%include "kernel.asm" ;kernal code

jmp $ ;infinite loop
times (segments_to_read*512) db dead_code ;empty