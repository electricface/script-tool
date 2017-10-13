#!/usr/bin/python3
import sys
import os
import os.path
import subprocess
from shutil import copyfile
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('svg_file', help='input svg file')

default_output_pattern = 'icons/hicolor/<size2>/apps'
default_sizes = '16,22,24,32,48,64,96,128,scalable'

parser.add_argument('-s', '--sizes',
        dest='sizes',
        default=default_sizes,
        help='the list of sizes to export, comma split, default: %s' % default_sizes
        )

parser.add_argument('-o', '--output-pattern',
        dest='output_pattern',
        metavar='PATTERN',
        default= default_output_pattern,
        help=('the output file path pattern, must contain <size1> or <size2> mark, ' +
        '<size1> will be replaced with a single number, ' +
        'and <size2> will be replaced with number x number. ' +
        'default: %s') % default_output_pattern
        )

args = parser.parse_args()
svg_file = args.svg_file
output_pattern = args.output_pattern
sizes=args.sizes.split(',')

name = os.path.splitext(os.path.basename(svg_file))[0]

def svg2png(svg_file, output, size):
    subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size), '-o', output, svg_file ])

def get_filename(pattern, size, name):
    if size == 'scalable':
        size1 = size
        size2 = size
    else:
        # size is num
        size1 = size
        size2 = size + 'x' + size

    if '<size1>' in pattern:
        pattern = pattern.replace('<size1>', size1, 1)
    elif '<size2>' in pattern:
        pattern = pattern.replace('<size2>', size2, 1)
    else:
        raise Exception('no found <sizeX> in pattern %s' % pattern)
    return os.path.join(pattern, name)

if __name__ == '__main__':
    print("src ", svg_file, os.path.getsize(svg_file))
    for size in sizes:
        ext = '.png'
        if size == 'scalable':
            ext = '.svg'

        output = get_filename(output_pattern, size , name + ext)
        os.makedirs( os.path.dirname(output), mode=0o755, exist_ok=True)

        if ext == '.png':
            svg2png(svg_file, output, int(size))
        else:
            copyfile(svg_file, output)
        print(output, os.path.getsize(output))

