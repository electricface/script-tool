#!/bin/bash
PYENV="$HOME/.pyenv/bin/pyenv"
export PYENV_VERSION=pyenv1
exec $PYENV exec xkeysnail  --watch -q \
    --devices 'Lenovo ThinkPad Compact USB Keyboard with TrackPoint'
