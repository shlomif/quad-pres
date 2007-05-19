#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use strict;
use Shlomif::Quad::Pres::Path;

my $filename = shift(@ARGV);

$filename =~ s{\.wml$}{};
$filename =~ s{/$}{/index.html};

my $path_man = Shlomif::Quad::Pres::Path->new();

my $scripts_dir = $path_man->get_scripts_dir();
my $wml_dir = $path_man->get_wml_dir();
my $modules_dir = $path_man->get_modules_dir();

my $local_wml_dir = $ENV{"HOME"}. "/.Quad-Pres/lib/";

my @local_wml = 
    $ENV{"QUAD_PRES_NO_HOME_LIB"} 
        ? ()
        : ("-I", $local_wml_dir)
    ;

exec (
    "wml",
    "-I", $wml_dir,
    @local_wml,
    "-DFILENAME=$filename",
    "--passoption=3,-I$modules_dir",
    "src/$filename.wml"
);

