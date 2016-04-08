#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

sub get_dbus_session_daemon_pid {
    my @process_cmdlines = qx(pgrep -a dbus-daemon);
    ### @process_cmdlines
    my @session_cmdlines = grep { $_ =~ /--session/ } @process_cmdlines;
    ### @session_cmdlines
    my $session_cmdline = $session_cmdlines[0];
    if (defined $session_cmdline) {
        if ( $session_cmdline =~ /^(\d+)/ ) {
            return int $1;
        }
    } else {
        die "Not found pid of `dbus-daemon --session`";
    }
}

sub dbus_tmp_file {
    my $pid = $_[0];
    my @lines = qx(lsof -p $pid -F n);
    ### @lines
    for (@lines) {
        if ( m{@(/tmp/dbus-\S*+)} ) {
            return $1;
        }
    }
}

MAIN: {
    my $pid = get_dbus_session_daemon_pid();
    ### $pid
    my $file = dbus_tmp_file( $pid );
    ### $file
    my $address = $ENV{DBUS_SESSION_BUS_ADDRESS};
    ### $address
    if ($address =~ /^unix:abstract=$file,guid=/) {
        say "ok";
        exit 0;
    }
    say "not ok";
    exit 1;
}
