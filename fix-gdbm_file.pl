#!/usr/bin/env perl

use strict;
use warnings;

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
    system_(qw(rm -rf), $folder);
}

sub system_ {
    print "@_\n";
    system(@_) == 0 or die "system() failed: $?";
    return 0;
}
