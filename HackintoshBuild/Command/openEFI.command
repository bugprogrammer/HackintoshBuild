#!/bin/bash

mount=$(diskutil info $1 | grep 'Mount Point' | awk -F: {'print $2'} | sed 's/^[ \t]*//g')

open "${mount}"
