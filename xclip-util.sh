#!/bin/sh
case $1 in
	p2c)
		#primary to clipboard
		xclip -o -selection primary|xclip -i -selection clipboard
		;;
	c2p)
		#clipboard to primary
		xclip -o -selection clipboard|xclip -i -selection primary
		;;
esac
