.include "m2560def.inc"

.cseg
.org 0x0000
    rjmp RESET

RESET:
    ldi r16, 0x00

LOOP:
    rjmp LOOP