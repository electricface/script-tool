#!/usr/bin/env perl
use 5.018;
use warnings;

use Time::HiRes qw(time tv_interval);
my $startTime = [time];
while (<>) {
    my $dt = tv_interval($startTime);
    printf "[%.2f] %s", $dt, $_;
    # print . " " . $_
}
