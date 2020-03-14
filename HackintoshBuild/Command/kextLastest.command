#!/bin/bash

curl $1/releases/latest | sed 's#.*tag/\(.*\)".*#\1#' | sed 's/v//g' | sed 's/N-d-k-//g'
