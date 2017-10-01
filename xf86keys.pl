#!/usr/bin/env perl
use warnings;
use strict;
use 5.018;

my $xmlHeader =
'<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
    <schema id="com.deepin.dde.keybinding.mediakey" path="/com/deepin/dde/keybinding/mediakey/" >
';

my $xmlFooter =
'    </schema>
</schemalist>
';

sub decamelize {
        my $s = shift;
        $s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
                my $fc = pos($s)==0;
                my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
                my $t = $p0 || $fc ? $p0 : '-';
                $t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
                $t;
        }ge;
        $s;
}

sub trimSpace {
	my $s = shift;
	$s =~ s/\A\s+//;
	$s =~ s/\s+\z//;
	return $s;
}

sub printKeyDefine {
	my ($fh, $name, $comment) = @_;
	my $id = decamelize($name);
	my $key = 'XF86'.$name;
	printKey($fh, $id, $key, $comment);
}

sub printKey {
	my ($fh, $id, $key, $comment) = @_;
	my $format =
'        <key type="as" name="%s">
            <default>[\'%s\']</default>
            <summary>%s</summary>
            <description></description>
        </key>
';
	printf $fh $format, $id, $key, trimSpace($comment);
}

sub printIgnoreKeyDefine {
	my ($fh, $name) = @_;
	print $fh "        <!-- ignore XF86$name-->\n";
}

my $XF86keysymHFile = $ARGV[0];
my $outputXMLFile = $ARGV[1];

warn "input $XF86keysymHFile,output $outputXMLFile";
#my $file = "/usr/include/X11/XF86keysym.h";
open OUT, '>', $outputXMLFile
	or die $!;

print OUT $xmlHeader;

open FH, '<', $XF86keysymHFile
	or die $!;

my @ignoreKeys = qw(
ClearGrab Ungrab LogWindowTree LogGrabInfo
iTouch Q RotationPB RotationKB BackForward Travel UserPB User1KB User2KB Market
);
while (my $line = <FH>) {
	chomp $line;
	if ($line =~ /^#define/ ) {
		print ">>> ", $line , "\n";
		if ($line =~ /^#define\s+XF86XK_(\w+)\s+0x[0-9A-F]+(\s*\/\*(.*)\*\/)?/ ) {
			my $name = $1;
			my $comment = $3;
			if ( !defined $comment ) {
				$comment = ""
			}

			# ignore some keys
			if ($name =~ /^Switch_VT_/ ||
				$name =~ /_VMode$/ ||
				$name =~ /^Launch[0-9A-F]$/ ||
				grep { $_ eq $name } @ignoreKeys
			) {
				printIgnoreKeyDefine(\*OUT, $name);
				next;
			}

			say "name: $name, comment: {$comment}";
			printKeyDefine(\*OUT, $name, $comment);
		} else {
			die "line don't match regex: $line";
		}
	}
}
close FH;

# Exceptions
printKey(\*OUT,'switch-monitors', 'mod4-p', '');
printKey(\*OUT,'capslock', 'Caps_Lock', '');
printKey(\*OUT,'numlock', 'Num_Lock', '');
print OUT $xmlFooter;
close OUT;
