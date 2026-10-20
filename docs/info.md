<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Initial version of project will encrypt or decrypt one 64-bit data block using a 64-bit DES key.

## How to test

Using mode 0 SPI connection, send three 9-byte messages. The first has command byte KEY followed by 8 byte key value. The second has command byte DATA+ENCRYPT or DATA+DECRYPT followed by 8 byte data value. The third has 0 command byte and 8 bytes dummy data, to enable reading back the encryped or decrypted result.

## External hardware

Connect using standard SPI PMOD, or SPI pin assignments on TT dev board.
