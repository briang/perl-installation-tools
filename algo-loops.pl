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

my $PERLBREW_ROOT  = $ENV{PERLBREW_ROOT};
my $PERLBREW_PERLS = "$PERLBREW_ROOT/perls";

main( qw[perl-5.35.3 full] ); # XXX
say "\nAll done!";

exit;

sub main(@cli_args) {
    my ($perl, $conf_set) = @cli_args;

    my %configure_options = (
        clang => '-DCC=clang',
        dbg   => '-DEBUGGING=both',
        gcc   => '-DCC=gcc',
        ld    => '--ld',
        qm    => '-Dusequadmath',
        th    => '--thread',
    );

    my %config_set_for = (
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
    );

    my @perms          = $config_set_for{$conf_set}->@*;
    my $number_of_jobs = @perms;
    my $job            = 1;
    my $all_start_time = time;

    for my $perm (@perms) {
        my @terms = @$perm;

        my $as = join '-', $perl, @terms;

        my $command = join ' ',
          qw(perlbrew install), $perl,
          '-j', 5,
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
    my ( $output, $exit ) = capture_merged { system($command) };
    die "$output\n" if $exit != 0;
}
