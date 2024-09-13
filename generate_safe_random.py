#!/usr/bin/python3

import string
import secrets
alphabet = string.ascii_letters + string.digits
print("".join(secrets.choice(alphabet) for i in range(32)))
