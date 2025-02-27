; Checksum file format and functions
BITS 64
DEFAULT REL

%include "src/efi.inc"

section .data
global Checksums
Checksums:
    .boot1_hash:    resb 32    ; SHA-256 hash for boot1.png
    .boot2_hash:    resb 32    ; SHA-256 hash for boot2.png
    .config_hash:   resb 32    ; SHA-256 hash for config.cfg
ChecksumsPath:   db '\EFI\BOOT\checksums.dat', 0

section .text
global load_checksums
global verify_checksum
global save_checksums

; Load checksums from file
load_checksums:
    push rbp
    mov rbp, rsp
    
    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]
    
    ; Open checksums file
    lea rdx, [ChecksumsPath]
    mov r8, EFI_FILE_READ
    lea r9, [FileHandle]
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax
    
    ; Read checksums
    mov rcx, [FileHandle]
    lea rdx, [Checksums]
    mov r8, 96              ; 32 bytes * 3 hashes
    lea r9, [BytesRead]
    mov rax, [rcx + EFI_FILE_READ]
    call rax
    
    mov rsp, rbp
    pop rbp
    ret

; Verify file against stored checksum
; Input: rdx = file path, rcx = checksum offset
verify_checksum:
    push rbp
    mov rbp, rsp
    
    ; TODO: Calculate file hash and compare with stored
    ; For now, return success
    xor rax, rax
    
    mov rsp, rbp
    pop rbp
    ret

section .bss
FileHandle:    resq 1
BytesRead:     resq 1
