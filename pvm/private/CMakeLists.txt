# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initalize pico_sdk from installed location
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_PATH "ADJUSTMEIFNEEDED")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(chall C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

# Add executable. Default name is the project name, version 0.1

add_executable(chall chall.c )


pico_generate_pio_header(chall ${CMAKE_CURRENT_LIST_DIR}/pio/custom_progs.pio)
pico_generate_pio_header(chall ${CMAKE_CURRENT_LIST_DIR}/pio/uart_tx.pio)
pico_generate_pio_header(chall ${CMAKE_CURRENT_LIST_DIR}/pio/uart_rx.pio)
pico_generate_pio_header(chall ${CMAKE_CURRENT_LIST_DIR}/pio/decoder.pio)

pico_set_program_name(chall "chall")
pico_set_program_version(chall "0.1")

pico_enable_stdio_uart(chall 1)
pico_enable_stdio_usb(chall 0)

# Add the standard library to the build
target_link_libraries(chall pico_stdlib hardware_pio)

pico_add_extra_outputs(chall)

