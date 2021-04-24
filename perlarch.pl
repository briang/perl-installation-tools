#!/usr/bin/env perl

#:TAGS:

use 5.010;

use strict;  use warnings;

use Data::Dump;
################################################################################
my $OTHER_PERLBREW_OPTIONS = '-j 5'; # -Dcc=gcc-10
my $PERLBREW_PERLS         = glob "~/perlbrew/perls";
my $USAGE                  = "./perlarch.pl  [--noqm]  <path-to-perl-tarball>";

main();
exit;

sub usage {
    print STDERR "$USAGE\n";
    exit 1 if shift;
}

sub minutes_seconds {
    my $seconds = shift;
    sprintf "%dm%d", $seconds / 60, $seconds % 60;
}

sub main {
    my %OPTIONS = map {$_=>0} qw(noqm);
    for (@ARGV) {
        my ($opt) = /^--(.+?)\b/;
        next unless $opt;

        usage(1) unless exists $OPTIONS{$opt};

        if ($opt eq 'noqm') {
            $OPTIONS{$opt} = 1;
        }
    }

    @ARGV = grep { ! /^--/ } @ARGV;

    usage(1) unless @ARGV == 1 and -f $ARGV[0];

    my $perl = my $perl_tar_gz = shift @ARGV;
    $perl =~ s{.*/}{};
    $perl =~ s{\.tar.gz$}{};

    my ($perl_version) = $perl =~ /([\d.]+)/;
    $OPTIONS{noqm} = 1 if $perl_version lt '5.22';

    my $job_start_time = time;

    for my $p ('', '-Dusequadmath', '--ld') {
        my $build_start_time = time;

        if ($OPTIONS{noqm}) {
            next if $p =~ /quad/;
        }

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

            my $t = time;
            printf "\nTime: this build=%s;  total job=%s\n\n",
              minutes_seconds($t - $build_start_time), minutes_seconds($t - $job_start_time);
        }
    }
}
