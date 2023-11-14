#!/bin/sh
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv shell 3.10.4
cd $HOME/projects/ChuanhuChatGPT
pyenv exec python3 ./ChuanhuChatbot.py
