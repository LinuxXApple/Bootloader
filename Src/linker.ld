OUTPUT_FORMAT("pei-x86-64")
OUTPUT_ARCH(i386:x86-64)

ENTRY(_start)
SECTIONS
{
    /* PE/COFF expects certain alignments */
    . = ALIGN(4096);
    .text : {
        *(.text)
    }

    . = ALIGN(4096);
    .data : {
        *(.data)
    }

    . = ALIGN(4096);
    .rdata : {
        *(.rdata)
        *(.rodata*)
    }

    . = ALIGN(4096);
    .bss : {
        *(.bss*)
    }
    .eh_frame : {
        *(.eh_frame*)
    }

    .note.gnu.build-id : {
        *(.note.gnu.build-id)
    }
}