[bits 16]

switch_to_pm:
    cli                         

    lgdt [gdt_descriptor]      ; load gdt descriptor

    mov eax, cr0               ; read cr0
    or eax, 0x1                ; set bit 0 (pe bit)
    mov cr0, eax               ; write back to cr0

    ; flushes cpu instruction pipeline
    ; loads cs with code segment selector (0x08)
    ; jumps to 32-bit code
    jmp CODE_SEG:init_pm

[bits 32]

; initialize protected mode environment
; sets up segment registers and stack
; all segments point to flat data segment (covers all 4gb)
init_pm:
    mov ax, DATA_SEG            
    mov ds, ax                  
    mov ss, ax                  
    mov es, ax                 
    mov fs, ax                  
    mov gs, ax                  

    ; stack grows downward from high address
    mov ebp, 0x90000           ; stack base at 576kb         
    mov esp, ebp               ; stack pointer = base    

    call begin_pm               