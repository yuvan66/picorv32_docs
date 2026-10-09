.section .text.start
.global _start
.global main

_start:
    /* Set stack pointer to top of 8 KB App RAM */
    la   sp, 0x10001ffc

    /* Clear BSS section */
    la   a0, _sbss
    la   a1, _ebss
    bge  a0, a1, bss_done
bss_loop:
    sw   zero, 0(a0)
    addi a0, a0, 4
    blt  a0, a1, bss_loop
bss_done:

    call main

hang:
    j    hang
