//#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "hardware/i2c.h"

const uint LED1 = 25; // onboard led (pi pico board)

uint8_t addr = 0x3c; // My SSD1306 OLED device i2c address

uint8_t pixel_buffer[1025]; // screen's worth of pixels (8x128: page-cols) + data byte

void cmd(unsigned char byte){
        uint8_t cmd_pair[2] = {0x00, byte}; // 0x00 is control byte = command follows

        i2c_write_blocking(i2c0, addr, cmd_pair, 2, false);
}

void draw(){
	// The 0x40 byte means "Here somes some data!"
	// Last param true means "no stop bit" so the data can follow.
	//uint8_t data_byte[1] = {0x40};
	//i2c_write_blocking(i2c0, addr, data_byte, 1, true);

	// Here's the data. This DOES send the stop bit.
        i2c_write_blocking(i2c0, addr, pixel_buffer, 1025, false);
}

void clear(){
	int i;
	for(i = 1; i<1025; i++){
		pixel_buffer[i] = 0;
	}
	draw();
}

void checker(){
	int i;
	for(i = 1; i<1025; i++){
		 // every other byte is alternating 1010 or 0101...
		pixel_buffer[i] = i%2? 0xaa : 0x55;
	}
	draw();
}


int main() {
	// Setup pixel buffer
       	// Pixel data actually starts at 1, so we make a pointer to that.
	pixel_buffer[0]=0x40; // control byte means "here comes data!"
	uint8_t *pixel_draw_start = &pixel_buffer[1];

	// LEDs
	gpio_set_function(LED1, GPIO_FUNC_SIO);
	gpio_set_dir(LED1, true); // output

	// OLED SCREEN via SSD1306 controller
	// Setup i2c on gpio pins.
	i2c_init(i2c0, 1000000); 
	const uint SDA = 12;
	const uint SCL = 13;
	gpio_set_function(SDA, GPIO_FUNC_I2C); 
	gpio_set_function(SCL, GPIO_FUNC_I2C);
	gpio_pull_up(SDA);
	gpio_pull_up(SCL);

	// First, display off
	cmd(0xae);

	// Startline (0x40 is "zero", 0x41 is 1, etc.)
	cmd(0x40);

	// Mux ratio cmd - 15d to 63d
	cmd(0xa8);
	cmd(63);

	// Display offset 0d to 63d
	cmd(0xd3);
	cmd(0);

	// Set Segment Re-map: Flips display left-right
	// Mine has this ON.
	cmd(0xa1); // on
	//cmd(0xa0); // off

	// Com output scan direct (how pointer advancing works, default)
	// Flips image vertically.
	// Mine is flipped vertically!
	//cmd(0xc0); // normal
	cmd(0xc8); // flipped vertically

	// Com pin hardware (looks like has to do with direction of screen)
	cmd(0xda);
	//cmd(0x02); // "sequential pins"
	cmd(0x12);   // "alternative com pin config"
	//cmd(0x22); // "enable left/right pin remap"
	//cmd(0x32); // "BOTH alt pin config and l/r remap"

	// Contrast
	cmd(0x81);
	cmd(0x7f); // about middle

	// Resume displaying from ram (0xa5 is display all on)
	cmd(0xa4);

	// Addressing mode
	cmd(0x20);
	cmd(0x00); // horizontal

	// Set column addr (ONLY valid for horiz/vert modes above)
	cmd(0x21); // cmd
	cmd(0); // start (starts drawing here too)
	cmd(127); // end

	// Set page start/end addr (ONLY valid for horiz/vert modes)
	cmd(0x22); // cmd
	cmd(0); // start
	cmd(7); // end

	// Oscillator freq
	cmd(0xd4);
	cmd(0x80); // default

	// Enable charge pump (apparently vital!)
	cmd(0x8d);
	cmd(0x14);

	// Turn display on!
	cmd(0xaf);


	// Clear display and then show a checker pattern so we can tell
	// we've re-started. And makes debugging bad buffer drawing easier.

    //clear();
	checker();

	/*
     * TEST drawing:
	pixel_buffer[1] = 0x81; // First col (top and bottom pixel on)
	pixel_buffer[2] = 255;
	pixel_buffer[3] = 0x55;
	pixel_buffer[4] = 0xaa;
	pixel_buffer[12] = 255;
	pixel_buffer[13] = 0x55;
	pixel_buffer[14] = 0xaa;
	pixel_buffer[129] = 0x81;
	pixel_buffer[895] = 0x81; //second-to-last col on second-to-last page
	pixel_buffer[1024] = 0x81; //last col (top and bottom pixel on)
	draw();
	*/

	// setup uart for serial transfer
    // set on linux side with something like
    //     stty -F /dev/serial0 9600
	uart_init(uart0, 9600);
	gpio_set_function(1, GPIO_FUNC_UART);
	gpio_set_function(2, GPIO_FUNC_UART);
	uart_set_format(uart0, 8, 1, UART_PARITY_NONE);

	bool light_toggle = false;

	int read_bytes = 1024;

	while(true){
		uart_read_blocking(uart0, pixel_draw_start, read_bytes);
		draw();

        // Toggle led on and off every time we get a new image.
		if(light_toggle){
			gpio_put(LED1, 1);
		}
		else{
			gpio_put(LED1, 0);
		}
		light_toggle = !light_toggle;
	}
}

