package Cltest::PatchsetBuildResult;
use 5.018;
use warnings;
use Data::Dump qw(pp);

use Cltest::Deb;
use Cltest::Utils;

sub new {
	my ($class,$patchset_num, $url, $status, $change_info) = @_;

	return bless {
		url => $url,
		status => $status,
		patchset_num => $patchset_num,
		change_info => $change_info,
	}, $class;
}

sub is_success {
	my $self = shift;
	return $self->{status} eq "SUCCESS";
}

sub get_deb_urls {
	my $self = $_[0];
	my $url = $self->{url};
	my $ua = Cltest::Utils::get_ua();
	my $resp = $ua->get($url);
	if ( $resp->is_success ){
		$_ = $resp->decoded_content;
		return map { $url . $_ } /href="(\S+\.deb)">/sgi;
	}
	else {
		warn "get_deb_urls failed: url=$url ", $resp->status_line;
		return ();
	}
}

sub install_debs {
	my $self = shift;

	# check url build status
	if (not $self->is_success) {
		die "build status not success, status: " . $self->{status};
	}

	for my $url ( $self->get_deb_urls ) {
		my $deb = Cltest::Deb->new($url, $self);
		$deb->install;
	}
}


1;
