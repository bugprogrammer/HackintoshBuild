#!/bin/bash

$1 | awk '{$1="";print $0}' | sed 's/ = / /g' | sed 's/:/ /g'
