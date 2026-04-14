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
    ; Configurar LED externo en pin digital 12
    ; En Arduino Mega 2560, D12 = PB6
    ;--------------------------------------------------
    sbi DDRB, 6          ; PB6 como salida
    cbi PORTB, 6         ; LED apagado al inicio

    ;--------------------------------------------------
    ; Configurar ADC
    ; Canal: ADC0 = A0
    ; Referencia: AVcc
    ; Ajuste a la izquierda (leeremos ADCH)
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
    ; Leer resultado de 8 bits desde ADCH
    ;--------------------------------------------------
    lds adc_val, ADCH

    ;--------------------------------------------------
    ; Comparar con umbral
    ; Si adc_val >= UMBRAL, encender LED
    ; Si adc_val < UMBRAL, apagar LED
    ;--------------------------------------------------
    cpi adc_val, UMBRAL
    brlo LED_OFF

LED_ON:
    sbi PORTB, 6
    rjmp LOOP

LED_OFF:
    cbi PORTB, 6
    rjmp LOOP