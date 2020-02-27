#!/bin/bash

nvram -p | awk '{print $1}' | sort -f
