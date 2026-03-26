# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.triggers import ClockCycles
from cocotb.types import LogicArray


async def await_half_sclk(dut):
    """Wait for half of the SPI clock period."""
    start_time = cocotb.utils.get_sim_time(units="ns")
    while True:
        await ClockCycles(dut.clk, 1)
        if (start_time + 100 * 100 * 0.5) < cocotb.utils.get_sim_time(units="ns"):
            break


def ui_in_logicarray(ncs, bit, sclk):
    """Setup the ui_in value as a LogicArray."""
    return LogicArray(f"00000{ncs}{bit}{sclk}")


async def send_spi_transaction(dut, r_w, address, data):
    """
    Send an SPI transaction with format:
    - 1 bit for Read/Write
    - 7 bits for address
    - 8 bits for data

    Parameters:
    - r_w: boolean, True for write, False for read
    - address: int, 7-bit address (0-127)
    - data: LogicArray or int, 8-bit data
    """
    if isinstance(data, LogicArray):
        data_int = int(data)
    else:
        data_int = data

    if address < 0 or address > 127:
        raise ValueError("Address must be 7-bit (0-127)")
    if data_int < 0 or data_int > 255:
        raise ValueError("Data must be 8-bit (0-255)")

    first_byte = (int(r_w) << 7) | address

    sclk = 0
    ncs = 0
    bit = 0

    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 1)

    for i in range(8):
        bit = (first_byte >> (7 - i)) & 0x1
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

    for i in range(8):
        bit = (data_int >> (7 - i)) & 0x1
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

    sclk = 0
    ncs = 1
    bit = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 600)

    return ui_in_logicarray(ncs, bit, sclk)


async def setup_dut(dut):
    """Common clock/reset setup."""
    clock = Clock(dut.clk, 100, units="ns")  # 10 MHz
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = ui_in_logicarray(1, 0, 0)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_spi(dut):
    dut._log.info("Start SPI test")
    await setup_dut(dut)

    dut._log.info("Test project behavior")

    dut._log.info("Write transaction, address 0x00, data 0xF0")
    await send_spi_transaction(dut, 1, 0x00, 0xF0)
    assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Write transaction, address 0x01, data 0xCC")
    await send_spi_transaction(dut, 1, 0x01, 0xCC)
    assert dut.uio_out.value == 0xCC, f"Expected 0xCC, got {dut.uio_out.value}"
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x30 (invalid), data 0xAA")
    await send_spi_transaction(dut, 1, 0x30, 0xAA)
    await ClockCycles(dut.clk, 100)

    dut._log.info("Read transaction (invalid), address 0x00, data 0xBE")
    await send_spi_transaction(dut, 0, 0x30, 0xBE)
    assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
    await ClockCycles(dut.clk, 100)

    dut._log.info("Read transaction (invalid), address 0x41 (invalid), data 0xEF")
    await send_spi_transaction(dut, 0, 0x41, 0xEF)
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x02, data 0xFF")
    await send_spi_transaction(dut, 1, 0x02, 0xFF)
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x04, data 0xCF")
    await send_spi_transaction(dut, 1, 0x04, 0xCF)
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0xFF")
    await send_spi_transaction(dut, 1, 0x04, 0xFF)
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0x00")
    await send_spi_transaction(dut, 1, 0x04, 0x00)
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0x01")
    await send_spi_transaction(dut, 1, 0x04, 0x01)
    await ClockCycles(dut.clk, 30000)

    dut._log.info("SPI test completed successfully")


@cocotb.test()
async def test_pwm_freq(dut):
    dut._log.info("Start PWM frequency test")
    await setup_dut(dut)

    # Enable uo_out[0]
    await send_spi_transaction(dut, 1, 0x00, 0x01)

    # Enable PWM on uo_out[0]
    await send_spi_transaction(dut, 1, 0x02, 0x01)

    # Set duty cycle to about 50%
    await send_spi_transaction(dut, 1, 0x04, 0x80)

    # Measure period using two rising edges
    await RisingEdge(dut.uo_out[0])
    t1 = cocotb.utils.get_sim_time(units="ns")

    await RisingEdge(dut.uo_out[0])
    t2 = cocotb.utils.get_sim_time(units="ns")

    period_ns = t2 - t1
    freq_hz = 1e9 / period_ns

    dut._log.info(f"Measured PWM frequency: {freq_hz} Hz")

    assert 2970 <= freq_hz <= 3030, f"Frequency out of range: {freq_hz} Hz"

    dut._log.info("PWM Frequency test completed successfully")


@cocotb.test()
async def test_pwm_duty(dut):
    dut._log.info("Start PWM duty cycle test")
    await setup_dut(dut)

    # Enable uo_out[0]
    await send_spi_transaction(dut, 1, 0x00, 0x01)

    # Enable PWM on uo_out[0]
    await send_spi_transaction(dut, 1, 0x02, 0x01)

    # Set duty cycle to about 50%
    duty_reg_value = 0x80
    await send_spi_transaction(dut, 1, 0x04, duty_reg_value)

    # Measure one PWM cycle
    await RisingEdge(dut.uo_out[0])
    t_rise1 = cocotb.utils.get_sim_time(units="ns")

    await FallingEdge(dut.uo_out[0])
    t_fall = cocotb.utils.get_sim_time(units="ns")

    await RisingEdge(dut.uo_out[0])
    t_rise2 = cocotb.utils.get_sim_time(units="ns")

    high_time_ns = t_fall - t_rise1
    period_ns = t_rise2 - t_rise1
    duty_percent = (high_time_ns / period_ns) * 100

    expected_duty = (duty_reg_value / 256) * 100

    dut._log.info(f"Measured PWM duty cycle: {duty_percent}%")
    dut._log.info(f"Expected PWM duty cycle: {expected_duty}%")

    assert abs(duty_percent - expected_duty) <= 1.0, (
        f"Duty cycle out of range: got {duty_percent}%, expected {expected_duty}%"
    )

    dut._log.info("PWM Duty Cycle test completed successfully")