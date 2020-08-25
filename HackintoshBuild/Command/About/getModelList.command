#!/bin/bash

$1 --list | grep Model: | awk '{print $NF}'
