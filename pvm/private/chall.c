#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/pio.h"
#include "uart_tx.pio.h"
#include "uart_rx.pio.h"
#include "decoder.pio.h"
#include "custom_progs.pio.h"
#include "ops.h"

#define DEBUG 1

#define INSN_OUT_PIN 22
#define INSN_IN_PIN  2

#define SM_A_TX_PIN 21
#define SM_A_RX_PIN  20

#define PROG_A_RX_PIN 3
#define PROG_A_TX_PIN  4


#define OP1(X)    X << 1
#define INSN(X)   X << 1 | 0x1

#define DEOP1(X)  X >> 1
#define DEINSN(X) X >> 2


// expected flag: tstlss{p10_m4dn3ss}
char prog[] = {

    // PROG PART 1: ASK FOR FLAG
    OP1('E'), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(41), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(6), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(15), INSN(OP_SUB),
    INSN(OP_UART_TX),
    OP1(13), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(0x20), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1('F'), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(38), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(11), INSN(OP_SUB),
    INSN(OP_UART_TX),
    OP1(6), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(':'), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(0x20), INSN(OP_SET_A),
    INSN(OP_UART_TX),


    // PROG PART 2: GET FLAG (pc:36)
    OP1(0x00), INSN(OP_STR), // Write offset to 0x00
    // LOOP Entry
    OP1(0x00), INSN(OP_LDR),
    INSN(OP_UART_RX), //Read byte to offset
    INSN(OP_LDR),
    INSN(OP_UART_TX),

    OP1(0x00), INSN(OP_LDR),
    INSN(OP_INC),
    OP1(0x00), INSN(OP_STR),

    OP1(0x20+19), INSN(OP_CMP),
    //OP1(0x20+3), INSN(OP_CMP),

    OP1(38), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A), // Delay slot(?)

    // PROG PART 3: Validate Flag FMT (pc:54)
    OP1(80), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A), // Delay slot(?)

    //Exit if need be
    INSN(OP_GET_A), // Delay slot(?)
    OP1(0xa), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(0xd), INSN(OP_SET_A),
    INSN(OP_UART_TX),

    OP1('W'), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(5), INSN(OP_SUB),
    INSN(OP_UART_TX),
    OP1(3), INSN(OP_SUB),
    INSN(OP_UART_TX),
    INSN(OP_DEC),
    INSN(OP_UART_TX),
    OP1(7), INSN(OP_SUB),
    INSN(OP_UART_TX),
    INSN(OP_EXIT), // Early abort (pc: 58)


    //AAAA


    OP1('t'), INSN(OP_SET_A),
    OP1(0x00), INSN(OP_STR),
    INSN(OP_DEC),
    OP1(0x01), INSN(OP_STR),



    // 3.a) compare 't'
    OP1(0x20), INSN(OP_LDR),
    OP1(0x00), INSN(OP_CMP_MEM),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    OP1(0x22), INSN(OP_LDR),
    OP1(0x00), INSN(OP_CMP_MEM),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),


    // 3.a) compare 's'
    OP1(0x21), INSN(OP_LDR),
    OP1(0x01), INSN(OP_CMP_MEM),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    OP1(0x24), INSN(OP_LDR),
    OP1(0x01), INSN(OP_CMP_MEM),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    OP1(0x25), INSN(OP_LDR),
    OP1(0x01), INSN(OP_CMP_MEM),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    // 3.a) compare rest
    OP1(0x23), INSN(OP_LDR),
    OP1('l'), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    OP1(0x26), INSN(OP_LDR),
    OP1('{'), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),


    OP1(0x32), INSN(OP_LDR),
    OP1('}'), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),
    INSN(OP_GET_A),

    // PART 4: compare actual flag

    // pos1: '1' -> 2
    OP1(0x28), INSN(OP_LDR),
    INSN(OP_INC),
    OP1('1'), INSN(OP_SUB),
    OP1(0x40+2), INSN(OP_STR),

    // pos4: 'm' ->
    OP1(0x2b), INSN(OP_LDR),
    INSN(OP_DEC),
    OP1('m'-1), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),

    // pos7: 's'
    OP1(0x31), INSN(OP_LDR),
    OP1('s'), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),

    // pos0: 'p'
    OP1(0x27), INSN(OP_LDR),
    OP1('p'-1), INSN(OP_SUB),
    OP1(0x40+15), INSN(OP_STR),

    // pos3: '_'
    OP1(0x2a), INSN(OP_LDR),
    INSN(OP_INC),
    OP1('_'+1), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),


    // pos5: '4' -> 1
    OP1(0x2c), INSN(OP_LDR),
    OP1('4'-1), INSN(OP_SUB),
    OP1(0x40+1), INSN(OP_STR),

    // pos8: 's' -> 4
    OP1(0x30), INSN(OP_LDR),
    OP1('s'-1), INSN(OP_SUB),
    OP1(0x40+4), INSN(OP_STR),

    // pos7: 'n' -> 0
    OP1(0x2e), INSN(OP_LDR),
    OP1('n'-1), INSN(OP_SUB),
    OP1(0x40), INSN(OP_STR),

    // pos8: '3' -> 13
    OP1(0x2f), INSN(OP_LDR),
    OP1(13), INSN(OP_ADD),
    OP1('3'+12), INSN(OP_SUB),
    OP1(0x40+13), INSN(OP_STR),


    // pos2: '0' -> 5
    OP1(0x29), INSN(OP_LDR),
    OP1('0'-2), INSN(OP_SUB),
    INSN(OP_DEC),
    OP1(0x40+5), INSN(OP_STR),

    // pos6: 'd' -> 14
    OP1(0x2d), INSN(OP_LDR),
    INSN(OP_INV),
    OP1(0x12), INSN(OP_SUB),
    OP1(0x40+14), INSN(OP_STR),


    // check flag loop (pc: 228)
    OP1(0x40), INSN(OP_SET_A),
    OP1(0x3), INSN(OP_STR),


    OP1(3), INSN(OP_LDR),
    INSN(OP_LDR),
    INSN(OP_SHR),
    OP1(0x00), INSN(OP_CMP),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),

    OP1(0x3), INSN(OP_LDR),
    INSN(OP_INC),
    OP1(0x3), INSN(OP_STR),

    OP1(0x40+16), INSN(OP_CMP),
    OP1( 103), INSN(OP_SET_A),
    INSN(OP_HJNE),
    INSN(OP_GET_A),

    //OP1(0x10), INSN(OP_CMP),

    OP1(0x40), INSN(OP_CHECKFLAG),
    OP1(58), INSN(OP_SET_A),
    INSN(OP_JNE),

    // We made it!
    OP1(0xa), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(0xd), INSN(OP_SET_A),
    INSN(OP_UART_TX),

    OP1('C'), INSN(OP_SET_A),
    INSN(OP_UART_TX),
    OP1(44), INSN(OP_ADD),
    INSN(OP_UART_TX),
    OP1(3), INSN(OP_ADD),
    INSN(OP_UART_TX),
    INSN(OP_UART_TX),
    OP1(13), INSN(OP_SUB),
    INSN(OP_UART_TX),
    INSN(OP_DEC),
    INSN(OP_DEC),
    INSN(OP_UART_TX),
    OP1(0), INSN(OP_LDR),
    INSN(OP_UART_TX),

    INSN(OP_EXIT),


};


char mem[128] = {0};
uint pc = 0;

int execute_get_a(void) {
    int ret;

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &get_a_program);

    pio_sm_config conf = get_a_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    ret = pio_sm_get_blocking(pio, sm);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
    return ret;
}

void execute_set_a(char c) {

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &set_a_program);

    pio_sm_config conf = set_a_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    pio_sm_put_blocking(pio, sm, c);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}


void execute_add(char c) {

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &add_program);

    pio_sm_config conf = add_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    pio_sm_put_blocking(pio, sm, c);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}

void execute_putc() {
    const uint PIN_TX = 0;
    const uint SERIAL_BAUD = 115200;

    char c = execute_get_a();

    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &uart_tx_program);
    uart_tx_program_init(pio, sm, offset, PIN_TX, SERIAL_BAUD);
    uart_tx_program_putc(pio, sm, c);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);

}


void execute_getc() {
    const uint PIN_RX = 1;
    const uint SERIAL_BAUD = 115200;
    char off, c;
    off = execute_get_a();
    //puts("Waiting for input\n");

    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &uart_rx_program);
    uart_rx_program_init(pio, sm, offset, PIN_RX, SERIAL_BAUD);
    c = uart_rx_program_getc(pio, sm);



    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
    mem[off] = c;

}


void execute_sub(char c) {

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &sub_program);

    pio_sm_config conf = sub_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    pio_sm_put_blocking(pio, sm, c);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}

void execute_cmp(char c) {

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &cmp_program);

    pio_sm_config conf = cmp_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    pio_sm_put_blocking(pio, sm, c);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    //printf("CMP eq? %d\n", pio_interrupt_get(pio, 4));

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}

void execute_inv() {

    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &inv_program);

    pio_sm_config conf = inv_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}


void execute_inc() {
    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &inc_program);

    pio_sm_config conf = inc_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}

void execute_dec() {
    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &dec_program);

    pio_sm_config conf = dec_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}


void execute_check_flag(char off) {


    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &check_flag_program);

    pio_sm_config conf = check_flag_program_get_default_config(offset);
    pio_sm_init(pio, sm, offset, &conf);
    pio_sm_set_enabled(pio, sm, true);


    uint16_t cmd=0;
    for (int i=16; i >0; i--) {
        cmd |= mem[off+i];
        cmd <<= 1;
    }
    cmd |= mem[off];

    //printf("CMD: %x\n", cmd);
    pio_sm_put_blocking(pio, sm, cmd);


    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);


    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}

void execute_shl() {
    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &shl_program);

    pio_sm_config conf = shl_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_interrupt_clear(pio, 3);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}


void execute_shr() {
    PIO decoder_pio = pio0;
    PIO pio = pio1;
    uint sm = 0;
    uint offset = pio_add_program(pio, &shr_program);

    pio_sm_config conf = shr_program_get_default_config(offset);
    sm_config_set_in_pins(&conf, PROG_A_RX_PIN);
    sm_config_set_out_pins(&conf, PROG_A_TX_PIN, 1);
    pio_gpio_init(pio, PROG_A_RX_PIN);
    pio_gpio_init(pio, PROG_A_TX_PIN);
    sm_config_set_set_pins(&conf, PROG_A_TX_PIN, 1);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(pio, sm, PROG_A_TX_PIN, 1, true);
    pio_sm_init(pio, sm, offset, &conf);
    pio_interrupt_clear(pio, 3);
    pio_sm_set_enabled(pio, sm, true);

    while(!pio_interrupt_get(pio, 3)){};
    pio_interrupt_clear(pio, 3);

    pio_sm_set_enabled(pio, sm, false);
    pio_clear_instruction_memory(pio);
}



__attribute__ ((noinline)) void execute_str(char op) {
    char a = execute_get_a();
    mem[op] = a;
}

__attribute__ ((noinline)) void execute_ldr_abs(char op) {
    execute_set_a(mem[op]);
}

__attribute__ ((noinline)) void execute_ldr_rel(void) {
    execute_set_a(mem[execute_get_a()]);
}


__attribute__ ((noinline)) void execute_cmp_mem(char op) {
    execute_cmp(mem[op]);
}


__attribute__ ((noinline)) void execute_jne() {
    PIO pio = pio1;
    if (!pio_interrupt_get(pio, 4)) {
        pc = execute_get_a() -1;
    }
    pio_interrupt_clear(pio, 4);
}


__attribute__ ((noinline)) void execute_hjne() {
    PIO pio = pio1;
    if (!pio_interrupt_get(pio, 4)) {
        pc = execute_get_a() -1;
        pc |= 0x80;
    }
    pio_interrupt_clear(pio, 4);
}


void execute_opped_insn(char insn, char op){
    int res;

    //printf("EXEC: %x, %x\n", insn, op);

    switch (insn) {
        case OP_SET_A:
            execute_set_a(op);
            break;
        case OP_STR:
            execute_str(op);
            break;
        case OP_LDR:
            execute_ldr_abs(op);
            break;
        case OP_ADD:
            execute_add(op);
            break;
        case OP_SUB:
            execute_sub(op);
            break;
        case OP_CMP:
            execute_cmp(op);
            break;
        case OP_CMP_MEM:
            execute_cmp_mem(op);
            break;
        case OP_CHECKFLAG:
            execute_check_flag(op);
            break;
        default:
            break;


    }

}

void execute_insn(char insn){
    //printf("EXEC: %x\n", insn);
    int res;
    switch (insn) {
        case OP_UART_TX:
            execute_putc();
            break;
        case OP_UART_RX:
            execute_getc();
            break;
        case OP_GET_A:
            res = execute_get_a();
            break;
        case OP_LDR:
            execute_ldr_rel();
            break;
        case OP_INV:
            execute_inv();
            break;
        case OP_INC:
            execute_inc();
            break;
        case OP_DEC:
            execute_dec();
            break;
        case OP_HJNE:
            execute_hjne();
            break;
        case OP_JNE:
            execute_jne();
            break;
        case OP_SHL:
            execute_shl();
            break;
        case OP_SHR:
            execute_shr();
            break;
        case OP_EXIT:
            pc = -2;
            break;
        default:
            break;
    }

}




int main() {
    char insn, op;
    PIO decoder_pio= pio0;




    /* Initialize decoder */
    uint decoder_off = pio_add_program(decoder_pio, &decoder_program);
    uint decoder_sm  = pio_claim_unused_sm(decoder_pio, true);
    pio_sm_config decoder_conf = decoder_program_get_default_config(decoder_off);
    sm_config_set_out_pins(&decoder_conf, INSN_OUT_PIN, 1);
    pio_gpio_init(decoder_pio, INSN_OUT_PIN);
    pio_sm_set_consecutive_pindirs(decoder_pio, decoder_sm, INSN_OUT_PIN, 1, true);
    pio_sm_init(decoder_pio, decoder_sm, decoder_off, &decoder_conf);


    /* Initialize get_op1 */
    uint get_op1_off = pio_add_program(decoder_pio, &get_op1_program);
    uint get_op1_sm  = pio_claim_unused_sm(decoder_pio, true);
    pio_sm_config get_op1_conf = get_op1_program_get_default_config(get_op1_off);
    sm_config_set_in_pins(&get_op1_conf, INSN_IN_PIN);
    pio_gpio_init(decoder_pio, INSN_IN_PIN);
    pio_sm_set_consecutive_pindirs(decoder_pio, get_op1_sm, INSN_IN_PIN, 1, false);
    pio_sm_init(decoder_pio, get_op1_sm, get_op1_off, &get_op1_conf);


    /* Initialize sm_a */
    uint a_off = pio_add_program(decoder_pio, &a_program);
    uint a_sm  = pio_claim_unused_sm(decoder_pio, true);
    pio_sm_config a_conf = a_program_get_default_config(a_off);
    sm_config_set_in_pins(&a_conf, SM_A_RX_PIN);
    sm_config_set_out_pins(&a_conf, SM_A_TX_PIN, 1);
    pio_gpio_init(decoder_pio, SM_A_RX_PIN);
    pio_gpio_init(decoder_pio, SM_A_TX_PIN);
    pio_sm_set_consecutive_pindirs(decoder_pio, a_sm, SM_A_RX_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(decoder_pio, a_sm, SM_A_TX_PIN, 1, true);
    pio_sm_init(decoder_pio, a_sm, a_off, &a_conf);





    pio_sm_set_enabled(decoder_pio, decoder_sm, true);
    pio_sm_set_enabled(decoder_pio, get_op1_sm, true);
    pio_sm_set_enabled(decoder_pio, a_sm, true);


    int last_pc = pc;
    while(pc != -1) {
        // Using PIO to directly r/w uart breaks the cortex I/O config
        // Hence, let's just reinitialize
        //stdio_init_all();
        //printf("pc: %d\n", pc);
        ///sleep_ms(1);

        last_pc = pc;
        pio_sm_put(decoder_pio, decoder_sm, prog[pc]);

        if (!pio_sm_is_rx_fifo_empty(decoder_pio, decoder_sm)){
            insn = pio_sm_get_blocking(decoder_pio, decoder_sm);
            if (!pio_sm_is_rx_fifo_empty(decoder_pio, get_op1_sm)){
                op = pio_sm_get_blocking(decoder_pio, get_op1_sm);
                execute_opped_insn(insn, op);
            } else {
                execute_insn(insn);
            }

        //pio_sm_clear_fifos(decoder_pio, decoder_sm);
        }
        pc++;

        // Who needs proper synchronization if we can sleep? :D
        sleep_ms(2);

    }
    //stdio_init_all();
    //
    //==== Finished at: %d ====\nMemory:\n",last_pc);
    //for (int i=0; i <128 ; i++) {
        //printf("%02x ", mem[i]);
        //if (!(i % 0x10) && i) printf("\n");

    //}

    return 0;
}
