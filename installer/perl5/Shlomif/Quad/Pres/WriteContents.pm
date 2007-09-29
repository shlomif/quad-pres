package Shlomif::Quad::Pres::WriteContents;

use strict;
use warnings;

use Moose;

has '_contents' => (isa => "HashRef", is => "ro", init_arg => "contents");

my @output_contents_keys_order = (qw(url title subs images));

my %output_contents_keys_values = (map { $output_contents_keys_order[$_] => $_ } (0 .. $#output_contents_keys_order));

sub output_contents_get_value
{
    my ($key) = (@_);
    
    return exists($output_contents_keys_values{$key}) ? 
        $output_contents_keys_values{$key} :
        scalar(@output_contents_keys_order);
}

sub output_contents_sort_keys
{
    my ($hash) = @_;
    return 
        [ 
            sort 
            {
                output_contents_get_value($a) <=> output_contents_get_value($b)
            }
            keys(%$hash)
        ];
}
my %special_chars = 
(
    "\n" => "\\n",
    "\t" => "\\t",
    "\r" => "\\r",
    "\f" => "\\f",
    "\b" => "\\b",
    "\a" => "\\a",
    "\e" => "\\e",
);

sub string_to_perl
{
    my $s = shift;
    $s =~ s/([\\\"])/\\$1/g;
    
    $s =~ s/([\n\t\r\f\b\a\e])/$special_chars{$1}/ge;
    $s =~ s/([\x00-\x1F\x80-\xFF])/sprintf("\\x%.2xd", ord($1))/ge;

    return $s;
}

sub update_contents
{
    my ($self) = @_;

    open my $contents_fh, ">", "Contents.pm";
    # open Contents, ">&STDOUT";
    print {$contents_fh} "package Contents;\n\nuse strict;\n\nmy \$contents = \n";

    # my $d = Data::Dumper->new([$contents], ["\$contents"]);

    # $d->Indent(1);
    # $d->Sortkeys(\&output_contents_sort_keys);
    # print Contents $d->Dump();

    print {$contents_fh} $self->dump_contents();

    print {$contents_fh} <<"EOF";

sub get_contents
{
    return \$contents;
}

1;
EOF

    close($contents_fh);
}

sub dump_contents
{
    my $self = shift;

    my $contents = $self->_contents();

    my $indent = "    ";

    my @branches = ({ 'b' => $contents, 'i' => -1 });

    my $ret = "";
    
    MAIN_LOOP: while (@branches > 0)
    {
        my $last_element = $branches[$#branches];
        my $b = $last_element->{'b'};
        my $i = $last_element->{'i'};
        my $p1 = $indent x (2*(scalar(@branches)-1));
        my $p2 = $p1 . $indent;
        my $p3 = $p2 . $indent;
        if ($i < 0)
        {
            $ret .= "${p1}\{\n";
            foreach my $field (qw(url title))
            {
                if (exists($b->{$field}))
                {
                    $ret .= "${p2}'$field' => \"" . string_to_perl($b->{$field}) . "\",\n";
                }
            }
            
            
            if (exists($b->{'subs'}))
            {
                $ret .= "${p2}'subs' =>\n";
                $ret .= "${p2}\[\n";                
                # push @branches { 'b' => $b->{'subs'} }
            }
            $last_element->{'i'} = 0;
            next MAIN_LOOP;
        }
        elsif ((!exists($b->{'subs'})) || ($i >= scalar(@{$b->{'subs'}})))
        {
            $ret .= "${p2}],\n" if (exists($b->{'subs'}));
            if (exists ($b->{'images'}))
            {
                $ret .= "${p2}'images' =>\n";
                $ret .= "${p2}\[\n";
                foreach my $img (@{$b->{'images'}})
                {
                    $ret .= "${p3}\"" . string_to_perl($img) . "\",\n";
                }
                $ret .= "${p2}],\n";
            }            
            pop(@branches);
            $ret .= "${p1}}" . ((@branches > 0) ? "," : ";") ."\n";
            next MAIN_LOOP;
        }
        else
        {
            push @branches, { 'b' => $b->{'subs'}->[$i], 'i' => -1 };
            $last_element->{'i'}++;
            next MAIN_LOOP;
        }
    }

    return $ret;
}

1;

