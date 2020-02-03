#!/bin/bash

csrutil status | grep status | awk '{print $NF}'
