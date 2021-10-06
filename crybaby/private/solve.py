#!/usr/bin/env python3
#
# This is a pretty straight forward challenge:
# given an AES-CTR oracle where you may choose the nonce freely,
# find a way to forge an AES-GCM message with valid tag
#
# Hopefully, this should help some CTFers learn how GCM tags work :)
#

from pwn import args, remote, process
from sage.all import GF, var

if args.REMOTE:
    io = remote(host='localhost', port=1337)
else:
    io = process(['python3', 'crybaby.py'])

io.recvuntil("cry baby cry\n")

def _xor(s1, s2):
    return bytes(a^b for a, b in zip(s1, s2))

def cmd(nonce, msg):
    io.sendline(f'{nonce.hex()} {msg.hex()}'.encode())
    return bytes.fromhex(io.recvline().decode().strip())

def ctr_oracle(n):
    nonce = n.to_bytes(16, 'big')
    resp = cmd(nonce, b'blabla')
    return _xor(resp, b'Unknown command!')

#
# 1. use the CTR oracle to learn enc(0), enc(1), enc(2) etc
# in CTR mode, the keystream is simply enc(nonce) || enc(nonce+1) || enc(nonce+2) etc
#
keystream = b''.join(ctr_oracle(i) for i in range(8))

#
# 2. we now know the keystream for nonce=0 and can log in
#
adminplz = _xor(b'adminplz', keystream)
resp = cmd(b'\x00'*16, adminplz)
assert _xor(resp, keystream) == b'Login successful!'

#
# 3. admin messages use GCM
# we know enc(0), enc(1), enc(2) etc
# and can use that to construct a valid GCM ciphertext (and tag) for nonce=0
#
# specifically, with nonce=0:
# a) h = enc(0) is used as authentication key (via GHASH)
# b) s = enc(1) is added (xor) to the GHASH result, which produces the "tag" for the message
# c) the keystream will be enc(2) || enc(3) || enc(4) etc
#
# we will not describe GHASH further here, please refer to Wikipedia or similar
#

x = var('x')
modulus = x**128 + x**7 + x**2 + x + 1
G, x = GF(2**128, name='x', modulus=modulus).objgen()

def poly_from_bytes(b):
    n = int.from_bytes(b, 'big')
    n = int(f'{n:0128b}'[::-1], 2)  # reverse bit order
    return G.fetch_int(n)

def bytes_from_poly(e):
    n = e.integer_representation()
    n = int(f'{n:0128b}'[::-1], 2)  # reverse bit order
    return int(n).to_bytes(16, 'big')

def ghash(h, ctext, aad=b''):
    from struct import pack

    def split_blocks(msg, blocksize=16):
        for i in range(0, len(msg), blocksize):
            yield msg[i:i+blocksize]

    def align(c, blocksize=16):
        return c + b'\x00'*((-len(c)) % blocksize)

    msg = align(aad) + align(ctext) + pack('>QQ', len(aad)*8, len(ctext)*8)

    g = 0
    for b in split_blocks(msg):
        g += poly_from_bytes(b)
        g *= h
    return g


# this is the info we need to forge a GCM message for nonce=0
enc0 = keystream[:16]
enc1 = keystream[16:32]
gcm_keystream = keystream[32:]
h = poly_from_bytes(enc0)
s = poly_from_bytes(enc1)

#
# 4. forge ciphertext and tag
#
flagplz = _xor(b'flagplz', gcm_keystream)
tag = bytes_from_poly(ghash(h, flagplz) + s)

#
# 5. submit admin command
# then decrypt flag
#
nonce = b'\x00'*12
resp = cmd(nonce, flagplz + tag)
print(_xor(resp[:-16], gcm_keystream).decode())
