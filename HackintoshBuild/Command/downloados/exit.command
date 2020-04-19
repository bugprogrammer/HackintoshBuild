#!/bin/bash

killall curl

if [ -d "$1/macOSInstaller" ]; then
    rm -rf "$1/macOSInstaller"
fi
