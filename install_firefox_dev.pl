#!/usr/bin/env perl
use 5.024;
use strict;
use warnings;
use File::Temp qw(tempdir);
use Data::Dump qw(dump);
use POSIX qw(strftime);

my $HOME = $ENV{HOME};
#my $zipfile = "$HOME/firefox-54.0a2.zh-CN.linux-x86_64.tar.bz2";
my $zipfile = $ARGV[0];

# 设置 $check 为 0，跳过检查，可加快测试。
my $check = 1;

if ($check) {
	my @files = qx(tar --list --file $zipfile);
	warn "files", dump(@files);
	for (@files) {
		if (! m/^firefox\//) {
			die "not starts with firefox/"
		}
	}
	warn "check ok";
}
my $destdir = "$HOME/applications";
my $tmpdir = tempdir("upack-XXXXXX", DIR => $destdir);
warn "tmpdir:", $tmpdir;
chdir $tmpdir or die "Can't cd to tmpdir $tmpdir: $!";
print "extracting.";
# 提示: tar 命令的 --checkpoint 参数设置为 .1000 会在每经过1000个检查点时打印出一个点'.'
system "tar --extract --totals --checkpoint=.1000 --file $zipfile";
my $suffix = strftime("%Y-%m-%dT%H:%M:%S", localtime);
my $dest="$destdir/firefox-dev-$suffix";
rename "$tmpdir/firefox", $dest;
say "done.\n$dest";

# Clean
chdir "/";
rmdir $tmpdir or die $!;


