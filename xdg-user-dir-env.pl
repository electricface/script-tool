#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

no Smart::Comments;
use Path::Tiny;
use Getopt::Std;

my %opts;

# in fish rc
# eval (xdg-user-dir-env.pl -b)
# in bash rc
# eval $(xdg-user-dir-env.pl -f)

# -f fish
# -b bash
getopt('fb', \%opts);
### %opts

my $outputShell = 'bash';
if ( exists $opts{f} ) {
    $outputShell = 'fish';
} elsif ( exists $opts{b} ) {
    $outputShell = 'bash';
}

binmode \*STDOUT, 'utf8';

my $userDirsCfgFile = "$ENV{HOME}/.config/user-dirs.dirs";
### $userDirsCfgFile

my @contents = path($userDirsCfgFile)->lines_utf8({chomp => 1});
for ( @contents ) {
    next if /^#/;
    my ($key, $value) = split /=/, $_, 2;
    output($outputShell, $key, $value)
}

sub output {
#fish
# set -x key value

#bash
# export key=value
    my ($shell, $key, $value) = @_;
    if ($shell eq 'fish') {
        say "set -x $key $value;";
    } elsif ( $shell eq 'bash' ) {
        say "export $key=$value;";
    }
}
