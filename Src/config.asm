; Boot configuration handling functionality
BITS 64
DEFAULT REL

%include "src/efi.inc"

; External symbols from boot.asm
extern SystemTable
extern ImageHandle
extern print_string
extern get_char

section .text
global load_config
global save_config
global configure_boot_options
global verify_file_integrity

; Calculate SHA-256 hash for a file
; This is a simplified implementation that should be replaced
; with a proper SHA-256 implementation in production
calculate_file_hash:
    push rbp
    mov rbp, rsp

    ; TODO: Implement SHA-256 hash calculation
    ; For now, use a simple checksum

    mov rsp, rbp
    pop rbp
    ret

; Verify file integrity against stored hash
; Halts system if verification fails
verify_file_integrity:
    push rbp
    mov rbp, rsp

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [VerifyingMsg]
    call print_string
    pop rcx

    ; Calculate current hash
    call calculate_file_hash

    ; Compare with stored hash
    ; If mismatch, print error and halt
    cmp rax, 0
    jne .integrity_error

    mov rsp, rbp
    pop rbp
    xor rax, rax           ; Return success
    ret

.integrity_error:
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [IntegrityFailMsg]
    call print_string
    pop rcx

    cli                    ; Disable interrupts
    hlt                    ; Halt the system - System security compromised

; Load configuration from file
; Creates default config if file doesn't exist
load_config:
    push rbp
    mov rbp, rsp

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [LoadConfigMsg]
    call print_string
    pop rcx

    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; Open config file
    lea rdx, [ConfigPath]     ; Path to config file
    mov r8, EFI_FILE_READ     ; Open for reading
    lea r9, [FileHandle]      ; File handle
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax

    test rax, rax             ; Check for success
    jnz .create_default

    ; Read configuration
    mov rcx, [FileHandle]
    lea rdx, [ConfigBuffer]
    mov r8, BOOT_CONFIG_size
    lea r9, [BytesRead]
    mov rax, [rcx + EFI_FILE_READ]
    call rax

    ; Verify config integrity
    call verify_file_integrity
    test rax, rax
    jnz .verify_failed      ; If verification fails, halt system

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [ConfigLoadOkMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    xor rax, rax             ; Return success
    ret

.create_default:
    ; Create default configuration
    lea rdi, [ConfigBuffer]
    lea rsi, [DefaultKernelPath]
    mov rcx, 256
    rep movsb               ; Copy default kernel path

    lea rsi, [DefaultLogoPath]
    mov rcx, 256
    rep movsb               ; Copy default logo path

    mov byte [ConfigBuffer + BOOT_CONFIG.DefaultEntry], 0
    mov byte [ConfigBuffer + BOOT_CONFIG.Timeout], 5

    ; Calculate and store initial hashes
    call calculate_file_hash
    mov [ConfigBuffer + BOOT_CONFIG.ConfigHash], rax

    ; Save default configuration
    call save_config

    mov rsp, rbp
    pop rbp
    xor rax, rax           ; Return success
    ret

.verify_failed:
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [IntegrityFailMsg]
    call print_string
    pop rcx

    cli                    ; Disable interrupts
    hlt                    ; Halt the system - Config integrity check failed

; Save configuration to file
save_config:
    push rbp
    mov rbp, rsp

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [SaveConfigMsg]
    call print_string
    pop rcx

    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; Open config file for writing
    lea rdx, [ConfigPath]     ; Path to config file
    mov r8, EFI_FILE_WRITE    ; Open for writing
    lea r9, [FileHandle]      ; File handle
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax

    ; Write configuration
    mov rcx, [FileHandle]
    lea rdx, [ConfigBuffer]
    mov r8, BOOT_CONFIG_size
    lea r9, [BytesWritten]
    mov rax, [rcx + EFI_FILE_WRITE]
    call rax

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [ConfigSaveOkMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

; Configure boot options through menu
configure_boot_options:
    push rbp
    mov rbp, rsp

    ; Print configuration menu
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [ConfigMenu]
    call print_string

    ; Get input and handle configuration options
    call get_char            ; From main.asm

    ; Handle different configuration options
    cmp al, '1'
    je .change_kernel
    cmp al, '2'
    je .change_logo
    cmp al, '3'
    je .change_timeout
    cmp al, '4'
    je .save_exit

    jmp configure_boot_options  ; Invalid option, show menu again

.change_kernel:
    ; TODO: Implement kernel path change
    jmp configure_boot_options

.change_logo:
    ; TODO: Implement logo path change
    jmp configure_boot_options

.change_timeout:
    ; TODO: Implement timeout change
    jmp configure_boot_options

.save_exit:
    call save_config
    mov rsp, rbp
    pop rbp
    ret

section .data
ConfigPath:      db '\EFI\BOOT\boot.cfg', 0
DefaultKernelPath: db '\boot\vmlinuz', 0           ; Default USB kernel path
DefaultLogoPath:   db '\EFI\BOOT\boot1.png', 0    ; Default USB logo path

; Debug messages
LoadConfigMsg:    db 'Loading boot configuration...', 0x0D, 0x0A, 0
SaveConfigMsg:    db 'Saving boot configuration...', 0x0D, 0x0A, 0
ConfigLoadOkMsg:  db 'Configuration loaded successfully', 0x0D, 0x0A, 0
ConfigSaveOkMsg:  db 'Configuration saved successfully', 0x0D, 0x0A, 0
VerifyingMsg:    db 'Verifying file integrity...', 0x0D, 0x0A, 0
IntegrityFailMsg: db 'ERROR: File integrity check failed! System halted.', 0x0D, 0x0A, 0

ConfigMenu:       db 'Boot Configuration:', 0x0D, 0x0A
                 db '1. Change kernel path', 0x0D, 0x0A
                 db '2. Change logo path', 0x0D, 0x0A
                 db '3. Change boot timeout', 0x0D, 0x0A
                 db '4. Save and exit', 0x0D, 0x0A
                 db 'Selection: ', 0

section .bss
FileHandle:      resq 1
BytesRead:       resq 1
BytesWritten:    resq 1
ConfigBuffer:    resb BOOT_CONFIG_size
HashBuffer:      resb 32        ; Buffer for hash calculation

section .note.GNU-stack noalloc noexec nowrite progbits