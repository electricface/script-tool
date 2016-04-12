package Cltest::Deb;
use warnings;
use strict;
use 5.018;

use URI::Escape qw(uri_unescape);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::Temp qw(tempdir);

use Cltest::DebControlParser;
use Cltest::Utils;

my @new_installed_pkgs;

sub get_new_installed_pkgs {
    return Cltest::Utils::uniq(@new_installed_pkgs)
}

sub new {
    my ($class, $url, $build_result) = @_;
    # $url is deb url
	my $pkg = basename(uri_unescape($url));
    my ($pkg_name,$ver) = split /_/, $pkg, 2;

    return bless {
        url => $url,
        pkg => $pkg,
        pkg_name => $pkg_name,
        build_result => $build_result,
        download_file_path => undef,
        modified_file_path => undef,
    }, $class;
}

sub save_deb {
	my ($self) = @_;
	my $tmp_deb_dir = get_tmp_deb_download_dir();

	my $file_path = "$tmp_deb_dir/$self->{pkg}";
    my $ua = Cltest::Utils::get_ua();
	my $response = $ua->mirror($self->{url}, $file_path);
	if ($response->is_success ||
		$response->code eq '304') {
		warn "download ok";
        $self->{download_file_path} = $file_path;
        return 1
	} else {
		warn "download failed" . $response->status_line;
        return 0
	}
}

sub install {
    ### install
    my ($self) = @_;
    say "Package: $self->{pkg_name}";
	print "need install? (y/n)";
	my $ask = <STDIN>;
	return if $ask !~ /y/i;

    # set download_file_path
    my $save_ok = $self->save_deb;
    return if not $save_ok;

    # set modified_file_path
    $self->modify_deb;

	system "sudo dpkg -i $self->{modified_file_path}";

    if ($?) {
        warn "dpkg error : exit code ($?)";
        return;
    }

    $self->save_install;
}

sub save_install {
    my ($self) = @_;
    my $pkg_name = $self->{pkg_name};
    push @new_installed_pkgs, $pkg_name;
    my $flag_file = get_config_dir() . "$pkg_name.install";
    qx(touch $flag_file);
}

sub get_config_dir {
    return get_dir("$ENV{HOME}/.config/cltest/");
}

sub get_dir {
	my $tmp_dir = $_[0];
	make_path($tmp_dir, {
		error => \my $err,
	});
	if (@$err) {
		die "get_dir error:", pp($err);
	}
	return $tmp_dir;
}

sub get_tmp_deb_modified_dir {
	return get_dir("/tmp/cltest/deb_modified");
}

sub get_tmp_deb_download_dir {
	return get_dir("/tmp/cltest/deb_download");
}

# modify deb control info
sub modify_deb {
	my ($self) = @_;

	my $tmp_deb_dir = get_tmp_deb_modified_dir();
	copy($self->{download_file_path}, $tmp_deb_dir)
		or die "Copy failed: $!";

	my $file_path = "$tmp_deb_dir/$self->{pkg}";
	### modify_deb: $file_path
	$self->{modified_file_path} = $file_path;
	my $tmp_debian_dir = tempdir( CLEANUP => 1 );

	chdir $tmp_debian_dir;
	# get control.tar.gz
	qx(ar x $file_path control.tar.gz);
	# get control.tar
	qx(gunzip control.tar.gz);

	#TODO error line 147 tar: ./control：时间戳 2014-12-29 11:16:42 是未来的 40.804810683 秒之后
	# get control
	say "tar extract";
	qx(tar --extract --file=control.tar ./control);

	$self->modify_control;

	# rebuild deb
	say "tar update";
	qx(tar --update -f control.tar ./control);
	qx(gzip control.tar);
	qx(ar r $file_path control.tar.gz);

    # TODO: ch old dir
}

sub modify_control {
	my ($self) = @_;
	### modify_control: $self
	my $control = Cltest::DebControlParser->read_file("./control");
	my $content = $control->{contents}[0];
	if ( defined $content ) {
		my $old_depends = modify_depends($content);
        modify_version($content, $self->{pkg_name});

		# append meta info
        my $build_result = $self->{build_result};
		my $patchset_num = $build_result->{patchset_num};
        my $ci_url = $build_result->{url};

        ### $build_result
        my $change_info = $build_result->{change_info};
		my $cl_num = $change_info->{num};
        my $cl_status = $change_info->{status};
        my $cl_owner = $change_info->{owner};
        my $cl_subject = $change_info->{subject};
        $cl_subject =~ s/\n/\\n/g;

        my $more_lines = [
            "The following information is added by cltest",
			"=begin",
			"DEPENDS=$old_depends",
			"CR_URL=https://cr.deepin.io/#/c/$cl_num/$patchset_num",
            "CR_OWNER=$cl_owner",
            "CR_SUBJECT=$cl_subject",
            "CR_STATUS=$cl_status",
            "CR_NUM=$cl_num",
            "CR_PATCHSET_NUM=$patchset_num",
			"CI_URL=$ci_url",
			"DEB_URL=$self->{url}",
			"DEB_MODIFY_TIME=" . scalar localtime,
			"=end",
		];
		append_lines($content, "Description", $more_lines);
		### $content
	}
	$control->write_file("./control");
}

sub modify_depends {
	my ($pairs) = @_;
	my $ref_value = $pairs->FETCH("Depends");
	### depends field: $$ref_value
	my $old_depends = "$$ref_value";
	$$ref_value =~ s/\( [^\(\)]+ \)//xg;
	### after replace: $$ref_value
	chomp $old_depends;
	return $old_depends;
}

sub modify_version {
    my ($pairs, $pkg_name) = @_;
    my $new_ver = get_new_version( $pkg_name );
    if (defined $new_ver) {
        my $ref_value = $pairs->FETCH("Version");
        $$ref_value = "$new_ver\n";
    }
}

sub append_lines {
	my ($pairs, $key, $lines) = @_;
	my $ref_value = $pairs->FETCH($key);

	my @lines;
	if (ref $lines eq 'ARRAY') {
		for (@$lines) {
			push @lines, " $_\n";
		}
	} else {
		warn "no line to append";
		return;
	}

	$$ref_value .= join('', @lines);
}

sub get_new_version {
    my $pkgname = $_[0];
    my @pkg_policy = qx(env LANGUAGE=en_US apt-cache policy $pkgname);
    return undef unless @pkg_policy;

    my $installed_ver;
    my $candidate_ver;
    if ( $pkg_policy[1] =~ /Installed: (.*)\n/ ) {
        $installed_ver = $1;
    }
    if ( $pkg_policy[2] =~ /Candidate: (.*)\n/ ) {
        $candidate_ver = $1;
    }

    ### get_new_version
    ### @pkg_policy
    ### $installed_ver
    ### $candidate_ver
    if (defined $candidate_ver && $installed_ver eq '(none)' ){
        return $candidate_ver;
    }
    return $installed_ver;
}

1;
