[bits 32]
[org 0x1000]

VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

kernel_entry:
    mov edi, VIDEO_MEMORY
    mov ecx, 80 * 25
    mov ax, 0x0F20              
    rep stosw

    mov esi, kernel_msg
    mov edi, VIDEO_MEMORY
    call print_string

    cli
    hlt
    jmp $

print_string:
    lodsb
    cmp al, 0
    je .done
    
    mov ah, WHITE_ON_BLACK
    stosw
    
    jmp print_string
    
.done:
    ret

kernel_msg: db 'KERNEL: Hello from the kernel! USB driver coming soon...', 0

times 8192 - ($ - $$) db 0      