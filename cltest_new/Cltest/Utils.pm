package Cltest::Utils;
use warnings;
use strict;
use 5.018;

use LWP::UserAgent;


our $ua = LWP::UserAgent->new(
	ssl_opts => { verify_hostname => 0 },
	show_progress => 1,
);

sub get_ua {
    return $ua;
}

sub uniq (@)
{
    my %seen = ();
    my $k;
    my $seen_undef;
    grep { defined $_ ? not $seen{ $k = $_ }++ : not $seen_undef++ } @_;
}

1;
