#!/bin/bash

nvram -p | awk '{print $1}'
