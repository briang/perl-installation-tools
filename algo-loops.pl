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

my $APP            = $0;
my $PERLBREW_ROOT  = $ENV{PERLBREW_ROOT};
my $PERLBREW_PERLS = "$PERLBREW_ROOT/perls";
my $OPT_MAN        = 0; # install manpages
my $JOBS           = '-j 5';

# $Getopt::Long::autoabbrev = 0;  # don't allow abbrevs of --some-long-option
# my ($option, $usage) = describe_options(
#     "$APP  %o  conf-set  perl-version | path-to-tarball",
#     [ 'halt|H' => 'halt on error' ],
#     [],
#     # [ 'verbose|v', "print extra stuff" ],
#     [ 'help', "print usage message and exit" ],
# );

# print($usage), exit if $option->help;

if ( @ARGV != 2 ) {
    die qq(usage: $APP full|quick perl-spec\n);
}
elsif ( $ARGV[0] !~ /full|quick/ ) {
    die sprintf qq(First argument was "%s" but must be "full" or "quick"\n), $ARGV[0];
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
