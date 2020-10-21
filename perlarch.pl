#!/usr/bin/env perl

#:TAGS:

use 5.010;

use strict;  use warnings;

use Data::Dump;
################################################################################
my $OTHER_PERLBREW_OPTIONS = '-j 5';
my $PERLBREW_PERLS         = "/home/cpan/perlbrew/perls";
my $USAGE                  = "usage: perl perlarch.pl <path-to-perl-tarball>";

main();
exit;

sub main {
    die "$USAGE\n" unless @ARGV and -f $ARGV[0];

    my $perl = my $perl_tar_gz = shift @ARGV;
    $perl =~ s{.*/}{};
    $perl =~ s{\.tar.gz$}{};

    for my $p ('', '-Dusequadmath', '--ld') {
        for my $q ('', '--thread') {
            my $name = my $options = join ' ', grep { length } $p, $q, '--noman';
            for ($name) {
                s/-Dusequadmath/qm/;
                s/--ld/ld/;
                s/--thread/th/;
                s/--noman//;
                s/ /-/g;
                s/-$//;
            }

            $name = join '-', $perl, ($name || ());
            next if -d "$PERLBREW_PERLS/$name";

            my @perlbrew = split ' ', join ' ',
              "perlbrew install $OTHER_PERLBREW_OPTIONS",
              "$perl_tar_gz --as $name $options";
            say "-->@perlbrew";
            system(@perlbrew) == 0 or die $!;
        }
    }
}
