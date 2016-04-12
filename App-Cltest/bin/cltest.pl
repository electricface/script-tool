#!/usr/bin/env perl
use 5.018;
use warnings;
use Data::Dumper;
use File::Spec;
use Getopt::Long;
use Cltest::ChangeInfo;
use Cltest::PkgInstalled;

my @opt_cls;
my @opt_add_cls;
GetOptions(
	'help' => \&help,
	'num=i' => \@opt_cls,
	'restore' => \&restore,
	'again' => \&again,
	'add=i' => \@opt_add_cls,
	'status' => \&print_status,
);

if (@opt_cls) {
	install_cl($_) for @opt_cls;
	Cltest::PkgInstalled::restore_other_pkgs();
	exit;
} elsif ( @opt_add_cls) {
	install_cl($_) for @opt_add_cls;
	exit;
}

# funcations
sub help
{
print "
cltest -n N1 -n N2
options:
--restore
--status
--again
--add NUM
--num NUM
--help
";
exit;
}

sub install_cl
{
	my $cl_num = $_[0];
	my $info = Cltest::ChangeInfo->new( $cl_num );
	$info->install_deb;
}

sub restore {
	Cltest::PkgInstalled::restore();
	exit;
}

sub print_status {
	Cltest::PkgInstalled::print_status();
	exit 0;
}

sub again {
	my @cl_nums = Cltest::PkgInstalled::get_cl_nums();
	say "cl_nums: ". join(", ", @cl_nums);
	install_cl($_) for @cl_nums;
	exit;
}
