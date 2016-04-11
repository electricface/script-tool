#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Smart::Comments;
use Tie::IxHash;


my $file = $ARGV[0];
### $file

use Cltest::DebControlParser;

my $c = Cltest::DebControlParser->read_file($file);
### $c

$c->write_file("out");
