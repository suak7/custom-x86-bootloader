[org 0x7e00]                   ; mbr loads at 0x7e00                
[bits 16]                      

start_stage2:
    mov [boot_drive], dl

    mov bx, real_mode_str
    call print16_string
    call print16_newline

    mov bx, switching_pm_str
    call print16_string
    call print16_newline  

    mov ah, 0x03               ; get cursor position
    mov bh, 0x00
    int 0x10            
    
    ; offset = (row * 80 + column) * 2
    xor ax, ax
    mov al, dh                 ; al = row
    mov bx, 160                ; 80 chars * 2 bytes per char
    mul bx                     ; ax = row * 160
    mov si, ax                 ; si = row offset

    xor ax, ax
    mov al, dl                 ; al = column
    shl ax, 1                  ; ax = column * 2
    add si, ax                 ; si = final offset

    mov [cursor_pos], si       ; save for protected mode printing

    call switch_to_pm               

[bits 32]

; called by switch_to_pm after mode transition
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

times 4096 - ($ - $$) db 0     ; pad to 4kb (8 sectors)