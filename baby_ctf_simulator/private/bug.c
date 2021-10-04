#include <stdint.h>
#include <unistd.h>
#include <alloca.h>

void enter_flag(char *ptr);

char check_flag(const char* expected, size_t len) { // error here
    register char *attempt = (char*) alloca(len);
    enter_flag(attempt);
    register char valid = 1;
    for (register unsigned i = 0; i < len; i++) {
        valid &= (attempt[i] == expected[i]);
    }

    return valid;
};