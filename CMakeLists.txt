cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(oled3 C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
pico_sdk_init()

add_executable(oled3 oled3.c)

#pico_enable_stdio_usb(oled3 1)
#pico_enable_stdio_uart(oled3 1)

target_link_libraries(oled3 pico_stdlib hardware_i2c)
pico_add_extra_outputs(oled3)
