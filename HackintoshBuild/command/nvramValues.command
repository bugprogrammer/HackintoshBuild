#!/bin/bash

#nvram -x $1 | sed '1,5d' | sed '$d' | sed '$d'
nvram $1 | awk '{$1="";print $0}' | sed 's/^[ \t]*//g'

