[bits 32]

PCI_CONFIG_ADDRESS equ 0xcf8       
PCI_CONFIG_DATA equ 0xcfc       

PCI_VENDOR_ID equ 0x00        
PCI_DEVICE_ID equ 0x02        
PCI_CLASS_CODE equ 0x0b        
PCI_SUBCLASS equ 0x0a        
PCI_PROG_IF equ 0x09        
PCI_BAR0 equ 0x10        

USB_CLASS_CODE equ 0x0c        ; serial bus controller
USB_SUBCLASS equ 0x03          ; usb Controller
EHCI_PROG_IF equ 0x20          ; ehci (usb 2.0)
XHCI_PROG_IF equ 0x30          ; xhci (usb 3.0)

pci_scan_usb:
    pushad
    mov byte [usb_controller_found], 0
    xor ecx, ecx               ; scan all buses (0-255)
    
.scan_bus:
    xor edx, edx               ; scan all devices on bus (0-31)
    
.scan_device:
    xor esi, esi               ; scan all functions for device (0-7)

; read vendor id to check if device exists    
.scan_function:
    mov eax, ecx               ; eax = bus
    shl eax, 16                ; shift to bits 23-16
    or eax, edx                ; or with device
    shl eax, 11                ; shift device to bits 15-11
    or eax, esi                ; or with function
    shl eax, 8                 ; shift function to bits 10-8
    or eax, 0x80000000         ; set enable bit
    
    ; write address to config_address port
    mov dx, PCI_CONFIG_ADDRESS
    out dx, eax
    
    ; read from config_data port
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    
    ; check vendor id (lower 16 bits)
    cmp ax, 0xFFFF             ; 0xffff = no device
    je .next_function
    
    push ecx                   ; save bus
    push edx                   ; save device  
    push esi                   ; save function
    
    ; build address for class code register (offset 0x08)
    mov eax, ecx                    
    shl eax, 16
    or eax, edx                     
    shl eax, 11
    or eax, esi                     
    shl eax, 8
    or eax, 0x08                    
    or eax, 0x80000000            
    
    ; read class code register
    mov dx, PCI_CONFIG_ADDRESS
    out dx, eax
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    
    ; extract class code (byte 3), subclass (byte 2), prog if (byte 1)
    ; format: [base class][sub class][prog if][revision]
    shr eax, 8                 ; shift right to get [bc][sc][pi]
    
    ; check class code (bits 23-16 after shift)
    mov ebx, eax
    shr ebx, 16                ; ebx = class code
    and ebx, 0xFF
    cmp bl, USB_CLASS_CODE          
    jne .not_usb
    
    ; check subclass (bits 15-8)
    mov ebx, eax
    shr ebx, 8                 ; ebx = subclass
    and ebx, 0xFF
    cmp bl, USB_SUBCLASS            
    jne .not_usb
    
    ; check programming interface (bits 7-0)
    and eax, 0xFF              ; eax = programming interface
    
    cmp al, EHCI_PROG_IF            
    je .found_ehci
    
    cmp al, XHCI_PROG_IF            
    je .found_xhci
    
    jmp .not_usb
    
.found_ehci:
    mov ebx, found_ehci_str
    call print32_string
    call print32_newline

    mov byte [usb_controller_type], EHCI_PROG_IF
    jmp .save_controller_info
    
.found_xhci:
    mov ebx, found_xhci_str
    call print32_string
    call print32_newline

    mov byte [usb_controller_type], XHCI_PROG_IF
    jmp .save_controller_info
    
.save_controller_info:
    pop esi                    ; restore function
    pop edx                    ; restore device
    pop ecx                    ; restore bus
    
    mov [usb_controller_bus], cl
    mov [usb_controller_device], dl
    mov [usb_controller_function], esi

    ; read bar0 (base address register 0)
    push ecx
    push edx
    push esi
    
    ; build address for bar0 (offset 0x10)
    mov eax, ecx                    
    shl eax, 16
    or eax, edx                     
    shl eax, 11
    or eax, esi                     
    shl eax, 8
    or eax, PCI_BAR0              
    or eax, 0x80000000             
    
    ; read bar0
    mov dx, PCI_CONFIG_ADDRESS
    out dx, eax
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    
    ; bar0 contains mmio base address
    ; mask off lower 4 bits (flags)
    and eax, 0xFFFFFFF0
    mov [usb_controller_bar0], eax
    
    ; print bar0 address
    mov ebx, bar0_str
    call print32_string
    call print32_hex
    call print32_newline                
    
    mov byte [usb_controller_found], 1
    
    pop esi
    pop edx
    pop ecx
    
    jmp .end_pci_scan
    
.not_usb:
    pop esi                         
    pop edx                         
    pop ecx                         
    
.next_function:
    inc esi                         
    cmp esi, 8                 ; 8 functions per device
    jl .scan_function
    
    inc edx                         
    cmp edx, 32                ; 32 devices per bus
    jl .scan_device
    
    inc ecx                         
    cmp ecx, 256               ; 256 buses
    jl .scan_bus
    
.end_pci_scan:
    cmp byte [usb_controller_found], 0
    jne .found_device

    mov ebx, no_usb_str
    call print32_string
    call print32_newline
    
.found_device:
    popad
    ret

found_ehci_str: db 'Found EHCI USB 2.0 Controller | ', 0
found_xhci_str: db 'Found XHCI USB 3.0 Controller | ', 0
bar0_str: db 'BAR0: ', 0
no_usb_str: db 'No USB controllers found', 0
hex_prefix_str: db '0x', 0
space_str: db ' ', 0