#!/bin/bash

"$1" | grep GFX0 | awk '{print $NF}'
