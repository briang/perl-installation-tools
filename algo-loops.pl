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
    vquick => [ [] ], # no options at all
);

$Getopt::Long::autoabbrev = 0;  # don't allow abbrevs of --some-long-option
my ($option, $help) = describe_options(
    "$APP  %o  conf-set  perl-version | path-to-tarball",

    [ 'jobs|j=i'   => 'the number of jobs `make` will run simultaneously (default: 5)', { default => 5 } ],
    [ 'man|m'      => 'also install man pages (default: don\'t)' ],
    [ 'prefix|p=s' => 'add the given prefix to each installation' ],
    [ 'simulate|s' => 'do not install anything' ],

    [],

    [ 'help', "print this help message and exit" ],
);
my $usage = "usage: " . (split /\n/, $help)[0];

print($help), exit if $option->help;

die qq("jobs" cannot be negative\n) if $option->jobs < 0;

die "$usage\n"
    if @ARGV != 2;

if ( ! exists $CONFIG_SET_FOR{$ARGV[0]} ) {
    my $config_set_names =
        join ", ", map { qq("$_") } sort keys %CONFIG_SET_FOR;
    die sprintf qq(First argument was "%s" but must be one of $config_set_names\n), $ARGV[0];
}

main( @ARGV );
say "\nAll done!";

exit;
################################################################################
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
        $as = $option->prefix . $as
            if $option->prefix;

        my $command = join ' ',
          qw(perlbrew install), $spec_or_tarball,
          ($option->jobs ? '-j ' . $option->jobs : ()),
          ($option->man ? () : '--noman'),
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
    return if $option->simulate;
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
