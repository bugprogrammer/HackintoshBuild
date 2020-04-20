#!/bin/bash

if [[ $1 == "acidanthera_WhateverGreen" ]]; then
    kextstat | grep -i 'as.vit9696.whatevergreen' | awk {'print $7'} | sed 's/(//g' | sed 's/)//g'
elif [[ $1 == "bugprogrammer_WhateverGreen" ]]; then
    kextstat | grep -i 'as.bugprogrammer.WhateverGreen' | awk {'print $7'} | sed 's/(//g' | sed 's/)//g'
else
    kextstat | grep $1 | awk {'print $7'} | sed 's/(//g' | sed 's/)//g'
fi
