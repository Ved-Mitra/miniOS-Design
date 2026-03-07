; Multiboot header constants
MB_ALIGN     equ  1 << 0
MB_MEMINFO   equ  1 << 1
MB_FLAGS     equ  MB_ALIGN | MB_MEMINFO
MB_MAGIC     equ  0x1BADB002
MB_CHECKSUM  equ -(MB_MAGIC + MB_FLAGS)

section .multiboot
    dd MB_MAGIC
    dd MB_FLAGS
    dd MB_CHECKSUM

section .bss
    resb 16384 ; 16 KB stack space
stack_top:

section .text
    global _start
_start:
    mov esp, stack_top
    extern kernel_main
    call kernel_main  ; Jump to our C code

.hang:
    hlt
    jmp .hang