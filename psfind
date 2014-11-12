#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;
use Curses::UI;
use Getopt::Std;
my %opts;
getopts "h" , \%opts;
if ( $opts{h} or ! defined $ARGV[0] ) {
	help_message();
}

my @pids = qx(pgrep -f $ARGV[0]);
@pids = map { chomp;$_} @pids;


my $pids_str = join ",", @pids;
my %pid_dict;
my %listbox_labels;
my @listbox_values;
for ( qx(ps h -p '$pids_str' -o uid,pid,cmd) ){
	chomp;
	my ($uid,$pid,$cmd)	= split ' ',$_,3;
	next if $cmd =~ /perl.*psfind/;

	push @listbox_values, $pid;
	$pid_dict{$pid} = [$uid,$cmd];
	$listbox_labels{$pid} = "$uid $pid $cmd";
}

if (0 == @listbox_values){
	print "No result\n";
	exit;
}
my $cui = Curses::UI->new( -color_support => 1 );
my $win = $cui->add('window_id','Window');

$win->add(
	'mylabel','Label',
	-text => 'psfind (q Quit , d Done)',
	-bold => 1,
	-y => 0,
);

my %listbox_selected;
%listbox_selected = ( 0 => 1 ) if 1 == @listbox_values;

my $listbox = $win->add(
	'mylistbox', 'Listbox',
	-y => 1,
	-values => \@listbox_values,
	-labels => \%listbox_labels, 
	-multi => 1,
	-selected => \%listbox_selected, 
);

$cui->set_binding( sub { $cui->mainloopExit }  , "q" ); 
$cui->set_binding( \&kill_selected , "d" ); 

$listbox->focus();


$cui->mainloop;


sub help_message {
	say "
  k\tUp
  j\tDown
  Space\tMark
  d\tKill
  q\tQuit

Options:
 -h\tShow help";
 exit;
}

sub kill_selected {
	for ( $listbox->get ){
		my ($uid,$cmd) = @{ $pid_dict{$_} };
		if ($uid != $<){
			system "gksu kill $_";
		} else {
			system "kill $_";
		}
	}
	exit;
}

