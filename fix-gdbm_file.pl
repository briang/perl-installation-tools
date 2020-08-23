#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw/:all/;

for (glob "perl-5.*") {
    next unless -f;
    my $untar_flags = /\.tar\.gz$/ ? "xfz" : "xfj";
    my $tar_flags   = $untar_flags =~ s/x/c/r;
    my $folder      = s/\.tar\..*//r;

    system_("tar", $untar_flags, $_);
    system_(qw(chmod -R +rw), $folder);
    system_(qw(rm -rf), "$folder/ext/GD_File");
    system_(qw(cp -a GDBM_File), "$folder/ext");
    system_(qw(tar), $tar_flags, $_, $folder);
}

sub system_(@args) {
    say "@args";
    system(@args); # autodie ftw
    return 0;
}
