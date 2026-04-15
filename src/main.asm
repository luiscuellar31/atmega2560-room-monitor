.include "m2560def.inc"

; ==================================================
; Definición de registros de trabajo
; ==================================================
.def temp        = r16
.def adc_temp    = r17
.def adc_luz     = r18
.def adc_ruido   = r19
.def cont1       = r20
.def cont2       = r21
.def cont3       = r22
.def cond_count  = r23
.def ruido_hold  = r24

; ==================================================
; Umbrales de detección y retención de ruido
; ==================================================
.equ UMBRAL_TEMP   = 15
.equ UMBRAL_LUZ    = 80
.equ UMBRAL_RUIDO  = 20
.equ HOLD_RUIDO    = 20

; ==================================================
; Vector de reset
; ==================================================
.cseg
.org 0x0000
    rjmp RESET

RESET:
    ; Inicialización de pila
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; Configuración de salidas:
    ; PB6 -> D12 -> LED temperatura
    ; PB5 -> D11 -> ventilador
    ; PB4 -> D10 -> LED de oscuridad
    sbi DDRB, 6
    sbi DDRB, 5
    sbi DDRB, 4

    ; PH6 -> D9  -> LED de ruido
    ; PH5 -> D8  -> buzzer
    lds temp, DDRH
    ori temp, (1<<6) | (1<<5)
    sts DDRH, temp

    ; Estado inicial de salidas en puerto B
    cbi PORTB, 6
    cbi PORTB, 5
    cbi PORTB, 4

    ; Estado inicial de salidas en puerto H
    lds temp, PORTH
    andi temp, 0b10011111
    sts PORTH, temp

    ; Inicialización de retención de ruido
    clr ruido_hold

    ; Configuración del ADC:
    ; Referencia AVcc
    ; Ajuste a la izquierda
    ; Lectura en ADCH
    ; Prescaler = 128
    ldi temp, (1<<REFS0) | (1<<ADLAR)
    sts ADMUX, temp

    ldi temp, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
    sts ADCSRA, temp

LOOP:
    ; Reinicio de contador de condiciones activas
    clr cond_count

    ; ==================================================
    ; Lectura de temperatura en ADC0 (A0)
    ; ==================================================
    ldi temp, (1<<REFS0) | (1<<ADLAR) | 0
    sts ADMUX, temp

    lds temp, ADCSRA
    ori temp, (1<<ADSC)
    sts ADCSRA, temp

ESPERA_ADC_TEMP:
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp ESPERA_ADC_TEMP

    lds adc_temp, ADCH

    cpi adc_temp, UMBRAL_TEMP
    brlo TEMP_BAJA

TEMP_ALTA:
    sbi PORTB, 6
    sbi PORTB, 5
    inc cond_count
    rjmp LEER_LUZ

TEMP_BAJA:
    cbi PORTB, 6
    cbi PORTB, 5

LEER_LUZ:
    ; ==================================================
    ; Lectura de luz en ADC1 (A1)
    ; ==================================================
    ldi temp, (1<<REFS0) | (1<<ADLAR) | 1
    sts ADMUX, temp

    lds temp, ADCSRA
    ori temp, (1<<ADSC)
    sts ADCSRA, temp

ESPERA_ADC_LUZ:
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp ESPERA_ADC_LUZ

    lds adc_luz, ADCH

    cpi adc_luz, UMBRAL_LUZ
    brlo OSCURO

CLARO:
    cbi PORTB, 4
    rjmp LEER_RUIDO

OSCURO:
    sbi PORTB, 4
    inc cond_count

LEER_RUIDO:
    ; ==================================================
    ; Lectura de ruido en ADC2 (A2)
    ; ==================================================
    ldi temp, (1<<REFS0) | (1<<ADLAR) | 2
    sts ADMUX, temp

    lds temp, ADCSRA
    ori temp, (1<<ADSC)
    sts ADCSRA, temp

ESPERA_ADC_RUIDO:
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp ESPERA_ADC_RUIDO

    lds adc_ruido, ADCH

    ; Si hay ruido real, recargar retención
    cpi adc_ruido, UMBRAL_RUIDO
    brlo REVISAR_HOLD_RUIDO

CON_RUIDO_REAL:
    ldi ruido_hold, HOLD_RUIDO

    lds temp, PORTH
    ori temp, (1<<6)
    sts PORTH, temp

    inc cond_count
    rjmp EVALUAR_ALARMA

REVISAR_HOLD_RUIDO:
    cpi ruido_hold, 0
    breq SIN_RUIDO

    dec ruido_hold

    lds temp, PORTH
    ori temp, (1<<6)
    sts PORTH, temp

    inc cond_count
    rjmp EVALUAR_ALARMA

SIN_RUIDO:
    lds temp, PORTH
    andi temp, 0b10111111
    sts PORTH, temp

EVALUAR_ALARMA:
    ; ==================================================
    ; Lógica de alarma general
    ;
    ; 3 condiciones:
    ;   - LEDs permanecen encendidos
    ;   - buzzer intermitente
    ;
    ; 0, 1 o 2 condiciones:
    ;   - buzzer apagado
    ; ==================================================
    cpi cond_count, 3
    breq ALARMA_TOTAL

    rjmp BUZZER_OFF

ALARMA_TOTAL:
    ; Mantener encendidos los LEDs ya activados
    ; Activar buzzer de forma intermitente
    lds temp, PORTH
    ori temp, (1<<5)
    sts PORTH, temp

    rcall RETARDO_BUZZER

    lds temp, PORTH
    andi temp, 0b11011111
    sts PORTH, temp

    rcall RETARDO_BUZZER

    rjmp LOOP

BUZZER_OFF:
    ; Buzzer apagado con 0, 1 o 2 condiciones
    lds temp, PORTH
    andi temp, 0b11011111
    sts PORTH, temp

    ; Si hay ruido activo, mantenerlo visible un poco
    cpi ruido_hold, 0
    breq FIN_LOOP

    rcall RETARDO_RUIDO

FIN_LOOP:
    rjmp LOOP

; ==================================================
; Retardo corto para mantener visible el LED de ruido
; ==================================================
RETARDO_RUIDO:
    ldi cont1, 40

RR1:
    ldi cont2, 255

RR2:
    ldi cont3, 255

RR3:
    dec cont3
    brne RR3

    dec cont2
    brne RR2

    dec cont1
    brne RR1

    ret

; ==================================================
; Retardo para buzzer intermitente
; ==================================================
RETARDO_BUZZER:
    ldi cont1, 50

RB1:
    ldi cont2, 255

RB2:
    ldi cont3, 255

RB3:
    dec cont3
    brne RB3

    dec cont2
    brne RB2

    dec cont1
    brne RB1

    ret