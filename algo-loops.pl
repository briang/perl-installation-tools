#!/usr/bin/env perl

#:TAGS:

use 5.030;

use strict;  use warnings;  use autodie qw/:all/;
use experimental qw(signatures);

# use Capture::Tiny;
use Data::Dump;
# use List::AllUtils;
# use Object::Pad
# use Path::Tiny;
# use Time::Piece;
# use Try::Tiny;
################################################################################
use Algorithm::Loops 'NestedLoops';
use Capture::Tiny 'capture_merged';
use Getopt::Long::Descriptive;

# @ARGV = qw[full perl-5.37.0]; # XXX

my $APP            = $0 =~ s{.*/}{}r;
my $PERLBREW_ROOT  = $ENV{PERLBREW_ROOT};
my $PERLBREW_PERLS = "$PERLBREW_ROOT/perls";
my $OPT_MAN        = 0; # install manpages
my $JOBS           = '-j 5';

my %CONFIG_SET_FOR = (
    full => [
        NestedLoops(
            [ [ sort qw(gcc clang) ],
              [ sort qw(dbg NIL)   ],
              [ sort qw(qm ld NIL) ],
              [ sort qw(th NIL)    ] ],
            sub { [ grep { $_ ne 'NIL'} @_ ] }
        ),
    ],
    quick => [
        NestedLoops(
            [ [ sort qw(ld qm NIL) ],
              [ sort qw(th NIL)    ] ],
            sub { [ grep { $_ ne 'NIL'} @_ ] }
        ),
    ],
    vquick => [ [] ],           # no options at all
);

if ( @ARGV != 2 ) {
    die qq(usage: $APP full|quick perl-spec\n);
}

if ( ! exists $CONFIG_SET_FOR{$ARGV[0]} ) {
    my $config_set_names =
        join ", ", map { qq("$_") } sort keys %CONFIG_SET_FOR;
    die sprintf qq(First argument was "%s" but must be one of $config_set_names\n), $ARGV[0];
}

main( @ARGV );
say "\nAll done!";

exit;

sub main(@cli_args) {
    my ( $conf_set, $spec_or_tarball ) = @cli_args;

    my %configure_options = (
        clang => '-DCC=clang',
        dbg   => '-DEBUGGING=both',
        gcc   => '-DCC=gcc',
        ld    => '--ld',
        qm    => '-Dusequadmath',
        th    => '--thread',
    );

    my @perms          = $CONFIG_SET_FOR{$conf_set}->@*;
    my $number_of_jobs = @perms;
    my $job            = 1;
    my $all_start_time = time;
    my $perl_vname     = vname_from($spec_or_tarball);

    for my $perm (@perms) {
        my @terms = @$perm;

        my $as = join '-', $perl_vname, @terms;

        my $command = join ' ',
          qw(perlbrew install), $spec_or_tarball,
          $JOBS,
          ($OPT_MAN ? () : '--noman'),
          (map { $configure_options{$_} } @terms),
          "--as", $as;

        say "[$job/$number_of_jobs -- $command]";
        my $job_start_time = time;

        run_job($command)
          unless -d "$PERLBREW_PERLS/$as";

        printf "job_time = %s;  total_time = %s\n\n",
          map { minutes_seconds(time() - $_) } $job_start_time, $all_start_time;

        $job += 1;
    }
}

sub minutes_seconds($seconds) { sprintf "%dm%d", $seconds / 60, $seconds % 60 }

sub run_job($command) {
    if (0) {
        say "DRY_RUN: $command";
        return;
    }
    my ( $output, $exit ) = capture_merged { system($command) };
    die "$output\n" if $exit != 0;
}

sub vname_from($tarball) {
    for ( $tarball ) {
        s{\.tar\.(?:gz|xz|bz2)$}[] # suffix
          && s{.*/}[];             # path
    }

    return $tarball;
}
