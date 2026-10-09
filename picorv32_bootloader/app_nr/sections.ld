MEMORY
{
    APPRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
    . = 0x10000000;

    .text : {
        . = ALIGN(4);
        KEEP(*(.text.start))
        *(.text.start)
        *(.text)
        *(.text*)
        . = ALIGN(4);
        _etext = .;
    } > APPRAM

    .rodata : {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
    } > APPRAM

    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        . = ALIGN(4);
        _edata = .;
    } > APPRAM

    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > APPRAM

    /DISCARD/ : {
        *(.note*)
        *(.comment)
        *(.eh_frame*)
    }
}
