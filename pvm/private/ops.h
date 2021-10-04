

#define OP_UART_TX 0x71
#define OP_UART_RX 0x07
#define OP_EXIT    0x0a

#define OP_SET_A 0x18
#define OP_GET_A 0x19

#define OP_STR 0x3c
#define OP_LDR 0x25




#define OP_ADD 0x5a
#define OP_SUB 0x7e
#define OP_SHL 0x57
#define OP_SHR 0x6f

#define OP_INV 0x1a
#define OP_DEC 0x48
#define OP_INC 0x2a

#define OP_CMP     0x28 // Raises irq 4 when A == OP
#define OP_JNE     0x4d // Jmps when irq 4 is not set
#define OP_CMP_MEM 0x0f // Raises irq 4 when A == mem[OP]
#define OP_HJNE    0x1e // Jmps when irq 4 is not set


#define OP_CHECKFLAG 0xc // Raises irq4 on correct flag
