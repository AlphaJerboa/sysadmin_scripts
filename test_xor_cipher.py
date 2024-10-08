#!/usr/bin/python
from __future__ import print_function, unicode_literals
from os import urandom


def genkey(length):
    """Generate key"""
    return urandom(length)
    

def xor_strings(s, t):
    """xor two strings together"""
    if isinstance(s, str):
        # Text strings contain single characters
        return "".join(chr(ord(a) ^ ord(b)) for a, b in zip(s, t))
    else:
        # Python 3 bytes objects contain integer values in the range 0-255
        return bytes([a ^ b for a, b in zip(s, t)])
        

message = 'This is a secret message'
print('message:', message)

key = genkey(len(message))
print('key:', key)

cipherText = xor_strings(message.encode('utf8'), key)
print ('cipherText:', cipherText)
print ('decrypted:', xor_strings(cipherText, key).decode('utf8'))

# verify
if xor_strings(cipherText, key).decode('utf8') == message:
    print('Unit test passed')
else:
    print('Unit test failed')

