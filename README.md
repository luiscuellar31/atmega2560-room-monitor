# ATmega2560 Smart Room Monitor

A simple embedded monitoring system built on the ATmega2560 using AVR Assembly.

## Overview

This project monitors environmental conditions in a small room or study-area model using three analog sensors:

- LM35 temperature sensor
- LDR light sensor
- KY-038 analog sound sensor

According to the detected conditions, the system activates different outputs:

- Temperature LED
- Yellow warning LED for low light
- Red warning LED for sound events
- 5V cooling fan
- Active buzzer alarm

## Main Features

- Reads three analog sensors through the ADC
- Controls LEDs, fan, and buzzer directly from the microcontroller
- Built almost entirely in AVR Assembly
- Works as a standalone embedded system without requiring a PC during operation

## System Logic

### Temperature
If temperature exceeds the configured threshold:
- Temperature LED turns on
- Fan turns on

### Light
If the environment is dark:
- Yellow LED turns on

### Sound
If a strong sound event is detected:
- Red LED turns on

### Alarm Conditions
- If **two abnormal conditions** are active at the same time, the buzzer sounds intermittently
- If **three abnormal conditions** are active at the same time, the three LEDs blink and the buzzer behaves like an alarm

## Hardware Used

- Arduino Mega 2560 / ATmega2560
- LM35
- LDR
- KY-038
- Active 5V buzzer
- 5V fan
- 2N2222 transistor
- 1N4007 diode
- LEDs
- Resistors
- Breadboard and jumper wires

## ADC Channels

- `A0` -> LM35
- `A1` -> LDR
- `A2` -> KY-038 analog output

## Output Pins

- `D12` -> Temperature LED
- `D11` -> Fan control
- `D10` -> Light warning LED
- `D9`  -> Sound warning LED
- `D8`  -> Buzzer

## Notes

- The LDR was used as the sensor selected for the technical explanation of non-linear behavior.
- Threshold values were adjusted experimentally during testing.
- The sound sensor responds better to sharp nearby acoustic events than to continuous speech.