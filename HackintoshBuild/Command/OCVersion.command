#!/bin/bash

nvram 4d1fda02-38c7-4a6a-9cc6-4bcca8b30102:opencore-version | awk {'print $2'} | awk -F- {'print $2'}
