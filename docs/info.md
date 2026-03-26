<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements an SPI-controlled PWM peripheral for Tiny Tapeout.

## How to test

## Features
- SPI write transactions
- Register-controlled outputs
- PWM signal generation
- 16 output bits across uo_out and uio_out

## Register Map
- 0x00: en_reg_out_7_0
- 0x01: en_reg_out_15_8
- 0x02: en_reg_pwm_7_0
- 0x03: en_reg_pwm_15_8
- 0x04: pwm_duty_cycle

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
