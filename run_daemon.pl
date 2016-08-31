#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use File::Basename;

$SIG{TERM} = sub {
    say "ignore SIGTERM";
};

my ($daemon,$debugMatch) = @ARGV;
$debugMatch //= ".*";

my $daemonBasename = basename($daemon);
system "pkill -e -c -f $daemonBasename";
say "\$ env DDE_DEBUG_MATCH='$debugMatch' $daemon";
exec "env DDE_DEBUG_MATCH='$debugMatch' $daemon";
