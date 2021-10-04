#include <cstdio>
#include <cstdlib>
#include <unistd.h>

extern "C" void __real___stack_chk_fail();
extern "C" void __wrap___stack_chk_fail()
{
    throw 1337;
   __real___stack_chk_fail();
}

using namespace std;

int thrower() {
    char buf[4];
    read(0, buf, 100);
    return 0;
}

void win() {
    char* foo = "lose";
    try {
        thrower();
    } catch (int e) {
        printf("%s\n", foo);
    }
}

int main() {
    char *bar = "win";
    try {
        thrower();
    }
    catch (int e) {
        printf("Stack Smashing Detected!\n");
        exit(1);
    }
}