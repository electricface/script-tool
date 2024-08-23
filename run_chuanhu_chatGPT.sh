#!/bin/sh
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv shell 3.10.4
cd $HOME/projects/ChuanhuChatGPT
source /home/del0/.cache/pypoetry/virtualenvs/chuanhuchatgpt-Sa7WCY-Q-py3.10/bin/activate
python3 ./ChuanhuChatbot.py
