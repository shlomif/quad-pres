#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use strict;

use HTML::Links::Localize;

use Shlomif::Quad::Pres::Path;
use Shlomif::Quad::Pres::Config;

my $cfg = Shlomif::Quad::Pres::Config->new();

my $default_dest_dir = $cfg->get_server_dest_dir();

my $hard_disk_dest_dir = $cfg->get_hard_disk_dest_dir();

my $converter= 
    HTML::Links::Localize->new(
        'base_dir' => $default_dest_dir,
        'dest_dir' => $hard_disk_dest_dir,
    );

$converter->process_dir_tree('only-newer' => 1);

