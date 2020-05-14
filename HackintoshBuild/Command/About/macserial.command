#!/bin/bash

uuid=$(uuidgen)
echo -n "$2 | " && echo -n $($1 --model $2 | head -1) && echo -n " | "$uuid
