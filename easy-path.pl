#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

# Simple quote function to replace Data::Dump::quote
sub quote {
    my $str = shift;
    # Escape special characters and wrap in single quotes
    $str =~ s/'/'"'"'/g;  # Replace single quotes with '"'"'
    return "'$str'";
}

# config file ~/.config/easy-path.cfg.pl

my $cfg_file = "$ENV{HOME}/.config/easy-path.cfg.pl";
my $kv       = do $cfg_file;
if ($@) {
    die "couldn't parse $cfg_file: $@";
}
if ( !defined $kv ) {
    die "kv is not defined";
}

for my $key ( keys %$kv ) {
    printf "set -gx %s %s;\n", quote($key), quote( $kv->{$key} );
}
