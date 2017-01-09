#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Mojo::UserAgent;
use Getopt::Std;
use File::Temp qw(tempfile);
use English qw( -no_match_vars );

my $ppa_base_url         = "http://pools.corp.deepin.com/ppa/";
my $ppa_source_list_file = "/etc/apt/sources.list.d/deepin-ppa.list";
my $ua                   = Mojo::UserAgent->new;
my $INDEX_MAX            = 9999999;

my %opts;
getopts( 'hlLa:r:Ts', \%opts );

my $open_source = 0;
if ( $opts{s} ) {
    $open_source = 1;
}

if ( $opts{l} ) {
    list();
    exit;
}
elsif ( $opts{L} ) {
    show_source_list_file();
    exit;
}
elsif ( $opts{h} ) {
    print_help();
    exit;
}
elsif ( $opts{a} ) {
    add( $opts{a} );
    exit;
}
elsif ( $opts{r} ) {
    remove( $opts{r} );
    exit;
}
elsif ( $opts{T} ) {

    #test
    my @ppa_arr = read_file($ppa_source_list_file);
    write_file(@ppa_arr);
    exit;
}
else {
    print_help();
    exit;
}

sub print_help {
    print "
Options:
    -h show help
    -l list avilable ppa
    -L show local ppa
    -a <PPA> add a ppa
    -r <PPA> remove a ppa
    -s ppa is open source
    
ppa url base: $ppa_base_url
save in file://$ppa_source_list_file
";
}

sub show_source_list_file {
    system "cat", $ppa_source_list_file;
}

sub list {
    my @links = read_links($ppa_base_url);
    for (@links) {

        # remove tailing /
        chop;
        say $_;
    }
}

sub add {
    my $ppa = shift;
    say "add $ppa";
    my $ppa_url   = "$ppa_base_url$ppa";
    my $dists_url = "$ppa_url/dists/";
    my @links     = read_links($dists_url);
    my @sourcelist;
    for my $codename (@links) {
        if ( !is_dir($codename) ) {
            next;
        }

        warn $codename . "\n";
        my @sub_links = read_links("$dists_url$codename");
        my @components;
        for my $component (@sub_links) {
            if ( !is_dir($component) ) {
                next;
            }
            warn "\t$component\n";
            chop $component;
            push @components, $component;
        }
        chop $codename;
        my $line = "$ppa_url $codename @components";

        #say "deb $line\ndeb-src $line";
        push @sourcelist, "deb $line";
        push @sourcelist, "deb-src $line" if $open_source;
    }
    my $datetime = qx(date -R);
    chomp $datetime;
    my $ppa_item = {
        name        => $ppa,
        sourcelist  => \@sourcelist,
        index       => $INDEX_MAX,
        meta_uid    => $UID,
        meta_user   => getpwuid($UID),
        meta_modify => $datetime,
    };
    my @ppa_arr = read_file($ppa_source_list_file);
    my $idx = find_ppa( \@ppa_arr, $ppa );
    if ( $idx == -1 ) {
        warn "append";
        push @ppa_arr, $ppa_item;
    }
    else {
        warn "replace";
        $ppa_arr[$idx] = $ppa_item;
    }
    print ppa2str($ppa_item);
    write_file(@ppa_arr);
}

sub find_ppa {
    my ( $ppa_arr, $ppa ) = @_;
    my $idx = 0;
    for (@$ppa_arr) {
        if ( $_->{name} eq $ppa ) {
            return $idx;
        }
        $idx++;
    }
    return -1;
}

sub remove {
    my $ppa = shift;
    say "remove $ppa";
    my @ppa_arr = read_file($ppa_source_list_file);
    my $idx = find_ppa( \@ppa_arr, $ppa );
    if ( $idx == -1 ) {
        die "not found";
    }
    else {
        # delete $ppa_arr[$idx]
        splice( @ppa_arr, $idx, 1 );
    }
    write_file(@ppa_arr);
}

sub read_links {
    my $url   = shift;
    my $tx    = $ua->get($url);
    my $dom   = $tx->res->dom;
    my @links = grep { $_ ne '../' } $dom->find('a')->map('text')->each;
    return @links;
}

sub is_dir {
    $_[0] =~ /\/$/;
}

sub read_file {
    my $file = shift;
    open my $fh, '<', $file
        or return ();
    my %ppa_map;
    my $ppa_current;
    my $index = 0;
    while ( my $line = <$fh> ) {
        chomp $line;
        if ( $line =~ /^#: ppa (.+)$/ ) {

            #say ": $1";
            $ppa_current = $1;
            $index++;
            $ppa_map{$ppa_current} = { index => $index, sourcelist => [] };
            next;
        }
        elsif ( $line =~ /^#: meta_(\S+) (.+)$/ ) {

            # keep meta info
            if ($ppa_current) {
                $ppa_map{$ppa_current}{"meta_$1"} = $2;
            }

        }
        elsif ( $line =~ /(deb|deb-src)\s/ ) {

            #say "> $line";

            if ($ppa_current) {
                push @{ $ppa_map{$ppa_current}{sourcelist} }, $line;
            }
        }
        else {
            $ppa_current = "";
        }
    }
    close $fh;
    my @ppa_arr;
    for my $ppa ( keys %ppa_map ) {
        my $val = $ppa_map{$ppa};
        $val->{name} = $ppa;
        push @ppa_arr, $val;
    }
    ### read_file: @ppa_arr
    return @ppa_arr;
}

sub write_file {
    my @ppa_arr = @_;
    ### write_file: @ppa_arr
    @ppa_arr = sort { $a->{index} <=> $b->{index} } @ppa_arr;
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    for (@ppa_arr) {
        print $fh ppa2str($_);
    }
    close $fh;
    system "sudo mv -v $filename $ppa_source_list_file";
}

sub ppa2str {
    my $ppa = shift;
    my $ret = "#: ppa $ppa->{name}\n";

    # meta info
    for my $key ( sort keys %$ppa ) {
        if ( $key =~ /^meta_/ ) {
            my $val = $ppa->{$key};
            $ret .= "#: $key $val\n";
        }
    }
    for ( @{ $ppa->{sourcelist} } ) {
        $ret .= $_ . "\n";
    }
    $ret .= "\n";
    return $ret;
}
