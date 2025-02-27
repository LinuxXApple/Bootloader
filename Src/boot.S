.section .text
.global _start

_start:
    # Disable interrupts
    cli

    # Setup stack
    movl $stack_top, %esp

    # Clear flags
    pushl $0
    popf

    # Initialize basic CPU features
    call cpu_init

    # Jump to C code
    call bootloader_main

    # Should never return, but if it does:
    cli
    hlt

.section .bss
.align 16
stack_bottom:
    .skip 16384 # 16 KB stack
stack_top:

.section .text
cpu_init:
    # Basic CPU initialization
    # Enable protected mode
    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0
    ret

# Add note GNU stack section for security
.section .note.GNU-stack,"",@progbits