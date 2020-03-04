#!/bin/bash

volume=$1

if [ $volume != "" ]; then
    open /Volumes/$volume
else
    open /Volumes
fi
