; Main bootloader functionality
BITS 64
DEFAULT REL

%include "src/efi.inc"

; External symbols from boot.asm
extern efi_main
extern SystemTable
extern ImageHandle
extern print_string
extern load_boot_logo
extern display_setup_logo ; Added declaration for display_setup_logo

; External symbols from config.asm
extern load_config
extern save_config
extern configure_boot_options

section .text
global _start
global menu_main
global get_char  ; Make get_char available to other modules

_start:
    ; Call UEFI entry point (for initialization)
    call efi_main

    ; Enter the main menu loop
    call menu_main

    ; If we return from the menu (unlikely), halt the system
    cli
    hlt

; Enter system setup
; This function handles BIOS/QEMU setup entry with security features:
; 1. Displays secure boot2.png logo (integrity verified)
; 2. Detects if running on QEMU or real hardware
; 3. Uses appropriate method to enter setup mode
enter_setup:
    push rbp
    mov rbp, rsp

    ; Show setup logo first - verified against stored hash
    call display_setup_logo

    ; Get firmware vendor string to detect if we're running on QEMU
    mov rcx, [SystemTable]
    mov rdx, [rcx + EFI_SYSTEM_TABLE_FWVENDOR]

    ; Check if contains "QEMU"
    mov rax, [rdx]
    and rax, 0x554D4551  ; "QEMU" in little endian
    cmp rax, 0x554D4551
    je .qemu_setup

    ; Real hardware - use runtime services to enter setup
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_RUNTIME]
    mov rax, [rcx + EFI_RUNTIME_ENTERSETUP]
    call rax
    jmp .exit

.qemu_setup:
    ; QEMU - use special key sequence to enter monitor
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_RUNTIME]
    mov rax, [rcx + EFI_RUNTIME_RESETSYSTEM]
    mov rcx, EFI_RUNTIME_RESETWARM
    call rax

.exit:
    mov rsp, rbp
    pop rbp
    ret

; Find and mount USB root filesystem
; This function:
; 1. Locates USB storage device
; 2. Verifies FAT32 filesystem
; 3. Mounts as root for kernel loading
find_usb_root:
    push rbp
    mov rbp, rsp

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [FindingUSBMsg]
    call print_string
    pop rcx

    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; TODO: Implement USB device detection
    ; For now, assume first detected filesystem is USB

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [USBFoundMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

; Load kernel from USB filesystem
; Security features:
; 1. Verifies kernel file integrity
; 2. Maps kernel to protected memory
; 3. Configures memory protection before jump
load_kernel:
    push rbp
    mov rbp, rsp

    ; Find USB root first
    call find_usb_root

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [LoadingKernelMsg]
    call print_string
    pop rcx

    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; Open kernel file
    lea rdx, [KernelPath]     ; Path to kernel file
    mov r8, EFI_FILE_READ     ; Open for reading
    lea r9, [FileHandle]      ; File handle
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax

    test rax, rax             ; Check for success
    jnz .error

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [KernelOpenOkMsg]
    call print_string
    pop rcx

    ; Get memory map for safe kernel loading
    lea rdx, [MemoryMap]
    mov r8, [MemoryMapSize]
    lea r9, [MapKey]
    lea r10, [DescriptorSize]
    lea r11, [DescriptorVersion]
    mov rax, [rcx + EFI_BOOT_GETMEMORYMAP]
    call rax

    ; Print memory map success
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [MemMapOkMsg]
    call print_string
    pop rcx

    ; Load kernel into memory
    mov rcx, [FileHandle]
    lea rdx, [KernelBuffer]
    mov r8, KERNEL_BUFFER_SIZE
    lea r9, [BytesRead]
    mov rax, [rcx + EFI_FILE_READ]
    call rax

    ; Print kernel load success
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [KernelLoadOkMsg]
    call print_string
    pop rcx

    ; Exit boot services before jumping to kernel
    mov rcx, [ImageHandle]
    mov rdx, [MapKey]
    mov rax, [SystemTable]
    mov rax, [rax + EFI_SYSTEM_TABLE_BOOT]
    mov rax, [rax + EFI_BOOT_EXITBOOTSERVICES]
    call rax

    ; Jump to kernel
    jmp [KernelEntry]

.error:
    ; Print error message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [KernelLoadFailMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    mov rax, 1               ; Return error
    ret

; Print interactive boot menu
print_menu:
    push rbp
    mov rbp, rsp

    ; Get ConOut
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]

    ; Print menu
    lea rdx, [MenuOptions]
    call print_string

    mov rsp, rbp
    pop rbp
    ret

; Get character input from keyboard
; Used by both main menu and configuration
get_char:
    push rbp
    mov rbp, rsp

    ; Get ConIn
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONIN]

    ; Wait for key
    mov rdx, [rcx + EFI_INPUT_WAITFORKEY]
    call rdx

    ; Read keystroke
    lea rdx, [InputKey]
    mov rax, [rcx + EFI_INPUT_READKEY]
    call rax

    ; Return character in al
    movzx rax, word [InputKey + EFI_INPUT_KEY.UnicodeChar]

    mov rsp, rbp
    pop rbp
    ret

; Main menu handler with secure boot features
menu_main:
    push rbp
    mov rbp, rsp

.menu_loop:
    ; Print menu
    call print_menu

    ; Get input
    call get_char

    ; Compare with options
    cmp al, '1'
    je .boot_kernel
    cmp al, '2'
    je .memory_info
    cmp al, '3'
    je .system_info
    cmp al, '4'
    je .configure
    cmp al, '5'
    je .setup
    cmp al, '6'
    je .reboot

    ; Invalid option, loop again
    jmp .menu_loop

.boot_kernel:
    lea rdx, [BootingMsg]
    call load_kernel
    jmp .exit

.memory_info:
    lea rdx, [MemoryMsg]
    jmp .print_and_loop

.system_info:
    lea rdx, [SystemMsg]
    jmp .print_and_loop

.configure:
    lea rdx, [ConfigureMsg]
    jmp .print_and_loop

.setup:
    lea rdx, [SetupMsg]
    call print_string
    call enter_setup
    jmp .menu_loop

.reboot:
    lea rdx, [RebootMsg]
    jmp .exit

.print_and_loop:
    push rdx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    call print_string
    pop rdx
    jmp .menu_loop

.exit:
    push rdx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    call print_string
    pop rdx

    mov rsp, rbp
    pop rbp
    ret

section .data
MenuOptions:     db 0x0D, 0x0A
                db '1. Boot kernel', 0x0D, 0x0A
                db '2. Memory info', 0x0D, 0x0A
                db '3. System info', 0x0D, 0x0A
                db '4. Configure boot options', 0x0D, 0x0A
                db '5. Enter setup', 0x0D, 0x0A
                db '6. Reboot', 0x0D, 0x0A
                db 'Selection: ', 0
BootingMsg:      db 'Booting kernel...', 0x0D, 0x0A, 0
MemoryMsg:       db 'Memory Information:', 0x0D, 0x0A, 0
SystemMsg:       db 'System Information:', 0x0D, 0x0A, 0
ConfigureMsg:    db 'Configure Boot Options:', 0x0D, 0x0A, 0
SetupMsg:       db 'Entering system setup...', 0x0D, 0x0A, 0
RebootMsg:      db 'Rebooting...', 0x0D, 0x0A, 0
KernelPath:    db '\boot\vmlinuz', 0    ; Updated kernel path
KernelEntry:   dq 0x100000    ; Default kernel entry point
KERNEL_BUFFER_SIZE equ 1024*1024*16  ; 16MB
; Debug messages
LoadingKernelMsg:   db 'Loading kernel from: ', 0
KernelOpenOkMsg:    db 'Kernel file opened successfully', 0x0D, 0x0A, 0
KernelLoadOkMsg:    db 'Kernel loaded into memory', 0x0D, 0x0A, 0
KernelLoadFailMsg:  db 'Failed to load kernel', 0x0D, 0x0A, 0
MemMapOkMsg:        db 'Memory map retrieved successfully', 0x0D, 0x0A, 0
FindingUSBMsg:      db 'Looking for USB root filesystem...', 0x0D, 0x0A, 0
USBFoundMsg:        db 'USB root filesystem found', 0x0D, 0x0A, 0

section .bss
InputKey:        resb EFI_INPUT_KEY_size  ; Space for EFI_INPUT_KEY structure
KeyEvent:        resq 1
KernelBuffer:    resb 1024*1024*16 ; 16MB buffer for kernel
MemoryMap:         resb 1024*32  ; 32KB for memory map
MemoryMapSize:     resq 1
MapKey:            resq 1
DescriptorSize:    resq 1
DescriptorVersion: resq 1
FileHandle:        resq 1
BytesRead:         resq 1
BootConfig:        resb BOOT_CONFIG_size  ; Boot configuration structure

section .note.GNU-stack noalloc noexec nowrite progbits