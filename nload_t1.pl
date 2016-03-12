#!/usr/bin/env perl

use 5.018;
use warnings;

use Smart::Comments;
use File::Which;
use Data::Dumper;

my $nmcliBin = which('nmcli');
chomp $nmcliBin;
### $nmcliBin

my $activeNetConnections = qx($nmcliBin --terse --fields type,device connection show --active);
### $activeNetConnections

my @result = parseStr( $activeNetConnections );
### @result

if ( @result == 1 ) {
    system "nload $result[0] -u K";
} else {
    warn "Found more than one network-connected devices: " . join(',', @result);
}

sub parseStr {
    my $str = $_[0];
    my @result;
    for ( split /\n/, $str ) {
        ### $_
        my ($type, $device) = split /:/, $_, 2;
        ### $type
        ### $device
        if ( $type ne 'bridge' ) {
            push @result, $device
        }
    }
    return @result
}
