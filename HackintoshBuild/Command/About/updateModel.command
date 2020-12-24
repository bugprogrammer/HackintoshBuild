#!/bin/bash

url=$1
cd ${url%/*}
curl -O https://downloads.bugprogrammer.me/tools/macserial
chmod +x ./macserial
