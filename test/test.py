# SPDX-FileCopyrightText: © 2026 Richard Miller
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import os

ASSERT = True
if "NOASSERT" in os.environ:
	ASSERT = False

sclk_period = 60 # ns
KEY = 0
BLOCK = 1
ENCRYPT = 2
DECRYPT = 3

async def transaction(dut, cmd, data):
	SS = dut.uio_in[0]
	SS.value = 0
	await Timer(sclk_period*2, units="ns")
	await spitrans(dut, cmd, 8)
	rx = await spitrans(dut, data, 64)
	await Timer(sclk_period*2, units="ns")
	SS.value = 1
	await Timer(sclk_period*2, units="ns")
	return rx

async def spitrans(dut, tx, len):
	MOSI = dut.uio_in[1]
	MISO = dut.uio_out[2]
	SCLK = dut.uio_in[3]
	rx = 0
	for i in range(len-1, -1, -1):
		MOSI.value = (tx>>i) & 1
		await Timer(sclk_period/2, units="ns")
		SCLK.value = 1
		rx |= (MISO.value<<i)
		await Timer(sclk_period/2, units="ns")
		SCLK.value = 0
	return rx

@cocotb.test()
async def test(dut):

	#dut.VPWR.value = 1
	#dut.VGND.value = 0

	# clock frequency 100 MHz
	clock = Clock(dut.clk, 10, units="ns")
	cocotb.start_soon(clock.start())

	# Reset
	dut.ena.value = 1
	dut.rst_n.value = 0
	dut.uio_in.value = 0
	dut.uio_in.value[2] = 1
	await ClockCycles(dut.clk, 2)
	dut.rst_n.value = 1
	await ClockCycles(dut.clk, 1)

	key = 0x7CA110454A1A6E57
	plaintext = 0x01A1D6D039776742
	ciphertext = 0x690F5B0D9A26939B

	# request encryption
	await transaction(dut, 1<<KEY, key)
	await transaction(dut, (1<<BLOCK) | (1<<ENCRYPT), plaintext)
	await ClockCycles(dut.clk, 20)
	result = await transaction(dut, 0, 0)
	assert result == ciphertext

	# request decryption
	await transaction(dut, 1<<KEY, key)
	await transaction(dut, (1<<BLOCK) | (1<<DECRYPT), ciphertext)
	await ClockCycles(dut.clk, 20)
	result = await transaction(dut, 0, 0)
	assert result == plaintext

	# triple DES with two keys - encrypt and decrypt
	key1 = 0x5555555555555555
	key2 = 0xAAAAAAAAAAAAAAAA
	plaintext = 0x0102030405060708
	ciphertext = 0x361A24BBAC74EF0B

	await transaction(dut, (1<<BLOCK), plaintext)
	await transaction(dut, (1<<KEY) | (1<<ENCRYPT), key1)
	await transaction(dut, (1<<KEY) | (1<<DECRYPT), key2)
	await transaction(dut, (1<<KEY) | (1<<ENCRYPT), key1)
	result = await transaction(dut, 0, 0)
	assert result == ciphertext
	await transaction(dut, (1<<KEY) | (1<<DECRYPT), key1)
	await transaction(dut, (1<<KEY) | (1<<ENCRYPT), key2)
	await transaction(dut, (1<<KEY) | (1<<DECRYPT), key1)
	result = await transaction(dut, 0, 0)
	assert result == plaintext
