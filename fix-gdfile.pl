#!/usr/bin/env perl

#:TAGS:

use 5.030;

use strict;  use warnings;  use autodie qw/:all/;
use experimental qw(signatures);

# use Capture::Tiny;
# use Data::Dump;
# use List::AllUtils;
# use Mom;
# use Moo;
# use Object::Pad
# use Path::Tiny;
# use re q(/axms);
# use Time::Piece;
# use Try::Tiny;
# use Util::H2O;
################################################################################
for (glob "perl-5.*") {
    next unless -f;
    my $untar_flags = /\.tar\.gz$/ ? "xfz" : "xfj";
    my $tar_flags   = $untar_flags =~ s/x/c/r;
    my $folder = s/\.tar\..*//r;
    system_("tar", $untar_flags, $_);
    system_(qw(chmod -R +rw), $folder);
    system_(qw(rm -rf), "$folder/ext/GD_File");
    system_(qw(cp -a ext), $folder);
    system_(qw(tar), $tar_flags, $_, $folder);
}

sub system_(@args) {
    say "@args";
    system(@args); # autodie ftw
    return 0;
}
