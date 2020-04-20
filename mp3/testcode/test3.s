# testing the pipeline static branching

#  mp3-cp2.s version 1.0
.align 4
.section .text
.globl _start
_start:
    nop
    nop
    lw x0, %lo(W)(x8)
    nop
 
inf:
   beq x0, x0, inf
	
.section .rodata
.balign 256
W:    	.word 0x00000001