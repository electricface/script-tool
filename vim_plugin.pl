#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Getopt::Std;
use Data::Dump qw(pp);

my %opts;
getopts( "hli:u:e:d:U:S", \%opts );

#warn "opts: ", pp(\%opts);

my $VIM_DIR        = "$ENV{HOME}/.vim";
my $VIM_BUNDLE_DIR = "$VIM_DIR/bundle";

#warn "VIM_BUNDLE_DIR:", $VIM_BUNDLE_DIR;

sub print_help {
    print "Manage vim plugins the pathogen way

  Options:
	-h help
	-i install <git-uri>
	-U uninstall <name>
	-e enable <name>
	-d disable <name>
	-l list
	-u update [name/all/enabled]
	-S save

  about pathogen: https://github.com/tpope/vim-pathogen
    ";
}

MAIN: {
    # check pathogen.vim
    if ( !-e "$VIM_DIR/autoload/pathogen.vim" ) {
        say "pathogen not ok";
        install_pathogen();
    }

    #chdir $VIM_BUNDLE_DIR or die $!;
    if ( $opts{h} ) {
        print_help();
    }
    elsif ( $opts{l} ) {
        list_plugins();
    }
    elsif ( defined $opts{i} ) {
        install_plugin( $opts{i} );
    }
    elsif ( defined $opts{U} ) {
        uninstall_plugin( $opts{U} );
    }
    elsif ( defined $opts{d} ) {
        disable_plugin( $opts{d} );
        exit;
    }
    elsif ( defined $opts{e} ) {
        enable_plugin( $opts{e} );
    }
    elsif ( defined $opts{u} ) {
        update_plugin( $opts{u} );
    }
    elsif ( $opts{S} ) {
        save();
    }
    else {
        print_help();
    }
}
exit;

sub get_plugins {
    my @names;

    opendir( my $dh, $VIM_BUNDLE_DIR )
      or die "can't opendir: $!";
    while ( readdir $dh ) {
        if ( $_ =~ /^\./ ) {
            next;
        }
        if ( -d "$VIM_BUNDLE_DIR/$_" ) {
            push @names, $_;
        }
    }
    closedir $dh;

    #warn "names:", pp(@names);
    return @names;
}

sub list_plugins {
    my @plugins = get_plugins();
    for my $p ( sort @plugins ) {
        say "* $p";
    }
}

sub install_plugin {
    my $git_uri = $_[0];
    chdir $VIM_BUNDLE_DIR or die $!;
    system "git", "clone", $git_uri;
}

sub uninstall_plugin {
    my $name = $_[0];
    chdir $VIM_BUNDLE_DIR or die $!;
    system "rm", "-rvf", $name;
}

sub enable_plugin {
    my $name = $_[0];
    chdir $VIM_BUNDLE_DIR or die $!;
    warn "try enable_plugin $name";
    if ( $name !~ /~$/ ) {
        say "enabled";
        return;
    }
    if ( -d $name ) {
        my $new_name = substr $name, 0, -1;
        system "mv", $name, $new_name;
        say "enable plugin $name";
    }
    else {
        say "no this plugin $name";
    }
}

sub disable_plugin {
    my $name = $_[0];
    chdir $VIM_BUNDLE_DIR or die $!;
    warn "try disable_plugin $name";
    if ( $name =~ /~$/ ) {
        say "disabled";
        return;
    }
    if ( -d $name ) {
        system "mv", $name, "$name~";
        say "disable plugin $name";
    }
    else {
        say "no this plugin $name";
    }
}

sub install_pathogen {
    qx(mkdir -p ~/.vim/autoload ~/.vim/bundle);
    my $url = "https://tpo.pe/pathogen.vim";
    system "curl -# -L -o ~/.vim/autoload/pathogen.vim $url";
    if ( $? == 0 ) {
        say "install_pathogen done";
    }
}

sub update_plugin {
    my $name = $_[0];
    if ( $name eq 'all' ) {
        update_plugin_many( get_plugins() );
    }
    elsif ( $name eq 'enabled' ) {
        my @enabled = grep { $_ !~ /~$/ } get_plugins();
        update_plugin_many(@enabled);
    }
    else {
        update_plugin_one($name);
    }
}

sub update_plugin_one {
    my $name = $_[0];
    say "try update_plugin $name";
    chdir "$VIM_BUNDLE_DIR/$name" or die $!;

    system "git pull origin master";
}

sub update_plugin_many {
    warn "update_plugin_many", pp(@_);
    for my $p (@_) {
        update_plugin_one($p);
    }
}

sub save {
    say "#!/bin/sh";
    say 'cd $HOME/.vim/bundle';
    for my $p ( get_plugins() ) {
        my $dir = "$VIM_BUNDLE_DIR/$p";
        chdir $dir or die "chdir $dir failed: $!";
        my $git_uri = qx(git config --get remote.origin.url);
        chomp $git_uri;
        say "\n# $p";
        say "echo Install plugin $p";
        say "git clone $git_uri $p";
    }
}

