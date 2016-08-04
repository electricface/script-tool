#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Getopt::Std;
use File::Path qw(make_path remove_tree);
use Data::Dump qw(pp);
use Term::ReadLine;

my %opts;
getopts( "hli:u:e:d:U:S", \%opts );

#warn "opts: ", pp(\%opts);

my $VIM_DIR          = "$ENV{HOME}/.vim";
my $VIM_BUNDLE_DIR   = "$VIM_DIR/bundle";
my $VIM_AUTOLOAD_DIR = "$VIM_DIR/autoload";
my $PATHOGEN_VIM     = "$VIM_AUTOLOAD_DIR/pathogen.vim";
my $term             = Term::ReadLine->new('vim_plugin.pl');

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

sub has_pathogen {
    -f $PATHOGEN_VIM;
}

MAIN: {
    # check pathogen.vim
    if ( !has_pathogen() ) {
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
    my $prompt = "Enter plugin new name: ";
    my $name   = $term->readline($prompt);
    warn "name: $name";
    system "git", "clone", $git_uri, $name;
}

sub uninstall_plugin {
    my $name = $_[0];
    remove_tree( "$VIM_BUNDLE_DIR/$name", { verbose => 1 } );
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
        rename $name, $new_name or die $!;
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
        rename $name, "$name~" or die $!;
        say "disable plugin $name";
    }
    else {
        say "no this plugin $name";
    }
}

sub install_pathogen {
    make_path( $VIM_AUTOLOAD_DIR, $VIM_BUNDLE_DIR, { verbose => 1 } );

    #my $url = "https://tpo.pe/pathogen.vim";
    my $url =
"https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim";
    system "curl -# -L -o $PATHOGEN_VIM $url";
    if ( $? == 0 && has_pathogen() ) {
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

