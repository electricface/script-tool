#!/bin/sh
content=`xclip -sel clipboard -o`
echo $content
xdg-open "$content"
