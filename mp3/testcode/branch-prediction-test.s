#  mp3-cp3.s version 1.2
.align 4
.section .text
.globl _start
_start:

#jal uses x1

add  x3, x0, x0
lw  x2, HUNDRED

loop:
    addi x3, x3, 1
    #jal outside
#back:    
    blt  x3, x2, loop
halt:
    beq x0, x0, halt
    lw x7, BAD

#outside:
#    bne x0, x0, back
#    jal back




.section .rodata
.balign 256
HUNDRED:    .word  0x00000064
BAD:            .word 0x00BADBAD
