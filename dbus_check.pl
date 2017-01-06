#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

my $sessionBusAddress = $ENV{DBUS_SESSION_BUS_ADDRESS};
### $sessionBusAddress

my ($socket, $guid) = split /,/ , $sessionBusAddress,2;
### $socket
### $guid
if (!verifySocket($socket)) {
	die "socket verify failed"
}

if (!verifyGuid($guid)) {
	die "guid verify failed"
}

sub verifySocket {
	my ($socket) = @_;
	if ($socket =~ /^unix:path=(.*)$/) {
		my $file = $1;
		### $file
		if (-S $file) {
			# file is a socket
			return 1
		}
		return 0
	}
	return 0
}

sub verifyGuid {
	my ($guid) = @_;
	if (!defined $guid || $guid =~ /^guid=[0-9a-f]{32}$/ ) {
		return 1
	}
	return 0
}
