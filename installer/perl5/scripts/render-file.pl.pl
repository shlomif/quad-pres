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

exec("wml -DFILENAME=\"$filename\" -I \"$wml_dir\" --passoption=3,-I\"$modules_dir\" \"src/$filename.wml\" | \"$scripts_dir\"/fix-gvim-html.pl");

