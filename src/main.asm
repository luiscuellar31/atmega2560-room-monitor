.include "m2560def.inc"

.def temp        = r16
.def adc_temp    = r17
.def adc_luz     = r18
.def adc_ruido   = r19
.def cont1       = r20
.def cont2       = r21
.def cont3       = r22
.def cond_count  = r23

.equ UMBRAL_TEMP   = 15
.equ UMBRAL_LUZ    = 80
.equ UMBRAL_RUIDO  = 30

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
    ; D12 = PB6 -> LED temperatura
    ; D11 = PB5 -> ventilador
    ; D10 = PB4 -> LED amarillo (oscuridad)
    ; D9  = PH6 -> LED rojo (ruido)
    ; D8  = PH5 -> buzzer
    ;--------------------------------------------------
    sbi DDRB, 6
    sbi DDRB, 5
    sbi DDRB, 4

    ; DDRH bit 6 = 1  (LED rojo)
    ; DDRH bit 5 = 1  (buzzer)
    lds temp, DDRH
    ori temp, (1<<6) | (1<<5)
    sts DDRH, temp

    cbi PORTB, 6
    cbi PORTB, 5
    cbi PORTB, 4

    ; Apagar LED rojo y buzzer al inicio
    lds temp, PORTH
    andi temp, 0b10011111
    sts PORTH, temp

    ;--------------------------------------------------
    ; Configurar ADC
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
    ; Reiniciar contador de condiciones anormales
    ;--------------------------------------------------
    clr cond_count

    ;==================================================
    ; LEER TEMPERATURA EN ADC0 = A0
    ;==================================================
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
    sbi PORTB, 6      ; LED temperatura ON
    sbi PORTB, 5      ; Ventilador ON
    inc cond_count
    rjmp LEER_LUZ

TEMP_BAJA:
    cbi PORTB, 6      ; LED temperatura OFF
    cbi PORTB, 5      ; Ventilador OFF

LEER_LUZ:
    ;==================================================
    ; LEER LUZ EN ADC1 = A1
    ;==================================================
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

    ; Si adc_luz < UMBRAL_LUZ => oscuro
    cpi adc_luz, UMBRAL_LUZ
    brlo OSCURO

CLARO:
    cbi PORTB, 4      ; LED amarillo OFF
    rjmp LEER_RUIDO

OSCURO:
    sbi PORTB, 4      ; LED amarillo ON
    inc cond_count

LEER_RUIDO:
    ;==================================================
    ; LEER RUIDO EN ADC2 = A2
    ;==================================================
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

    ; Si adc_ruido >= UMBRAL_RUIDO => mucho ruido
    cpi adc_ruido, UMBRAL_RUIDO
    brlo SIN_RUIDO

CON_RUIDO:
    ; Encender LED rojo (PH6)
    lds temp, PORTH
    ori temp, (1<<6)
    sts PORTH, temp

    inc cond_count
    rjmp EVALUAR_BUZZER

SIN_RUIDO:
    ; Apagar LED rojo (PH6)
    lds temp, PORTH
    andi temp, 0b10111111
    sts PORTH, temp

EVALUAR_BUZZER:
    ;--------------------------------------------------
    ; Si hay 2 o más condiciones anormales -> buzzer ON
    ; Si no -> buzzer OFF
    ;--------------------------------------------------
    cpi cond_count, 2
    brlo BUZZER_OFF

BUZZER_ON:
    lds temp, PORTH
    ori temp, (1<<5)      ; PH5 = buzzer ON
    sts PORTH, temp
    rjmp FINAL_LOOP

BUZZER_OFF:
    lds temp, PORTH
    andi temp, 0b11011111 ; PH5 = buzzer OFF
    sts PORTH, temp

FINAL_LOOP:
    ;--------------------------------------------------
    ; Si hubo ruido, mantener LED rojo (y buzzer si aplica)
    ; un poco más para que se note
    ;--------------------------------------------------
    cpi adc_ruido, UMBRAL_RUIDO
    brlo SIN_RETARDO

    rcall RETARDO_RUIDO

SIN_RETARDO:
    rjmp LOOP

;==================================================
; RETARDO PARA QUE EL LED ROJO DURE MAS ENCENDIDO
;==================================================
RETARDO_RUIDO:
    ldi cont1, 120

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