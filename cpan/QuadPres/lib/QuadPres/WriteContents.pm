package QuadPres::WriteContents;

use 5.016;
use strict;
use warnings;
use autodie;

use MooX qw/ late /;

has '_contents' =>
    ( isa => "HashRef", is => "ro", init_arg => "contents", required => 1, );

=head1 NAME

QuadPres::WriteContents - write the contents.

=head1 SYNOPSIS

    my $obj = QuadPres::WriteContents->new({contents => $contents, });
    $obj->update_contents();

=head1 DESCTIPTION

QuadPres::WriteContents.

=cut

my @output_contents_keys_order = (qw(url title subs images));

my %output_contents_keys_values =
    ( map { $output_contents_keys_order[$_] => $_ }
        ( 0 .. $#output_contents_keys_order ) );

sub _get_key_order
{
    my ($key) = (@_);

    return
        exists( $output_contents_keys_values{$key} )
        ? $output_contents_keys_values{$key}
        : scalar(@output_contents_keys_order);
}

sub _sort_keys
{
    my ($hash) = @_;
    return [
        sort { _get_key_order($a) <=> _get_key_order($b) }
            keys(%$hash)
    ];
}
my %special_chars = (
    "\n" => "\\n",
    "\t" => "\\t",
    "\r" => "\\r",
    "\f" => "\\f",
    "\b" => "\\b",
    "\a" => "\\a",
    "\e" => "\\e",
);

sub _string_to_perl
{
    my $s = shift;
    $s =~ s/([\\\"])/\\$1/g;

    $s =~ s/([\n\t\r\f\b\a\e])/$special_chars{$1}/ge;
    $s =~ s/([\x00-\x1F\x80-\xFF])/sprintf("\\x%.2xd", ord($1))/ge;

    return $s;
}

=head1 METHODS

=head2 $writer->update_contents()

Overwrite Contents.pm with the updated contents perl code.

=cut

sub update_contents
{
    my ($self) = @_;

    open my $contents_fh, ">", "Contents.pm";
    print {$contents_fh}
        "package Contents;\n\nuse strict;\n\nmy \$contents = \n";

    print {$contents_fh} $self->_stringify_contents();

    print {$contents_fh} <<"EOF";

sub get_contents
{
    return \$contents;
}

1;
EOF

    close($contents_fh);
}

sub _stringify_contents
{
    my $self = shift;

    my $contents = $self->_contents();

    my $indent = "    ";

    my @branches = ( { 'b' => $contents, 'i' => -1 } );

    my $ret = "";

MAIN_LOOP: while ( @branches > 0 )
    {
        my $last_element = $branches[$#branches];
        my $b            = $last_element->{'b'};
        my $i            = $last_element->{'i'};
        my $p1           = $indent x ( 2 * ( scalar(@branches) - 1 ) );
        my $p2           = $p1 . $indent;
        my $p3           = $p2 . $indent;
        if ( $i < 0 )
        {
            $ret .= "${p1}\{\n";
            foreach my $field (qw(url title))
            {
                if ( exists( $b->{$field} ) )
                {
                    $ret .= "${p2}'$field' => \""
                        . _string_to_perl( $b->{$field} ) . "\",\n";
                }
            }

            if ( exists( $b->{'subs'} ) )
            {
                $ret .= "${p2}'subs' =>\n";
                $ret .= "${p2}\[\n";

                # push @branches { 'b' => $b->{'subs'} }
            }
            $last_element->{'i'} = 0;
            next MAIN_LOOP;
        }
        elsif (( !exists( $b->{'subs'} ) )
            || ( $i >= scalar( @{ $b->{'subs'} } ) ) )
        {
            $ret .= "${p2}],\n" if ( exists( $b->{'subs'} ) );
            if ( exists( $b->{'images'} ) )
            {
                $ret .= "${p2}'images' =>\n";
                $ret .= "${p2}\[\n";
                foreach my $img ( @{ $b->{'images'} } )
                {
                    $ret .= "${p3}\"" . _string_to_perl($img) . "\",\n";
                }
                $ret .= "${p2}],\n";
            }
            pop(@branches);
            $ret .= "${p1}}" . ( ( @branches > 0 ) ? "," : ";" ) . "\n";
            next MAIN_LOOP;
        }
        else
        {
            push @branches, { 'b' => $b->{'subs'}->[$i], 'i' => -1 };
            ++( $last_element->{'i'} );
            next MAIN_LOOP;
        }
    }

    return $ret;
}

1;
