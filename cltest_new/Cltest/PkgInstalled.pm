package Cltest::PkgInstalled;
use warnings;
use strict;
use 5.018;

use Cltest::DebControlParser;
use Cltest::Deb;
use File::Basename qw(basename);

my $config_dir = "$ENV{HOME}/.config/cltest";


sub get_install_pkg_list {
    my @files = glob "$config_dir/*.install";
    my @pkgs;
    for (@files) {
        my $basename = basename($_);
        push @pkgs, substr $basename, 0, -8
    }
    return @pkgs;
}

sub check_status {
    my @pkgs = get_install_pkg_list();
    my %pkg_status;
    for (@pkgs) {
        my %status = get_pkg_status( $_ );
        if (keys %status) {
            $pkg_status{$_} = \%status;
        } else {
            remove_install($_);
        }
    }
    return %pkg_status;
}

# remove .install file
sub remove_install {
    my $pkg = $_[0];
    unlink "$config_dir/$pkg.install";
}

sub print_status {
    my %pkg_status = check_status();
    my @cl_nums;
    for my $pkg (keys %pkg_status) {
        my $status = $pkg_status{$pkg};
        push @cl_nums, int($status->{CR_NUM});
        print_pkg_status($pkg, $status);
    }
    @cl_nums = Cltest::Utils::uniq(@cl_nums);
    if ( @cl_nums ) {
        say "cl nums: " . join(", ", @cl_nums);
    } else {
        say "nothing"
    }
}

sub restore {
    my %pkg_status = check_status();
    for my $pkg (keys %pkg_status) {
        restore_pkg($pkg);
    }
}

sub restore_other_pkgs {
    my %pkg_status = check_status();
    my @new_installed_pkgs = Cltest::Deb::get_new_installed_pkgs();
    for my $pkg (keys %pkg_status) {
        if ( not grep { $pkg eq $_ } @new_installed_pkgs ) {
            restore_pkg($pkg);
        }
    }
}

sub restore_pkg {
    my $pkg = $_[0];
    say "Restore $pkg";
    system "sudo apt-get install --reinstall $pkg";
}

sub get_cl_nums {
    my %pkg_status = check_status();
    my @cl_nums;
    for my $pkg (keys %pkg_status) {
        my $status = $pkg_status{$pkg};
        push @cl_nums, int($status->{CR_NUM});
    }
    @cl_nums = Cltest::Utils::uniq(@cl_nums);
}

sub print_pkg_status {
    my ($pkg, $status) = @_;
    say "Package: $pkg";
    say "subject: $status->{CR_SUBJECT}";
    say "status:  $status->{CR_STATUS}";
    say "owner: $status->{CR_OWNER}";
    say "url: $status->{CR_URL}\n";
}

sub get_pkg_status {
    my $pkg = $_[0];
    my $dpkg_status = qx(dpkg --status $pkg);
    my $control = Cltest::DebControlParser->read_string($dpkg_status);
    my $content = $control->{contents}[0];
    return unless defined $content;
    return parse_description($content);
}

sub parse_description {
    my ($pairs) = @_;
    my $ref_value = $pairs->FETCH("Description");
    return () unless defined $ref_value;
    my @desc = split /\n/, $$ref_value;
    my $begin = 0;
    my %info;
    for (@desc) {
        if ($_ eq ' =begin' ) {
            $begin = 1;
            next;
        }
        if ( $_ eq ' =end' ){
            last;
        }
        # push @collect, $_ if $begin;
        if ($begin){
            if ( / ([^=]+)=(.*)$/ ) {
                $info{$1} = $2;
            }
        }
    }
    return %info;
}

1;
