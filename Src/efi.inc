; UEFI constants and structure definitions
%define EFI_SUCCESS 0

; EFI System Table offsets
%define EFI_SYSTEM_TABLE_HDRSIZE      24
%define EFI_SYSTEM_TABLE_FWVENDOR     (EFI_SYSTEM_TABLE_HDRSIZE + 0)
%define EFI_SYSTEM_TABLE_FWREV        (EFI_SYSTEM_TABLE_HDRSIZE + 8)
%define EFI_SYSTEM_TABLE_CONINHANDLE  (EFI_SYSTEM_TABLE_HDRSIZE + 12)
%define EFI_SYSTEM_TABLE_CONIN        (EFI_SYSTEM_TABLE_HDRSIZE + 16)
%define EFI_SYSTEM_TABLE_CONOUTHANDLE (EFI_SYSTEM_TABLE_HDRSIZE + 24)
%define EFI_SYSTEM_TABLE_CONOUT       (EFI_SYSTEM_TABLE_HDRSIZE + 32)
%define EFI_SYSTEM_TABLE_STDERR       (EFI_SYSTEM_TABLE_HDRSIZE + 48)
%define EFI_SYSTEM_TABLE_RUNTIME      (EFI_SYSTEM_TABLE_HDRSIZE + 56)
%define EFI_SYSTEM_TABLE_BOOT         (EFI_SYSTEM_TABLE_HDRSIZE + 64)

; Simple Text Input Protocol offsets
%define EFI_INPUT_RESET              0
%define EFI_INPUT_READKEY           16
%define EFI_INPUT_WAITFORKEY        24

; Simple Text Output Protocol offsets
%define EFI_OUTPUT_RESET            0
%define EFI_OUTPUT_STRING           8
%define EFI_OUTPUT_CLEARSCREEN     48

; Boot Services offsets
%define EFI_BOOT_GETMEMORYMAP      48
%define EFI_BOOT_ALLOCATEPAGES     64
%define EFI_BOOT_EXITBOOTSERVICES  96
%define EFI_BOOT_REBOOT           128
%define EFI_BOOT_LOADFILE         144
%define EFI_BOOT_GRAPHICS_OUTPUT  160

; Runtime Services offsets
%define EFI_RUNTIME_RESETTYPE      0
%define EFI_RUNTIME_RESETCOLD      1
%define EFI_RUNTIME_RESETWARM      2
%define EFI_RUNTIME_RESETSYSTEM    32
%define EFI_RUNTIME_ENTERSETUP     64

; Graphics output protocol
%define EFI_GOP_QUERYMODE          8
%define EFI_GOP_SETMODE           16
%define EFI_GOP_BLT               24

; File protocol
%define EFI_FILE_OPEN             8
%define EFI_FILE_READ            16
%define EFI_FILE_WRITE           32  ; Added write operation
%define EFI_FILE_CLOSE           24

; Input Key structure
struc EFI_INPUT_KEY
    .ScanCode:     resw 1
    .UnicodeChar:  resw 1
endstruc

; Boot configuration structure
struc BOOT_CONFIG
    .KernelPath:    resb 256
    .LogoPath:      resb 256
    .DefaultEntry:  resb 1
    .Timeout:       resb 1
    .Logo1Hash:     resb 32    ; SHA-256 hash of boot1.png
    .Logo2Hash:     resb 32    ; SHA-256 hash of boot2.png
    .ConfigHash:    resb 32    ; SHA-256 hash of config (excluding hash fields)
endstruc

; Image format structures
struc PNG_HEADER
    .Signature:    resb 8
    .IHDR_Length: resd 1
    .IHDR_Type:   resd 1
    .Width:       resd 1
    .Height:      resd 1
    .BitDepth:    resb 1
    .ColorType:   resb 1
    .Compression: resb 1
    .Filter:      resb 1
    .Interlace:   resb 1
endstruc