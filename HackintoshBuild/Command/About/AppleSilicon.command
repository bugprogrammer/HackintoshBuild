#!/bin/bash

system_profiler -json SPApplicationsDataType | grep -E '\"_name\"|\"arch_kind\"|\"obtained_from\"|\"version\"' | sed 's/^[ \t]*//g' | sed 's/,//g' | sed 's/\"//g'
