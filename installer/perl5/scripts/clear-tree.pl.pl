#!/usr/bin/perl -w -I{QP_MODULES_DIR}

use strict;

use Shlomif::Quad::Pres::Config;

my $cfg = Shlomif::Quad::Pres::Config->new();

my $dest_dir = $cfg->get_server_dest_dir();

system("rm", "-fr", $dest_dir);

