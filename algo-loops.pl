#!/usr/bin/env perl

#:TAGS:

use 5.040;
use feature 'try';

use strict;  use warnings;  use autodie qw/:all/;
use experimental qw(signatures);

use Data::Dump;
# use List::AllUtils;
# use Try::Tiny;
################################################################################
use Algorithm::Loops 'NestedLoops';
use Capture::Tiny 'capture_merged';
use Getopt::Long::Descriptive;
use Path::Tiny;
use Time::Piece;

my $PATCHLEVEL_H = 'patchlevel.h'; # where perl's version is in source

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
    "$APP  %o  conf-set  ( perl-version | path-to-tarball ) +",

    [ 'clean'      => 'delete all build artefacts in `perls/` and `build/`' ],
    [ 'jobs|j=i'   => 'the number of jobs `make` will run simultaneously (default: 5)', { default => 5 } ],
    [ 'man|m'      => 'also install man pages (default: don\'t)' ],
    [ 'prefix|p=s' => 'add the given prefix to each installation' ],
    [ 'simulate|s' => 'do not install anything' ],

    [],

    [ 'help', "print this help message and exit" ],
);
my $usage = "usage: " . (split /\n/, $help)[0];

print($help), exit if $option->help;

die sprintf qq("%s" is an invalid value for "jobs"\n), $option->jobs
    if $option->jobs < 1;

die "$usage\n"
    if @ARGV < 2;

if ( ! exists $CONFIG_SET_FOR{$ARGV[0]} ) {
    my $config_set_names =
        join ", ", map { qq("$_") } sort keys %CONFIG_SET_FOR;
    die sprintf qq(First argument was "%s" but must be one of $config_set_names\n), $ARGV[0];
}

my $config = shift @ARGV;
main( $config, shift @ARGV ) while @ARGV;
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

    if ($spec_or_tarball =~ m{[./]}) { # it's a tarball
        $spec_or_tarball = path($spec_or_tarball)->absolute
    }

    my @perms          = $CONFIG_SET_FOR{$conf_set}->@*;
    my $number_of_jobs = @perms;
    my $job            = 1;
    my $all_start_time = time;
    my $perl_vname     = vname_from($spec_or_tarball);

    my @failures;
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

        if ( -d "$PERLBREW_PERLS/$as" || run_job_succeeded($command) ) { ; }
        else {
            push @failures, $as;
            say "[FAILED]"
        }

        printf "@%s job_time = %s;  total_time = %s\n\n",
            time_now(),
            map { minutes_seconds(time() - $_) } $job_start_time, $all_start_time;

        $job += 1;
    }

    if (@failures) {
        printf "%d jobs failed:\n", scalar @failures;
        printf "  %s\n", $_ for sort @failures;
    }

    cleanup($perl_vname)
        # if $option->clean;
}

sub minutes_seconds($seconds) { sprintf "%dm%d", $seconds / 60, $seconds % 60 }

sub time_now() {
    my $lt = localtime();
    return sprintf "%02d:%02d", map { $lt->$_ } qw'hour minute';
}

sub run_job_succeeded($command) {
    return 1 if $option->simulate;
    try {
        my ( $output, $status ) = capture_merged { system $command };
        return $status == 0
    } catch ($e) {}

    die "how did we get here?";
}

sub vname_from($tarball) {
    for ( $tarball ) {
        s{\.tar\.(?:gz|xz|bz2)$}[] # suffix
          && s{.*/}[];             # path
    }

    return $tarball;
}

sub get_perl_version_from_source {
    open my $IN, '<', $PATCHLEVEL_H;
    my ($revision, $version, $subversion);
    while (<$IN>) {
        $revision   = $1 if /^\#define \s+ PERL_REVISION   \s+ (\d+)/x; # 5
        $version    = $1 if /^\#define \s+ PERL_VERSION    \s+ (\d+)/x; # 37
        $subversion = $1 if /^\#define \s+ PERL_SUBVERSION \s+ (\d+)/x; # 8
    }
    die qq[cannot find perl version in "$PATCHLEVEL_H"]
        unless defined $revision && defined $version && defined $subversion;
    return qq[$revision.$version.$subversion];
}

sub cleanup($vname) {
    # FIXME: alse remove $PERLBREW_ROOT/dists/$vname\\* ?
    say qq[rm -rf $PERLBREW_ROOT/perls/$vname*  $PERLBREW_ROOT/build/*  $PERLBREW_ROOT/build.*];

    # for my $f ( "dists/$vname*", "perls/$vname*", "build/*", "build.*" ) {
    #     system "echo rm -rf $PERLBREW_ROOT/$f";
    # }
}
