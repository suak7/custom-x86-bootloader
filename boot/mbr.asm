%define load_address 0x7C00
%define relocate_address 0x0600
%define stage2_address 0x7E00
%define stage2_sectors 8

[org load_address]        
[bits 16]

start_boot:
    cli
    xor ax, ax                      
    mov ds, ax                      
    mov es, ax                      
    mov ss, ax                      
    mov sp, load_address           
    mov [boot_drive], dl

    sti

    mov si, load_address    
    mov di, relocate_address
    mov cx, 512
    cld
    rep movsb

    jmp 0x0000:(continue_boot - load_address + relocate_address) 

continue_boot:
    call clear_screen

    mov si, mbr_start_str - load_address + relocate_address
    call print_string 
    call print_newline  

    mov ah, 0x02                    
    mov al, stage2_sectors          
    mov ch, 0                       
    mov cl, 2                       
    mov dh, 0                     
    mov dl, [boot_drive - load_address + relocate_address]  
    mov bx, stage2_address             
    int 0x13  

    mov si, stage2_loaded_str - load_address + relocate_address
    call print_string  

    mov [boot_drive - load_address + relocate_address], dl

    jmp 0x0000:stage2_address                    

print_error:
    mov si, disk_error_str - load_address + relocate_address
    call print_string
    call print_newline

    mov dl, ah                      
    
    jmp halt

halt:
    mov si, system_halted_str - load_address + relocate_address
    call print_string
    call print_newline
    cli                             
    hlt                             
    jmp halt 

clear_screen:
    pusha                           
    
    mov ah, 0x00                    
    mov al, 0x03                    
    int 0x10                        
    
    popa                            
    ret     

print_string:
    pusha                           
    
.print_loop:
    lodsb                           
    cmp al, 0                       
    je .end_print_loop                        
    
    mov ah, 0x0E                     
    mov bh, 0                       
    mov bl, 0x07                  
    int 0x10                        
    
    jmp .print_loop                       

.end_print_loop:
    popa                            
    ret   

print_newline:
    pusha
    
    mov ah, 0x0E                    
    mov al, 0x0D                    
    int 0x10
    mov al, 0x0A                    
    int 0x10
    
    popa
    ret  

mbr_start_str: db 'Master boot record started', 0  
stage2_loaded_str: db 'Stage 2 loaded successfully', 0
disk_error_str: db 'error: disk read error', 0
system_halted_str: db 'System halted', 0

boot_drive: db 0

times 510 - ($ - $$) db 0
dw 0xAA55