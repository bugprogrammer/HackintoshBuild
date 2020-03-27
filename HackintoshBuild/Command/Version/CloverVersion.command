#!/bin/bash

$1 | grep revision: | awk -F'revision:' {'print $2'} | awk {'print $1'}

