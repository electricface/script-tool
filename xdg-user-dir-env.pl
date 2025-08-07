#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;
use Getopt::Std;

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

open my $fh, '<:encoding(UTF-8)', $userDirsCfgFile or die "cannot open file '$userDirsCfgFile': $!";
my @contents = map { chomp; $_ } <$fh>;
close $fh;
for ( @contents ) {
    next if /^#/;
    my ($key, $value) = split /=/, $_, 2;
    output($outputShell, $key, $value)
}

