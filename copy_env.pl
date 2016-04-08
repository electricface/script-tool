#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Data::Dump qw(pp);
use File::Slurper 'read_text';
use Smart::Comments;

sub get_env {
    my $pid = shift;
    my $file = "/proc/$pid/environ";
    my @envs = split /\0/, scalar read_text($file);
    my %env = map { split /=/, $_, 2 } @envs;
    return %env
}

sub print_env {
    my $comment = shift;
    say $comment;
    system("env")
}

# pid of dde-preload
my $pid = shift;
say "copy env from process $pid";

# print_env("before");
# set env
%ENV = get_env($pid);

$ENV{TERM} = "xterm-256color";
# print_env("after");

system @ARGV
