; Boot logo handling functionality
BITS 64
DEFAULT REL

%include "src/efi.inc"

; External symbols from boot.asm
extern SystemTable
extern ImageHandle
extern print_string
extern verify_checksum ; From checksums.h

section .text
global load_boot_logo
global display_setup_logo

; Initialize Graphics Output Protocol
init_gop:
    push rbp
    mov rbp, rsp

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [InitGopMsg]
    call print_string
    pop rcx

    ; Get boot services
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; Locate GOP protocol
    lea rdx, [GopGuid]      ; GUID for GOP
    xor r8, r8              ; No handle
    xor r9, r9              ; No registration
    lea r10, [GopHandle]    ; Interface
    mov rax, [rcx + EFI_BOOT_GRAPHICS_OUTPUT]
    call rax

    test rax, rax           ; Check for success
    jnz .error

    ; Print success message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [GopInitOkMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

.error:
    ; Print error message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [GopInitFailMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    mov rax, 1              ; Return error
    ret

; Load PNG file with integrity check
load_png:
    push rbp
    mov rbp, rsp

    ; Verify file checksum first
    mov rdx, [ImagePath]
    mov rcx, [ChecksumOffset]
    call verify_checksum
    test rax, rax
    jnz .checksum_error

    ; Print debug message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [LoadingLogoMsg]
    call print_string
    pop rcx

    ; Get boot services for file operations
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_BOOT]

    ; Open boot logo file
    mov rdx, [ImagePath]     ; Path from parameter
    mov r8, EFI_FILE_READ   ; Open for reading
    lea r9, [FileHandle]    ; File handle
    mov rax, [rcx + EFI_FILE_OPEN]
    call rax

    test rax, rax           ; Check for success
    jnz .error

    ; Print file open success
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [LogoOpenOkMsg]
    call print_string
    pop rcx

    ; Read PNG header
    mov rcx, [FileHandle]
    lea rdx, [PngHeader]
    mov r8, PNG_HEADER_size
    lea r9, [BytesRead]
    mov rax, [rcx + EFI_FILE_READ]
    call rax

    ; Save dimensions from PNG header
    mov eax, [PngHeader + PNG_HEADER.Width]
    mov [Width], eax
    mov eax, [PngHeader + PNG_HEADER.Height]
    mov [Height], eax

    mov rsp, rbp
    pop rbp
    ret

.error:
    ; Print error message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [LogoOpenFailMsg]
    call print_string
    pop rcx

    mov rsp, rbp
    pop rbp
    mov rax, 1             ; Return error
    ret

.checksum_error:
    ; Print error message
    push rcx
    mov rcx, [SystemTable]
    mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
    lea rdx, [ChecksumFailMsg]
    call print_string
    pop rcx

    cli                    ; Disable interrupts
    hlt                    ; Halt system - Logo integrity compromised

; Display logo using GOP
display_logo:
    push rbp
    mov rbp, rsp

    ; Get GOP handle
    mov rcx, [GopHandle]
    test rcx, rcx
    jz .error

    ; Use GOP Blt to display the image
    mov rdx, [ImageBuffer]  ; Source buffer
    xor r8, r8              ; Operation (EfiBltBufferToVideo)
    xor r9, r9              ; Source X
    mov r10, 0              ; Source Y
    mov r11, 0              ; Dest X
    mov r12, 0              ; Dest Y
    mov r13, [Width]        ; Width
    mov r14, [Height]       ; Height
    xor r15, r15           ; Source Delta

    mov rax, [rcx + EFI_GOP_BLT]
    call rax

    mov rsp, rbp
    pop rbp
    xor rax, rax           ; Return success
    ret

.error:
    mov rsp, rbp
    pop rbp
    mov rax, 1             ; Return error
    ret

; Load and display boot kernel logo
load_boot_logo:
    push rbp
    mov rbp, rsp

    ; Set path to boot1.png and its checksum offset
    lea rax, [Boot1Path]
    mov [ImagePath], rax
    mov qword [ChecksumOffset], 0  ; Offset to boot1.png hash in checksums.dat

    call init_gop
    test rax, rax
    jnz .error

    call load_png
    test rax, rax
    jnz .error

    call display_logo

    mov rsp, rbp
    pop rbp
    xor rax, rax           ; Return success
    ret

.error:
    mov rsp, rbp
    pop rbp
    mov rax, 1             ; Return error
    ret

; Display BIOS/QEMU setup logo
display_setup_logo:
    push rbp
    mov rbp, rsp

    ; Set path to boot2.png and its checksum offset
    lea rax, [Boot2Path]
    mov [ImagePath], rax
    mov qword [ChecksumOffset], 32  ; Offset to boot2.png hash in checksums.dat

    call init_gop
    test rax, rax
    jnz .error

    call load_png
    test rax, rax
    jnz .error

    call display_logo

    mov rsp, rbp
    pop rbp
    xor rax, rax           ; Return success
    ret

.error:
    mov rsp, rbp
    pop rbp
    mov rax, 1             ; Return error
    ret

section .data
Boot1Path:      db '\EFI\BOOT\boot1.png', 0
Boot2Path:      db '\EFI\BOOT\boot2.png', 0
GopGuid:        db 0x9D, 0xE9, 0x71, 0x30, 0xDD, 0x4B, 0x11, 0xD4
                db 0x9A, 0x38, 0x00, 0x90, 0x27, 0x3F, 0xC1, 0x4D
Width:          dd 0
Height:         dd 0

; Debug messages
InitGopMsg:     db 'Initializing Graphics Output Protocol...', 0x0D, 0x0A, 0
GopInitOkMsg:   db 'GOP initialized successfully', 0x0D, 0x0A, 0
GopInitFailMsg: db 'Failed to initialize GOP', 0x0D, 0x0A, 0
LoadingLogoMsg: db 'Loading boot logo from: ', 0
LogoOpenOkMsg:  db 'Boot logo file opened successfully', 0x0D, 0x0A, 0
LogoOpenFailMsg:db 'Failed to open boot logo file', 0x0D, 0x0A, 0
ChecksumFailMsg:db 'ERROR: Logo checksum verification failed! System halted.', 0x0D, 0x0A, 0

section .bss
GopHandle:    resq 1
FileHandle:   resq 1
PngHeader:    resb PNG_HEADER_size
BytesRead:    resq 1
ImageBuffer:  resb 1024*768*4  ; Buffer for 1024x768 32-bit image
ImagePath:    resq 1           ; Current image path pointer
ChecksumOffset: resq 1         ; Offset in checksums.dat file for current image

section .note.GNU-stack noalloc noexec nowrite progbits