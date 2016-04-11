package Cltest::ChangeInfo;
use 5.018;
use warnings;

use JSON::PP;
use Cltest::PatchsetBuildResult;
use Cltest::Utils;

# return hash
sub get_change_detail
{
	my $ua = Cltest::Utils::get_ua();
	my $cl_num = shift;
	my $url = "https://cr.deepin.io/changes/$cl_num/detail";
	my $resp = $ua->get($url);
	if ($resp->is_success ){
		$_ = $resp->decoded_content;
		return decode_json( substr( $_, index ($_, "\n") + 1) );
	}
	else {
		die "get_change_detail : url = $url ",$resp->status_line;
	}
}

sub new {
	my ($class, $cl_num) = @_;
	my $detail = get_change_detail($cl_num);
	my $self = bless {
		status => $detail->{status},
		subject => $detail->{subject},
		owner => $detail->{owner}{name},
		num => $detail->{_number},
	}, $class;

	my $messages = $detail->{messages};
	### $messages
	my @jenkins_messages;
	for (@$messages) {
		my $author_name = $_->{author}{name};
		if (defined $author_name && $author_name eq 'jenkins' ) {
			push @jenkins_messages, $_->{message};
		}
	}
	### @jenkins_messages
	my @build_results;
	for my $msg ( @jenkins_messages ) {
		if ( $msg =~ /Patch Set (\d+): Verified/ ) {
			### jenkins Verified: $msg
			my $patchset_num = $1;
			if ( my %url_status = $msg =~ m{(https?://\S+).+(SUCCESS|FAILURE)}g ) {
				### %url_status
				for my $url (keys %url_status) {
					next if $url =~ /-mxe-ci/;
					next if $url =~ /-win32-ci/;
					my $status = $url_status{ $url };
					push @build_results, Cltest::PatchsetBuildResult->new($patchset_num, $url, $status, $self);
				}
			}
		}
	}

	$self->{patchset_build_results} = \@build_results;
	return $self;
}

sub print_head
{
	my $self = shift;
    printf "\e[38;5;10m%s %s\nOwner: %s\nStatus: %s\e[0m\n",
		$self->{num} , $self->{subject}, $self->{owner}, $self->{status};
}


# TODO: 考虑接受个 patchset num 参数
sub install_deb {
	my $self = shift;
	$self->print_head;

	my $build_results = $self->{patchset_build_results};
	warn "Not found any patchset build result" unless @$build_results;

	# get newest
	my $newest_build = $build_results->[-1];
	$newest_build->install_debs;
}

1;
