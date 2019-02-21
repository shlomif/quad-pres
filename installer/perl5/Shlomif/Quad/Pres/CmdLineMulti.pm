package Shlomif::Quad::Pres::CmdLineMulti;

use strict;
use warnings;

use Shlomif::Quad::Pres::CmdLine ();

use MooX qw/ late /;

has 'cmd_line' => ( isa => 'ArrayRef', is => 'ro', required => 1 );

sub run
{
    my $self = shift;

    my @argv = @{ $self->cmd_line };
    if ( @argv and $argv[0] eq 'multi_run' )
    {
        shift @argv;
        push @argv, ';';
        my @cmd;
        foreach my $arg (@argv)
        {
            if ( $arg eq ';' )
            {
                if (@cmd)
                {
                    if (
                        my $ret = Shlomif::Quad::Pres::CmdLine->new(
                            'cmd_line' => [@cmd],
                        )->run()
                        )
                    {
                        return $ret;
                    }
                }
                @cmd = ();
            }
            else
            {
                push @cmd, $arg;
            }
        }
        return 0;
    }
    else
    {
        return Shlomif::Quad::Pres::CmdLine->new( 'cmd_line' => [@argv], )->run;
    }
}

1;
