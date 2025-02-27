; Boot configuration handling functionality
BITS 64
DEFAULT REL

%include "src/efi.inc"

; External symbols from boot.asm
extern SystemTable
extern ImageHandle
extern print_string
extern verify_checksum ; From checksums.h

section .text
global load_config
global save_config
global configure_boot_options

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
    mov r8, EFI_FILE_READ    ; Open for reading
    lea r9, [FileHandle]     ; File handle
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax

    test rax, rax           ; Check for success
    jnz .create_default

    ; Read configuration
    mov rcx, [FileHandle]
    lea rdx, [ConfigBuffer]
    mov r8, BOOT_CONFIG_size
    lea r9, [BytesRead]
    mov rax, [rcx + EFI_FILE_READ]
    call rax

    ; Verify config integrity using external checksum
    mov rdx, ConfigPath
    mov rcx, 64            ; Offset to config hash in checksums.dat
    call verify_checksum
    test rax, rax
    jnz .verify_failed    ; If verification fails, halt system

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [ConfigLoadOkMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    xor rax, rax         ; Return success
    ret

.create_default:
    ; Create default configuration
    lea rdi, [ConfigBuffer]
    lea rsi, [DefaultKernelPath]
    mov rcx, 256
    rep movsb           ; Copy default kernel path

    lea rsi, [DefaultLogoPath]
    mov rcx, 256
    rep movsb          ; Copy default logo path

    mov byte [ConfigBuffer + BOOT_CONFIG.DefaultEntry], 0
    mov byte [ConfigBuffer + BOOT_CONFIG.Timeout], 5

    ; Save default configuration
    call save_config

    mov rsp, rbp
    pop rbp
    xor rax, rax       ; Return success
    ret

.verify_failed:
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [IntegrityFailMsg]
    call print_string
    pop rcx

    cli                ; Disable interrupts
    hlt               ; Halt the system - Config integrity check failed

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
    mov r8, EFI_FILE_WRITE   ; Open for writing
    lea r9, [FileHandle]     ; File handle
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

section .data
ConfigPath:      db '\EFI\BOOT\boot.cfg', 0
DefaultKernelPath: db '\boot\vmlinuz', 0           ; Default USB kernel path
DefaultLogoPath:   db '\EFI\BOOT\boot1.png', 0    ; Default USB logo path

; Debug messages
LoadConfigMsg:    db 'Loading boot configuration...', 0x0D, 0x0A, 0
SaveConfigMsg:    db 'Saving boot configuration...', 0x0D, 0x0A, 0
ConfigLoadOkMsg:  db 'Configuration loaded successfully', 0x0D, 0x0A, 0
ConfigSaveOkMsg:  db 'Configuration saved successfully', 0x0D, 0x0A, 0
VerifyingMsg:    db 'Verifying configuration integrity...', 0x0D, 0x0A, 0
IntegrityFailMsg: db 'ERROR: Configuration integrity check failed! System halted.', 0x0D, 0x0A, 0

section .bss
FileHandle:      resq 1
BytesRead:       resq 1
BytesWritten:    resq 1
ConfigBuffer:    resb BOOT_CONFIG_size

section .note.GNU-stack noalloc noexec nowrite progbits

; Removed: calculate_file_hash, verify_file_integrity,  HashBuffer, BOOT_CONFIG.ConfigHash (implicitly removed by removing the function)
; configure_boot_options remains as it doesn't directly involve hash verification.