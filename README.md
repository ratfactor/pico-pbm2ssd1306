# pico-pbm2ssd1306


**MOVED!** Hello, I am moving my repos to http://ratfactor.com/repos/
and setting them to read-only ("archived") on GitHub. Thank you, _-Dave_

This repo contains two things:

1. A Zig program that converts 1-bit ASCII PBM images
(easily created in many different raster graphics programs such as GIMP).

2. A Pico (RP2040) microcontroller program to receive images via UART serial
connection and display them on a 128x64 pixel OLED screen controlled by the
common SSD1306 chip. This program is written with the official Pico C SDK.

You can see these programs in action in the later part of my 2023: Year of
the Microcontroller "chapter" here:

https://ratfactor.com/mc2023/chapter4

## PBM converter (runs on a host computer)

The SSD1306 display RAM expects image data as 1-byte columns where each
of the 8 bits in a byte is a pixel in the column. There are 128 of these
1-byte columns per row. These rows are called "pages" and there are 8 of
them total on the display for 128 x 64 pixels total.

The PBM ASCII 1-bit image format is easily written (even by hand!) and
read with any text editor.

The `convert.zig` program takes a PBM image on STDIN and writes a binary
image in the format expected by the SSD1306 to STDOUT.

```
zig run convert.zig <foo.bpm >foo.bin
```

The `viewer.zig` program takes a converted SSD1306-compatible binary
image on STDIN and displays it as ASCII characters in the terminal.

```
zig run viewer.zig <foo.bin
```

You can also convert and view in one go by piping the converter output
to the viewer like so:

```
zig run convert.zig <foo.bpm | zig run viewer.zig
```

(You'll note that I'm running these programs as if they were scripts
for rapid testing and debugging purposes, but, of course, you can compile
them with Zig and run the compiled executables.)

## Pico SSD1306 init and image display via UART (runs on microcontroller)

These three files make a complete Pico C SDK-based program to run on the
microcontroller and display images on an attached OLED screen:

```
pico_sdk_import.cmake
CMakeLists.txt
oled3.c
```

(Sorry about the filename. It happens to be the third program I wrote
for this OLED device.)

To compile, you'll need to do the cmake dance:

```
mkdir build
cd build
cmake ..
cd ..
make
```

Setting up the SDK and getting the compiled program onto the Pico are
beyond anything this README could hope to cover, but the Raspberry Pi
people have that part well covered.

To send a converted binary image to the device, you can do something
like this on a Linux machine connected via UART:

```
stty -F /dev/serial0 9600
cat foo.bin > /dev/serial0
```

Good luck!
