#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

use Getopt::Std;
use File::Path qw(make_path remove_tree);
use Data::Dump qw(pp);
use Term::ReadLine;
use File::Basename qw(basename);

my %opts;
getopts( "hli:u:e:d:U:Ss:", \%opts );

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
	-s show <name>
	-S shell script

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
        print_shell_script();
    } elsif ( defined $opts{s} ) {
		show_plugin( $opts{s} );
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

sub get_plugin_display_name {
    my $name = $_[0];
    if ( $name =~ /~$/ ) {
        $name = substr $name, 0, -1;
        $name .= "\t[disabled]";
    }
    return $name;
}

sub list_plugins {
    my @plugins = get_plugins();

    my ( @colorscheme, @lang, @other );

    for my $p ( sort @plugins ) {
        if ( $p =~ /^colorscheme-/ ) {
            push @colorscheme, $p;
        }
        elsif ( $p =~ /^lang-/ ) {
            push @lang, $p;
        }
        else {
            push @other, $p;
        }
    }

    for my $p (@other) {
        say "* ", get_plugin_display_name($p);
    }

    for my $p (@colorscheme) {
        say "% ", get_plugin_display_name($p);
    }

    for my $p (@lang) {
        say "& ", get_plugin_display_name($p);
    }

}

sub get_good_plugin_name {
    my $name = $_[0];
    $name =~ s/^vim-//;
    $name =~ s/\.git$//;
    $name =~ s/(\.|-)vim$//;
    return $name;
}

sub install_plugin {
    my $git_uri = $_[0];
    chdir $VIM_BUNDLE_DIR or die $!;
    my $prompt = "Enter plugin new name: ";
    my $bname  = basename($git_uri);
    $term->add_history($bname);
    my $good_name = get_good_plugin_name($bname);
    $term->add_history( "lang-" . $good_name );
    $term->add_history( "colorscheme-" . $good_name );
    $term->add_history($good_name);
    my $name = $term->readline($prompt);
    my @cmds = ( "git", "clone", $git_uri );

    if ( defined $name && length($name) > 1 ) {
        push @cmds, $name;
        system @cmds;
    }
    else {
        say "do nothing";
    }
}

sub find_match_plugin {
    my $n       = $_[0];
    my @plugins = get_plugins();
    my @matched = grep { $_ eq $n || $_ eq "$n~" } @plugins;
    return $matched[0];
}

sub uninstall_plugin {
    my $n    = $_[0];
    my $name = find_match_plugin($n);
    if ( !defined $name ) {
        say "not found plugin $n";
        return;
    }
    my $plugin_dir = "$VIM_BUNDLE_DIR/$name";
    my $yes        = ask_yes("delete $plugin_dir ? (y/N)");
    if ($yes) {
        remove_tree( $plugin_dir, { verbose => 1 } );
    }
    else {
        say "do nothing";
    }
}

sub ask_yes {
    my $prompt = $_[0];
    my $in     = $term->readline($prompt);
    return scalar( $in =~ /^(y|yes)$/i );
}

sub enable_plugin {
    my $n    = $_[0];
    my $name = find_match_plugin($n);
    if ( !defined $name ) {
        say "not found plugin $n";
        return;
    }
    chdir $VIM_BUNDLE_DIR or die $!;
    warn "try enable_plugin $name";
    if ( $name !~ /~$/ ) {
        say "enabled";
        return;
    }
    my $new_name = substr $name, 0, -1;
    rename $name, $new_name or die $!;
    say "enable plugin $name";
}

sub disable_plugin {
    my $n    = $_[0];
    my $name = find_match_plugin($n);
    if ( !defined $name ) {
        say "not found plugin $n";
        return;
    }
    chdir $VIM_BUNDLE_DIR or die $!;
    warn "try disable_plugin $name";
    if ( $name =~ /~$/ ) {
        say "disabled";
        return;
    }
    rename $name, "$name~" or die $!;
    say "disable plugin $name";
}

sub install_pathogen {
    make_path( $VIM_AUTOLOAD_DIR, $VIM_BUNDLE_DIR, { verbose => 1 } );

    #my $url = "https://tpo.pe/pathogen.vim";
    my $url
        = "https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim";
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
        my $plugin = find_match_plugin($name);
        if ( !defined $plugin ) {
            say "not found plugin $name";
            return;
        }
        update_plugin_one($plugin);
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

sub show_plugin {
	my ($name) = @_;
	my $plugin = find_match_plugin($name);
	say "plugin: ", get_plugin_display_name($plugin);
	my $dir = "$VIM_BUNDLE_DIR/$plugin";
	say "directory: ", $dir;

	my @readmes = glob "$dir/README.*";
	if (@readmes) {
		say "readme: ", $readmes[0]
	}

	chdir $dir or die "chdir $dir failed: $!";
	my $git_uri = qx(git config --get remote.origin.url);
	chomp $git_uri;
	say "git: $git_uri";
}

sub print_shell_script {
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
