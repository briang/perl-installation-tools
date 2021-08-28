#!/usr/bin/env perl

use strict;
use warnings;

die "No archives given" if @ARGV == 0;

for (@ARGV) {
    # as things stand, tar extracts to the current folder, no matter
    # where the archive is located. From there, things just get worse :(
    # So, just don't do it.
    die qq["$_" appears to be in another directory] if m{/};

    die qq["$_" does not exist\n] unless -e;
    die qq["$_" is not a file\n]  unless -f;
    die qq["$_" doesn't look like a perl archive\n] unless /\bperl-5\./;

    (my $folder = $_) =~ s/\.tar\..*//;

    untar($_);
    system_(qw(chmod -R +rw), $folder);
    system_(qw(cp -a fatal.t), "$folder/ext/GDBM_File/t/");
    tar($_, $folder);
    system_(qw(rm -rf), $folder);
}

sub tar {
    my ($archive, $folder) = @_;
    system_(qw(tar cfa), $archive, $folder); # tar a => compress based on archive suffix
}

sub untar {
    system_(qw(tar xf), shift); # tar auto decompresses based on archive suffix
}

sub system_ {
    print "@_\n";
    system(@_) == 0 or die "system() failed: $?";
}
