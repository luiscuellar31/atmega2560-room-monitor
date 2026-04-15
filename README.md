# ATmega2560 Smart Room Monitor

A simple embedded monitoring system built on the ATmega2560 using AVR Assembly.

## Overview

This project monitors environmental conditions in a small room or study-area model using three analog sensors:

- LM35 temperature sensor
- LDR light sensor
- KY-038 analog sound sensor

According to the detected conditions, the system activates different outputs:

- Red warning LED for high temperature
- Yellow warning LED for low light
- Green warning LED for sound events
- 5V cooling fan
- Active buzzer alarm

## Project Objective

The objective of this project was to design and implement an embedded room-monitoring prototype using the ATmega2560 and AVR Assembly, integrating analog sensing and actuator control under predefined alarm conditions.

This work was developed as part of my Embedded Systems course project.

## Main Features

- Reads three analog sensors through the ADC
- Controls LEDs, fan, and buzzer directly from the microcontroller
- Built almost entirely in AVR Assembly
- Works as a standalone embedded system without requiring a PC during operation

## System Logic

### Temperature
If temperature exceeds the configured threshold:
- Red LED turns on
- Fan turns on

### Light
If the environment is dark:
- Yellow LED turns on

### Sound
If a strong sound event is detected:
- Green LED turns on

To improve event visibility, the sound indicator now uses a short hold window:
- After a valid sound event, the green LED remains active briefly even if the next sample falls below threshold.

### Alarm Conditions
- If **three abnormal conditions** are active at the same time, the buzzer sounds intermittently while active condition LEDs remain on
- If **zero, one, or two abnormal conditions** are active, the buzzer stays off

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

- `D12` -> Red temperature LED
- `D11` -> Fan control
- `D10` -> Yellow light warning LED
- `D9`  -> Green sound warning LED
- `D8`  -> Buzzer

## 3D Enclosure Files

The printable enclosure models are located in the `3d/` folder:

- `3d/room-monitor-box.stl` -> Main box
- `3d/room-monitor-lid.stl` -> Top lid

## Notes

- The LDR was used as the sensor selected for the technical explanation of non-linear behavior.
- Threshold values were adjusted experimentally during testing.
- The sound sensor responds better to sharp nearby acoustic events than to continuous speech.
- Current firmware includes a short noise hold (`HOLD_RUIDO`) to avoid losing brief sound events between ADC cycles.
