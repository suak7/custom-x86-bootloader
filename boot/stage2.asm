[org 0x7e00]                    
[bits 16]                      

start_stage2:
    mov [boot_drive], dl

    mov bx, real_mode_str
    call print16_string
    call print16_newline

    mov bx, switching_pm_str
    call print16_string
    call print16_newline  

    mov ah, 0x03
    mov bh, 0x00
    int 0x10            

    mov [cursor_row], dh
    mov [cursor_col], dl

    mov al, [cursor_row]   
    xor ah, ah
    mov bx, 160
    mul bx                  
    mov si, ax             

    mov al, [cursor_col]
    xor ah, ah
    shl ax, 1               

    add si, ax              

    mov word [cursor_pos], si
    mov word [cursor_pos + 2], 0

    call switch_to_pm

[bits 32]

begin_pm:
    mov ebx, protected_mode_str
    call print32_string
 
    jmp $                    

%include "boot/print16_string.asm"
%include "boot/print32_string.asm"
%include "boot/gdt.asm"
%include "boot/switch_to_pm.asm"

real_mode_str: db 'Running in 16-bit real mode', 0
switching_pm_str: db 'Switching to protected mode...', 0
protected_mode_str: db 'Now in 32-bit protected mode', 0

boot_drive: db 0
cursor_pos: dd 0
cursor_row: db 0
cursor_col: db 0

times 4096 - ($ - $$) db 0