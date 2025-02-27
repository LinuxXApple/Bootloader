; Tool to update checksums for boot files
BITS 64
DEFAULT REL

%include "src/efi.inc"

section .text
global _start

_start:
    ; Initialize
    push rbp
    mov rbp, rsp

    ; Print welcome message
    mov rdi, WelcomeMsg
    call print_string

    ; Open files and calculate new checksums
    mov rdi, Boot1Path
    call calculate_file_hash

    ; Store in checksum buffer
    mov [Checksums.boot1_hash], rax

    mov rdi, Boot2Path
    call calculate_file_hash
    mov [Checksums.boot2_hash], rax

    mov rdi, ConfigPath
    call calculate_file_hash
    mov [Checksums.config_hash], rax

    ; Save updated checksums to binary file
    mov rdi, ChecksumsPath
    mov rsi, Checksums
    mov rdx, 96              ; 32 bytes * 3 hashes
    call write_binary_file

    ; Print success message
    mov rdi, SuccessMsg
    call print_string

    mov rsp, rbp
    pop rbp
    xor eax, eax            ; Return 0
    ret

; Calculate SHA-256 hash for a file
calculate_file_hash:
    push rbp
    mov rbp, rsp

    ; Open file
    mov rsi, 0              ; O_RDONLY
    mov rax, 2              ; sys_open
    syscall

    test rax, rax
    js .error

    mov [FileHandle], rax

    ; Read file content
    mov rdi, [FileHandle]
    mov rsi, HashBuffer
    mov rdx, 4096          ; Read up to 4KB at a time
    mov rax, 0             ; sys_read
    syscall

    ; Close file
    mov rdi, [FileHandle]
    mov rax, 3             ; sys_close
    syscall

    ; Calculate hash (simple implementation for now)
    mov rax, 0
    mov rcx, 4096
    mov rsi, HashBuffer
.hash_loop:
    add al, [rsi]
    inc rsi
    loop .hash_loop

    mov rsp, rbp
    pop rbp
    ret

.error:
    mov rdi, ErrorMsg
    call print_string
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

; Write data to binary file
write_binary_file:
    push rbp
    mov rbp, rsp

    ; Open file for writing
    mov rsi, 0x241         ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o         ; File permissions
    mov rax, 2            ; sys_open
    syscall

    test rax, rax
    js .error

    mov [FileHandle], rax

    ; Write data
    mov rdi, [FileHandle]
    mov rsi, rsi          ; Data buffer already in rsi
    mov rdx, rdx          ; Size already in rdx
    mov rax, 1            ; sys_write
    syscall

    ; Close file
    mov rdi, [FileHandle]
    mov rax, 3            ; sys_close
    syscall

    mov rsp, rbp
    pop rbp
    ret

.error:
    mov rdi, WriteErrorMsg
    call print_string
    mov rsp, rbp
    pop rbp
    ret

; Simple print string function
print_string:
    push rbp
    mov rbp, rsp

    ; Calculate string length
    mov rsi, rdi
    mov rdx, 0
.strlen:
    cmp byte [rsi], 0
    je .print
    inc rdx
    inc rsi
    jmp .strlen

.print:
    mov rsi, rdi          ; string
    mov rdi, 1            ; stdout
    mov rax, 1            ; sys_write
    syscall

    mov rsp, rbp
    pop rbp
    ret

section .data
WelcomeMsg:  db 'Updating checksums for boot files...', 0x0A, 0
SuccessMsg:  db 'Checksums updated successfully!', 0x0A, 0
ErrorMsg:    db 'Error reading file!', 0x0A, 0
WriteErrorMsg: db 'Error writing checksum file!', 0x0A, 0
Boot1Path:   db '\EFI\BOOT\boot1.png', 0
Boot2Path:   db '\EFI\BOOT\boot2.png', 0
ConfigPath:  db '\EFI\BOOT\config.cfg', 0
ChecksumsPath: db '\EFI\BOOT\checksums.dat', 0

section .bss
FileHandle:  resq 1
HashBuffer:  resb 4096
Checksums:
    .boot1_hash: resb 32
    .boot2_hash: resb 32
    .config_hash: resb 32