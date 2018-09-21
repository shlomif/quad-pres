package Contents;

use strict;
use warnings;

use File::Basename qw/ dirname /;
use YAML::XS qw/ LoadFile /;

my $contents = LoadFile( dirname(__FILE__) . '/Contents.yml' );

sub get_contents
{
    return $contents;
}

1;
