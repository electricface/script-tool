package Cltest::DebControlParser;
use 5.018;

use Tie::IxHash;

# new method
# read_file and read_string

sub read_file {
    my ($class,$file) = @_;
    open my $fh, '<', $file or die $!;
    my @contents = parse_fh($fh);
    close $fh;
    return bless {
        contents => \@contents,
    }, $class;
}

sub read_string {
    my ($class, $string) = @_;
    open my $fh, '<', \$string or die $!;
    my @contents = parse_fh($fh);
    close $fh;
    return bless {
        contents => \@contents,
    }, $class;
}

sub write_file {
    my ($self, $file) = @_;
    open my $fh, '>', $file
        or die $!;
    print $fh $self->to_string;
    close $fh;
}

sub to_string {
    my ($self) = @_;
    return contents_to_string(@{ $self->{contents} });
}

sub parse_fh {
    my $fh = $_[0];

    my $ref_last_value;
    my $last_pairs = Tie::IxHash->new;
    my @contents;

    while (my $line = <$fh>) {
        ### $line

        # if the line is empty it's the end of control paragraph
        if ($line =~ /^\s*$/) {
            $ref_last_value = undef;
            if (defined $last_pairs) {
                push @contents, $last_pairs;
                $last_pairs = Tie::IxHash->new;
            }
            next;
        }

        # line starting with white space
        if ($line =~ /^\s/) {
            die if not defined $ref_last_value;
            ### append last_value
            $$ref_last_value .= $line;
            next;
        }

        # line starting with `#` are comments
        if ($line =~ /^#/) {
            next;
        }

        # key : value lines
        if ($line =~ /^([^:]+):(.*$)/ms ) {
            my ($key, $value) = ($1,$2);
            $last_pairs->STORE($key, \$value);
            $ref_last_value = \$value;
            next;
        }
        die "unexpect";
    }
    push @contents, $last_pairs
        if defined $last_pairs;
    return @contents;
}

sub contents_to_string {
    my @contents = @_;
    my @str_list;
    for ( @contents ) {
        push @str_list, content_to_string($_);
    }
    my $str = join "\n", @str_list;
    return $str;
}

sub content_to_string {
    my $pairs = $_[0];
    my $str = '';
    for my $key ( $pairs->Keys ) {
        my $value = $pairs->FETCH($key);
        $str .= "$key:$$value";
    }
    return $str;
}

1;
