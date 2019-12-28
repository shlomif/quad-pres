#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;
use autodie;

sub do_system
{
    my ($args) = @_;

    my $cmd = $args->{cmd};
    print "Running [@$cmd]\n";
    if ( system(@$cmd) )
    {
        die "Running [@$cmd] failed!";
    }
}

my $ACTION = shift @ARGV;

my $IS_WIN = ( $^O eq "MSWin32" );
my $SEP    = $IS_WIN ? "\\" : '/';
my $MAKE   = $IS_WIN ? 'gmake' : 'make';
local $ENV{WMLOPTS} //= "-q";

my $cmake_gen;
if ($IS_WIN)
{
    $cmake_gen = 'MSYS Makefiles';
}

my @dzil_dirs = ( 'cpan/QuadPres', 'Task-QuadPres' );

my $CPAN = sprintf( '%scpanm', ( 1 ? '' : 'sudo ' ) );
if ( $ACTION eq 'install_deps' )
{
    foreach my $d (@dzil_dirs)
    {
        do_system(
            {
                cmd => ["cd $d && (dzil authordeps --missing | $CPAN)"]
            }
        );
        do_system(
            {
                cmd => ["cd $d && (dzil listdeps --author --missing | $CPAN)"]
            }
        );
    }
}
elsif ( $ACTION eq 'test' )
{
    foreach my $d (@dzil_dirs)
    {
        do_system( { cmd => ["cd $d && (dzil smoke --release --author)"] } );
    }
    do_system(
        {
            cmd => [
                      "cd installer/ && mkdir B && cd B && cmake .. "
                    . ( defined($cmake_gen) ? qq#-G "$cmake_gen"# : "" )
                    . " .. && $MAKE && $MAKE check"
            ]
        }
    );
}
else
{
    die "Unknown action name '$ACTION'!";
}
