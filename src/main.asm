.include "m2560def.inc"

.def temp      = r16
.def adc_val   = r17

.equ UMBRAL = 15

.cseg
.org 0x0000
    rjmp RESET

RESET:
    ;--------------------------------------------------
    ; Inicializar stack pointer
    ;--------------------------------------------------
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ;--------------------------------------------------
    ; Configurar salidas
    ; D12 = PB6 -> LED
    ; D11 = PB5 -> control del transistor / ventilador
    ;--------------------------------------------------
    sbi DDRB, 6          ; PB6 como salida
    sbi DDRB, 5          ; PB5 como salida

    cbi PORTB, 6         ; LED apagado al inicio
    cbi PORTB, 5         ; Ventilador apagado al inicio

    ;--------------------------------------------------
    ; Configurar ADC
    ; Canal: ADC0 = A0
    ; Referencia: AVcc
    ; Ajuste a la izquierda
    ; Leeremos ADCH (8 bits)
    ; Prescaler: 128
    ;--------------------------------------------------
    ldi temp, (1<<REFS0) | (1<<ADLAR)
    sts ADMUX, temp

    ldi temp, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
    sts ADCSRA, temp

LOOP:
    ;--------------------------------------------------
    ; Iniciar conversión ADC
    ;--------------------------------------------------
    lds temp, ADCSRA
    ori temp, (1<<ADSC)
    sts ADCSRA, temp

ESPERA_ADC:
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp ESPERA_ADC

    ;--------------------------------------------------
    ; Leer valor de 8 bits
    ;--------------------------------------------------
    lds adc_val, ADCH

    ;--------------------------------------------------
    ; Comparar con umbral
    ;--------------------------------------------------
    cpi adc_val, UMBRAL
    brlo APAGAR_TODO

ENCENDER_TODO:
    ; Encender LED
    sbi PORTB, 6
    ; Encender ventilador
    sbi PORTB, 5
    rjmp LOOP

APAGAR_TODO:
    ; Apagar LED
    cbi PORTB, 6
    ; Apagar ventilador
    cbi PORTB, 5
    rjmp LOOP