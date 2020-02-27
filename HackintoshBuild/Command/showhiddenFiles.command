#!/bin/bash

defaults write com.apple.finder AppleShowAllFiles -bool $1
KillAll Finder

echo "success"
