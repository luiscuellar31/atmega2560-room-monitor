.include "m2560def.inc"

.def temp = r16
.def cont1 = r17
.def cont2 = r18
.def cont3 = r19

.cseg
.org 0x0000
    rjmp RESET

RESET:
    ; Configurar stack pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; Configurar PB7 como salida
    sbi DDRB, 7

LOOP:
    ; Encender LED integrado (PB7 = 1)
    sbi PORTB, 7
    rcall DELAY

    ; Apagar LED integrado (PB7 = 0)
    cbi PORTB, 7
    rcall DELAY

    rjmp LOOP

;--------------------------------------------------
; Retardo por software
;--------------------------------------------------
DELAY:
    ldi cont1, 255

D1:
    ldi cont2, 255

D2:
    ldi cont3, 255

D3:
    dec cont3
    brne D3

    dec cont2
    brne D2

    dec cont1
    brne D1

    ret