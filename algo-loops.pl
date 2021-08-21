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

my $perl = 'perl-5.35.3';

my %configure_options = (
    clang => '-DCC=clang',
    dbg   => '-DEBUGGING=both',
    gcc   => '-DCC=gcc',
    ld    => '--ld',
    qm    => '-Dusequadmath',
    th    => '--thread',
);

my @config_permutations = NestedLoops (
    [
        [ sort qw(gcc clang) ],
#        [ sort qw(dbg NIL)   ],
#        [ sort qw(qm ld NIL) ],
#        [ sort qw(th NIL)    ],
    ],
    sub {
        [ grep { $_ ne 'NIL'} @_ ]
    }
);

my $number_of_jobs = @config_permutations;
my $job = 1;
my $all_start_time = time;
for my $perm (@config_permutations) {
    my @terms = @$perm;

    my $binary_name = join '-', $perl, @terms;
    my $command = join ' ',
      qw(perlbrew install), $perl,
      '-j', 5,
      (map { $configure_options{$_} } @terms),
      "--as", $binary_name;

    say "[$job/$number_of_jobs -- $command]";
    my $job_start_time = time;
    run_job($command);
    printf "job_time = %s;  total_time = %s\n\n",
      map { minutes_seconds(time() - $_) } $job_start_time, $all_start_time;

    $job += 1;
}

sub minutes_seconds {
    my $seconds = shift;
    sprintf "%dm%d", $seconds / 60, $seconds % 60;
}

sub run_job($command) {
    my ( $output, $exit ) = capture_merged { system($command) };
    die "$output\n" if $exit != 0;
}
