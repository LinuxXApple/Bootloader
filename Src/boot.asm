; UEFI bootloader entry point
BITS 64
DEFAULT REL

%include "src/efi.inc"

section .text
global efi_main
global ImageHandle
global SystemTable
global print_string
extern menu_main
extern load_boot_logo

; Function to print a string
print_string:
    ; Input: rdx = string pointer, rcx = ConOut pointer
    push rbp
    mov rbp, rsp

    ; Call OutputString
    mov rax, [rcx + EFI_OUTPUT_STRING]
    call rax

    mov rsp, rbp
    pop rbp
    ret

efi_main:
    ; Save parameters passed by UEFI firmware
    push rbp
    mov rbp, rsp

    ; Store parameters (SystemTable in rdx, ImageHandle in rcx)
    mov [SystemTable], rdx
    mov [ImageHandle], rcx

    ; Initialize output
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]

    ; Clear screen
    mov rax, [rcx + EFI_OUTPUT_CLEARSCREEN]
    call rax

    ; Load and display boot logo
    call load_boot_logo

    ; Print welcome message
    lea rdx, [WelcomeMsg]
    call print_string

    ; Jump to main menu
    call menu_main

    ; Return EFI_SUCCESS (0)
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

section .data
WelcomeMsg:      db 'UEFI Bootloader Started', 0x0D, 0x0A, 0
ClearScreen:     db 0x1B, '[', '2', 'J', 0x1B, '[', 'H', 0  ; ANSI clear screen sequence
ImageHandle:     dq 0
SystemTable:     dq 0

section .note.GNU-stack noalloc noexec nowrite progbits