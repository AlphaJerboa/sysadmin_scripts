#!/bin/bash

# Check the function makepass

PASS=$(dd if=/dev/urandom count=20 bs=1 2>/dev/null | sha256sum | base64 | head -c 12)
echo $PASS
