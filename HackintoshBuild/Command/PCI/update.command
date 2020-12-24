#!/bin/bash

url=$1
cd ${url%/*}
curl -O https://downloads.bugprogrammer.me/tools/dspci
chmod +x ./dspci
