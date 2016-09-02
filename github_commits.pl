#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Term::ANSIColor qw(colored);
use JSON qw(from_json);
use File::Temp qw(tempfile);
use Mojo::UserAgent;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::TimeZone;

my $github_api_urlbase = "https://api.github.com";
my $localTZ = DateTime::TimeZone->new( name => 'local' );
my $jsonDateTimeF = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M:%SZ', locale => 'en_US', time_zone => 'UTC');
my $outputDateTimeF = DateTime::Format::Strptime->new(pattern => '%a %b %e %T %Y %z', locale => 'en_US');

sub get_commits {
    my ($user, $repo, $branch) = @_;
    my $url = "$github_api_urlbase/repos/$user/$repo/commits";

    my $ua = Mojo::UserAgent->new;
    my $commits = $ua->get($url => { Accept => 'text/json' } => form => {sha => $branch} )->res->json;
    return $commits;
}

#commit d7c46f01b4dfffffc2c00eecae38bc3eb82b20aa
#Author: jouyouyun <jouyouwen717@gmail.com>
#Date:   Thu Sep 1 16:51:26 2016 +0800

    #audio: Emit default sink/source  changed after rebuild

    #Change-Id: I969633689f888c7bc79c91a24055da4a045a8c38

sub print_commit {
    my ($fh, $data) = @_;
    my $sha = $data->{sha};
    ### $sha
    my $commit = $data->{commit};
    my $author = $commit->{author};
    ### $author
    my $message = $commit->{message};
    ### $message

    say $fh colored("commit $sha", 'yellow');
    say $fh "Author: $author->{name} $author->{email}";

    #say $fh "Date: $t";
    say $fh "Date: " . get_time_str($author->{date});

    my $message_indented = $message =~ s/^/    /mgr;
    say $fh "\n$message_indented\n";
}

sub get_time_str {
    my $dt = $jsonDateTimeF->parse_datetime($_[0]);
    $dt->set_formatter($outputDateTimeF);
    $dt->set_time_zone($localTZ);
    return $dt.'';
}


MAIN: {
    my ($user, $repo, $branch) = @ARGV;

    my ($fh, $tmp_file) = tempfile("github_commits-XXXXXXX", UNLINK => 1);
    binmode($fh, ':utf8');
    my $commits = get_commits($user, $repo, $branch);
    for (@$commits) {
        print_commit($fh, $_);
    }
    system "less", "-R", $tmp_file;
}
