#!/bin/bash

if [ "$(diskutil list | grep 'APFS Snapshot')" != "" ]; then
    echo enabled
else
    echo disabled
fi
