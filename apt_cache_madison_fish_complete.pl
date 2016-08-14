#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use String::Util qw(trim);
use URI;

my $pkg = shift;
$pkg =~ s/=.*//;
my @pkg_madison = qx(apt-cache madison $pkg);
chomp @pkg_madison;
@pkg_madison = grep { /Packages$/ } @pkg_madison;
### @pkg_madison

for my $line (@pkg_madison) {
    ### $line
    my ( undef, $version, $detail ) = split /\|/, $line, 3;
    $version = trim($version);
    $detail  = trim($detail);
    ### $version
    ### $detail

    my ( $url, $dist ) = split /\s/, $detail;
    ### $url
    ### $dist
    my $uri = URI->new($url);
    ### $uri
    my $short_url = short_host( $uri->host ) . $uri->path;
    ### $short_url
    printf "%s=%s\t%s\n", $pkg, $version, $short_url . "::$dist";
}

sub short_host {
    my $host = $_[0];
    my @parts = split /\./, $host;
    ### @parts
    my $ret;
    for (@parts) {
        $ret .= uc( substr $_, 0, 1 );
    }
    return $ret;
}

