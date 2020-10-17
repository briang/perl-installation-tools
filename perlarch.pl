#!/usr/bin/env perl

#:TAGS:

use 5.010;

use strict;  use warnings;

use Data::Dump;
################################################################################
my $OTHER_PERLBREW_OPTIONS = '-j 5';
my $PERL_SOURCE            = "/home/cpan/perl-source";
my $PERLS                  = "/home/cpan/perlbrew/perls";

my $perl = 'perl-5.32.0';

for my $p ('', '-Dusequadmath', '--ld') {
    for my $q ('', '--threaded') {
        my $name = my $options = join ' ', grep { length } $p, $q, '--noman';
        for ($name) {
            s/-Dusequadmath/qm/;
            s/--ld/ld/;
            s/--threaded/th/;
            s/--noman//;
            s/ /-/g;
            s/-$//;
        }

        $name = join '-', $perl, ($name || ());
        next if -d "$PERLS/$name";

        my $perl_tar_gz = "$perl.tar.gz";
        my @perlbrew = split ' ', join ' ',
          "perlbrew install $OTHER_PERLBREW_OPTIONS",
          "$PERL_SOURCE/$perl_tar_gz --as $name $options";
        say "-->@perlbrew";
        system(@perlbrew) == 0 or die $!;
    }
}
