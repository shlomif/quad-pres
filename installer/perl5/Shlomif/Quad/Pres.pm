package Shlomif::Quad::Pres;

use strict;
use warnings;

use utf8;

use Shlomif::Gamla::Object;
use Data::Dumper;

use Shlomif::Quad::Pres::Url;

use CGI ();

use vars qw(@ISA);

@ISA=qw(Shlomif::Gamla::Object);

my $navigation_style_class = "nav";
my $contents_style_class = "contents";

sub initialize
{
    my $self = shift;

    $self->{'contents'} = shift;
    
    my %args = (@_);
    
    my $doc_id = $args{'doc_id'};
    
    $self->{'mode'} = ($args{'mode'} || "server");

    $self->{'stage_idx'} = ($args{'stage_idx'} || 0);
    
    $self->get_doc_id($doc_id);
    
    $self->{'doc_id_slash_terminated'} = (($doc_id =~ /\/$/) ? 1 : 0);

    return 0;
}

sub get_doc_id
{
    my $self = shift;

    my $doc_id = shift;

    my $doc_id_parsed = [ split(/\//, $doc_id) ];

    $self->get_coords($doc_id_parsed);

    my ($b, $i, @coords);
    
    @coords = @{$self->{'coords'}};
    $b = $self->{'contents'};

    for($i=0;$i<scalar(@coords);$i++)
    {
        $b = $b->{'subs'}->[$coords[$i]];
    }
    
    $self->{'doc_id'} = Shlomif::Quad::Pres::Url->new(
        $doc_id_parsed,
        exists($b->{'subs'}),
        $self->{'mode'}
        );
}

sub get_coords
{
    my $self = shift;

    my $doc_id_parsed  = shift;
    if (!exists($self->{'coords'}))
    {
        my %locs;
        my $traverse;

        $traverse = 
        sub {
            my $coords = shift;
            my $branch = shift;
            my $path = shift;

            push @$path, $branch->{'url'};

            $locs{join("/", @$path[1..$#$path])} = [ @{$coords} ];
            if (exists ($branch->{'subs'}))
            {
                my $i;

                for($i=0;$i<scalar(@{$branch->{'subs'}});$i++)
                {
                    $traverse->(
                        [ @$coords, $i ],
                        $branch->{'subs'}->[$i],
                        [ @$path ],
                    );
                }
            }
        };

        $traverse->(
            [ ],
            $self->{'contents'},
            [ ],
        );

        if (0)
        {
            print "Content-Type: text/plain\n\n";
            my $d = Data::Dumper->new([\%locs], ["locs"]);
            print $d->Dump();
        }

        my $document_id = join("/", @{$doc_id_parsed});
        if (!exists($locs{$document_id}))
        {
            die "Pres::get_coords(): Could not find the document \"" . $document_id . "\".";
        }
        $self->{'coords'} = [ @{$locs{$document_id}} ];
    }
}

sub get_document_base_text
{
    my $self = shift;

    my $document_id = join("/", @{$self->{'doc_id'}->get_url()});

    my $filename = "./src/" . $document_id;

    if (-f $filename)
    {
        my $text;
        local(*I);
        open I, ("<".$filename);
        $text = join("",<I>);
        close(I);
        return $text;
    }
    elsif ((-d $filename) && (-f $filename."/index.html"))
    {
        my $text;
        local(*I);
        open I, ("<".$filename."/index.html");
        $text = join("",<I>);
        close(I);
        return $text;
    }
    else 
    {
        die "Could not find the file \"" . $document_id . "\"";
    }
}

sub get_url_by_coords
{
    my $self = shift;

    my @coords = @{shift(@_)};

    my @url;
    my $b;
    my $i;

    $b = $self->{'contents'};

    for($i=0;$i<scalar(@coords);$i++)
    {
        $b = $b->{'subs'}->[$coords[$i]];
        push @url, $b->{'url'};
    }

    return Shlomif::Quad::Pres::Url->new(\@url, exists($b->{'subs'}), $self->{'mode'});
}


sub get_contents_url
{
    my $self = shift;

    return Shlomif::Quad::Pres::Url->new([], 1, $self->{'mode'});
}

sub get_last_url
{
    my $self = shift;

    my $b = $self->{'contents'};

    my @path;

    while (exists($b->{'subs'}))
    {
        my $b_subs = $b->{'subs'};
        my $last_branch = $b_subs->[scalar(@$b_subs)-1];
        push @path, $last_branch->{'url'};
        $b = $last_branch;
    }

    return Shlomif::Quad::Pres::Url->new([@path], 0, $self->{'mode'});
}

sub get_next_url
{
    my $self = shift;

    my @coords = @{$self->{'coords'}};

    my @branches = ($self->{'contents'});

    my @dest_coords;

    my $i;

    for($i=0;$i<scalar(@coords);$i++)
    {
        $branches[$i+1] = $branches[$i]->{'subs'}->[$coords[$i]];
    }

    if (exists($branches[$i]->{'subs'}))
    {
        @dest_coords = (@coords,0);
    }
    else
    {
        for($i--;$i>=0;$i--)
        {
            if (scalar(@{$branches[$i]->{'subs'}}) > ($coords[$i]+1))
            {
                @dest_coords = (@coords[0 .. ($i-1)], $coords[$i]+1);
                last;
            }
        }
        if ($i == -1)
        {
            return undef;
        }
    }

    return $self->get_url_by_coords(\@dest_coords);
}

sub get_most_advanced_leaf
{
    my $self = shift;

    # We accept as a parameter the vector of coordinates
    my $coords_ref = shift;

    my @coords = @{$coords_ref};

    # Get a reference to the contents HDS (= hierarchial data structure)
    my $branch = $self->{'contents'};

    # Get to the current branch by advancing to the offset 
    foreach my $c (@coords)
    {
        # Advance to the next level which is at index $c
        $branch = $branch->{'subs'}->[$c];
    }

    # As long as there is something deeper
    while (exists($branch->{'subs'}))
    {
        # Get the index of the most advanced sub-branch
        my $index = scalar(@{$branch->{'subs'}})-1;
        # We are going to return it, so store it
        push @coords, $index;
        # Recurse into the sub-branch
        $branch = $branch->{'subs'}->[$index];
    }
    
    return \@coords;
}

sub get_prev_url
{
    my $self = shift;

    my @coords = @{$self->{'coords'}};

    if (scalar(@coords) == 0)
    {
        return undef;
    }    
    elsif ($coords[$#coords] > 0)
    {
        # Get the previous leaf
	    my @previous_leaf = 
	        ( 
                @coords[0 .. ($#coords - 1) ] ,
                $coords[$#coords]-1
            );
        # Continue in this leaf to the end.
        my $new_coords = $self->get_most_advanced_leaf(\@previous_leaf);

        return $self->get_url_by_coords($new_coords);
    }
    elsif (scalar(@coords) > 0)
    {
        return $self->get_url_by_coords(
            [ @coords[0 .. ($#coords-1)] ]
            );
    }
    else
    {
        return undef;
    }
}

sub get_up_url
{
    my $self = shift;

    my @coords = @{$self->{'coords'}};

    if (scalar(@coords) == 0)
    {
        return undef;
    }
    else
    {
        return $self->get_url_by_coords(
            [ @coords[0..($#coords-1)] ]
            );
    }    
}

sub get_relative_url__depcracated
{
    my @this_url = @{shift(@_)};
    my @other_url = @{shift(@_)};
    my $slash_terminated = shift;

    my $ret;
    
    while(
        scalar(@this_url) &&
        scalar(@other_url) &&
        ($this_url[0] eq $other_url[0])
    )
    {
        shift(@this_url);
        shift(@other_url);
    }

    $ret = "";

    if ($slash_terminated)
    {
        $ret .= join("/", (map { ".." } @this_url), @other_url); 
    }
    else
    {
        $ret .= ("./" . join("/", (map { ".." } @this_url[1..$#this_url]), @other_url)); 
    }

    return $ret;
}

sub get_control_url
{
    my $self = shift;

    my $other_url = shift;

    if (!defined($other_url))
    {
        return undef;
    }
    
    my $this_url = $self->{'doc_id'};

    return
        $this_url->get_relative_url(
                $other_url,
                $self->{'doc_id_slash_terminated'}
            );
}

sub get_control_text
{
    my $self = shift;

    my $spec = shift;

    my $text = "";

    my $this_url = $self->{'doc_id'};

    my $other_url = $spec->{'url'}->($self);

    if (defined($other_url))
    {
    
        $text .= "<a href=\"" . 
                $self->get_control_url($other_url) .
            "\" class=\"" . $navigation_style_class . "\">";
    
        $text .= $spec->{'caption'};

        $text .= "</a>";
    }
    else
    {
        $text .= "<b class=\"" . $navigation_style_class .  "\">" . $spec->{'caption'} . "</b>";
    }

    return $text;
}

sub get_navigation_bar
{
    my $self = shift;

    if (!exists($self->{'navigation_bar'}))
    {
        # Render the Navigation Bar
        my $text = "";
        my @controls;

        $text .= "<table>\n";
        $text .= "<tr>\n";
        $text .= "<td>\n";

        push @controls, ($self->get_control_text(
            {
                'url' => \&get_contents_url,
                'caption' => "Contents",
            },
        ));

        push @controls, ($self->get_control_text(
            {
                'url' => \&get_up_url,
                'caption' => "Up",
            },
        ));

        push @controls, ($self->get_control_text(
            {
                'url' => \&get_prev_url,
                'caption' => "Previous",
            },
        ));

        push @controls, ($self->get_control_text(
            {
                'url' => \&get_next_url,
                'caption' => "Next",
            },
        ));
        

        $text .= join("</td>\n<td>\n", @controls);

        $text .= "</td>\n";
        $text .= "</tr>\n";
        $text .= "</table>\n";
        $text .= "\n";
        #$text .= "<br><br>";

        $self->{'navigation_bar'} = $text;
    }

    return $self->{'navigation_bar'};
}

sub get_subject_by_coords
{
    my $self = shift;
    my $coords_ref = shift;

    my $branch = $self->{'contents'};

    my @coords = @$coords_ref;

    for(my $i=0;$i<scalar(@coords);$i++)
    {
        $branch = $branch->{'subs'}->[$coords[$i]];
    }

    return $branch->{'title'};
}

sub get_subject
{
    my $self = shift;

    return $self->get_subject_by_coords($self->{coords});
}

sub get_title
{
    my $self = shift;

    my @coords = @{$self->{'coords'}};

    my @coords_plus_1 = (map { $_+1 ; } @coords);
    my $indexes_str = join(".", @coords_plus_1);
    if (scalar(@coords))
    {
        $indexes_str .= ". ";
    }

    return $indexes_str . $self->get_subject();    
}

sub get_header
{
    my $self = shift;

    my $text = "";
    my $branch;

    my @coords = @{$self->{'coords'}};

    $text .= "<html>\n";
    $text .= "<head>\n";
    $text .= "<title>" . $self->get_subject() . "</title>\n";
    $text .= "<link rel=\"StyleSheet\" href=\"" .
        $self->{'doc_id'}->get_relative_url(
            Shlomif::Quad::Pres::Url->new(
                [ "style.css" ],
                0,
                $self->{'mode'}
                ),
            $self->{'doc_id_slash_terminated'}    
            ) .
        "\" type=\"text/css\">\n";
        
    $text .= "</head>\n";
    $text .= "<body>\n";
    $text .= $self->get_navigation_bar();

    $text .= "<h1 class=\"fcs\">" . $self->get_title() . "</h1>";

    return $text;
}

sub get_footer
{
    my $self = shift;

    my $text = "";

    $text .= "\n\n<hr>\n";

    $text .= $self->get_navigation_bar() ;

    $text .= "</body>\n";
    $text .= "</html>\n";

    return $text;
}

sub get_contents_helper
{
    my $self = shift;

    my $branch = shift;
    my $url = shift;
    my $coords_ref = shift;
    my @coords = @{$coords_ref};


    my $text = "";
    $text .= "<li>";
    $text .= "<a href=\"" .
        $self->{'doc_id'}->get_relative_url(
            Shlomif::Quad::Pres::Url->new(
                [@$url], 
                exists($branch->{'subs'}),
                $self->{'mode'}
            )
        ) .
        "\" class=\"" . $contents_style_class . "\">";
    my @coords_plus_1 = (map { $_+1; } @coords);
    $text .= join(".", @coords_plus_1);
    $text .= ". ";
    $text .= $branch->{'title'};
    $text .= "</a>\n";
    if (exists($branch->{'subs'}))
    {
        $text .= "<ul class=\"$contents_style_class\">\n";
        my $index = 0;
        foreach my $sb (@{$branch->{'subs'}})
        {
            $text .= $self->get_contents_helper(
                $sb, 
                [@$url, $sb->{'url'}],
                [ @coords, $index ],
                );
            $index++;
        }
        $text .= "</ul>\n";
    }
    $text .= "</li>";
    return $text;
}

sub get_contents
{
    my $self = shift;

    my $text = "";

    my @coords = @{$self->{'coords'}};
    my @url;

    my $b = $self->{'contents'};

    my $i;

    for($i=0;$i<scalar(@coords);$i++)
    {
        $b = $b->{'subs'}->[$coords[$i]];
        push @url, $b->{'url'};
    }
    
    if (exists($b->{'subs'}))
    {
        for($i=0;$i<scalar(@{$b->{'subs'}});$i++)
        {
            $text .= $self->get_contents_helper(
                $b->{'subs'}->[$i], 
                [@url, $b->{'subs'}->[$i]->{'url'}],
                [ @coords, $i],
                );
        }
    }

    return "<ul class=\"$contents_style_class" . "main\">\n" . $text . "</ul>\n";   # The wrapping <ul>'s are
        # meant to make sure there are no spaces between the various 
        # lines.
        # It just works.
}

sub get_menupath_text
{
    # We are not using $self, but it may prove useful in the future, so a 
    # stitch in time saves nine. So for the while get_menupath_text is treated
    # as a method function.
    my $self = shift; 

    my $inside = shift;

    # Remove new-lines
    $inside =~ s/\n//g;
    
    # Remove the existing <tt>'s and such.
    $inside =~ s/< *\/? *tt *>//;

    # convert these ampersand escapes to normal text.
    if (0)
    {
        $inside =~ s/&(amp|lt|gt);/
            (($1 eq "amp") ? 
                "&" : 
                ($1 eq "lt") ? 
                    "<" : 
                    ">"
            )
                    /ge;
    }
    
    # Split to the menu path components
    my @components = split(/\s*-&gt;\s*/, $inside);

    # Wrap the components of the path with the HTML Cascading Style
    # Sheets Magic
    my @components_rendered = map { 
        "\n<b class=\"menupathcomponent\">\n" .
        $_ . "\n" .
        "</b>\n"
        } @components;

    # An arrow wrapped in CSS magic.
    my $separator_string = "\n <font class=\"menupathseparator\">\n" .
        "-&gt;" .
        "</font> \n";

    my $final_string = join($separator_string, @components_rendered);

    $final_string = 
        ("&nbsp;" x 2) .        
        "<font class=\"menupath\">" . 
        $final_string . 
        "</font>";

    return $final_string;
}

sub process_document_text
{
    my $self = shift;

    my $text = shift;

    my $header = $self->get_header();
    my $footer = $self->get_footer();
    my $contents = $self->get_contents();

    $text =~ s/<!-+ *\& *begin_header *-+>[\x00-\xFF]*?<!-+ *\& *end_header *-+>/$header/;
    $text =~ s/<!-+ *\& *begin_footer *-+>[\x00-\xFF]*?<!-+ *\& *end_footer *-+>/$footer/;
    $text =~ s/<!-+ *\& *begin_contents *-+>[\x00-\xFF]*?<!-+ *\& *end_contents *-+>/$contents/;
    $text =~ s/<!-+ *\& *begin_menupath *-+>([\x00-\xFF]*?)<!-+ *\& *end_menupath *-+>/$self->get_menupath_text($1)/ge;

    return $text;
}

sub render_text
{
    my $self = shift;

    my $base_text = $self->get_document_base_text();
    my $text = $self->process_document_text($base_text);

    return $text;
}

sub render
{
    my $self = shift;
    eval {
        $self->get_coords();
        my $text = $self->render_text();
        if ($self->{'mode'} eq 'cgi')
        {
            print "Content-Type: text/html\n\n";
        }
        print $text;
    };

    if ($@)
    {
        if ($self->{'mode'} eq 'cgi')
        {
            print "Content-Type: text/plain\n\n";
        }
        print "Error!\n\n";
        print $@;
    }
}

sub traverse_tree
{
    my $self = shift;
    my $callback = shift;

    my $contents = $self->{'contents'};

    my $traverse_helper;
    $traverse_helper = 
        sub {
            my $path_ref = shift;
            my $coords = shift;
            my $branch = shift;

            $callback->(
                'path' => $path_ref, 
                'branch' => $branch,
                'coords' => $coords,
                );

            if (exists($branch->{'subs'}))
            {
                # Let's traverse all the directories
                my $new_coord = 0;
                foreach my $sub_branch (@{$branch->{'subs'}})
                {
                    $traverse_helper->(
                        [ @$path_ref, $sub_branch->{'url'} ],
                        [ @$coords, $new_coord],
                        $sub_branch,            
                        );
                }
                continue
                {
                    $new_coord++;
                }
            }
        };

    $traverse_helper->([], [], $contents);
}

sub get_breadcrumbs_trail
{
    my $qp = shift;
    my $sep = shift;

    if (!defined ($sep))
    {
        $sep = " → ";
    }

    my @abs_coords = @{$qp->{'coords'}};

    my @strs;
    for my $end ((-1) .. $#abs_coords)
    {
        my @coords = @abs_coords[0 .. $end];
        my $s = "<a href=\""
            . CGI::escapeHTML($qp->get_control_url($qp->get_url_by_coords(\@coords)))
            . "\">"
            . $qp->get_subject_by_coords(\@coords) .
            "</a>"
            ;
        push @strs, $s;
    }

    return join($sep, @strs);
}

1;

