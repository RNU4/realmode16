nasm -f bin boot.asm -o boot.bin 
qemu-system-x86_64  -k dk boot.bin 