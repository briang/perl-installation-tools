#!/usr/bin/perl

#:TAGS:

use 5.010;

use strict;  use warnings;

use Data::Dump;
################################################################################
use Getopt::Long::Descriptive;

my $PERLBREW_ROOT = $ENV{PERLBREW_ROOT};

main();
exit;

sub main {
    my ($option, $usage) = parse_options();
    die "No tarball given\n" unless @ARGV == 1;
    die "File not found\n" unless -f $ARGV[0];

    die "perlbrew home ($PERLBREW_ROOT) not found" unless -d $PERLBREW_ROOT;

    my $perl = my $perl_tar_gz = shift @ARGV;
    $perl =~ s{.*/}{};
    $perl =~ s{\.tar.gz$}{};

    my ($perl_version) = $perl =~ /([\d.]+)/;
    my $option_noqm = $perl_version lt '5.22'
      || $perl_version =~ /^5\.\d\./ # 5.8 specifically
      || $perl_version eq '5.28.3';

    my $job_start_time = time;

    for my $p ('', '-Dusequadmath', '--ld') {
        next if $p =~ /quad/ && $option_noqm;

        for my $q ('', '--thread') {
            my $build_start_time = time;
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
            next if -d "$PERLBREW_ROOT/perls/$name";

            my @perlbrew = split ' ', join ' ',
              "perlbrew install",
              "-j", $option->{jobs},
              "$perl_tar_gz --as $name $options",
              $option->cc ? '-Dcc=' . $option->cc : ();
            say "-->@perlbrew";
            system(@perlbrew) == 0 or die $!
              unless $option->simulate;

            my $t = time;
            printf "\nTime: this build=%s;  total job=%s\n\n",
              minutes_seconds($t - $build_start_time), minutes_seconds($t - $job_start_time);
        }
    }
}

sub minutes_seconds {
    my $seconds = shift;
    sprintf "%dm%d", $seconds / 60, $seconds % 60;
}

sub parse_options {
    my $COMMAND = Getopt::Long::Descriptive::prog_name();

    my ($option, $usage) = describe_options(
        "$COMMAND  %o  path-to-perl-source-tarball",
        [ 'cc=s'       => 'CYO compiler!' ],
        [ 'jobs|j=i'   => 'Number of jobs', { default => 5 } ],
        [ 'noqm'       => 'Skip quadmath builds' ],
        [ 'simulate|S' => 'Simulate actions only' ],
        [],
        [ 'help|h'     => 'Display this help message and exit' ],

        { getopt_conf => [ # some of these are already default
            "gnu_compat",       # C<--opt=> sets empty string
            "no_auto_abbrev",   # disallow abbreviated long options
            "no_getopt_compat", # disallow C<+> for specifying options
            "no_ignore_case",   # case is important
            "permute",          # options can appear anywhere
            "bundling" ] }      # C<-ab> is equivalent to C<-a -b> (THIS MUST BE LAST)
    );

    print($usage) and exit if $option->help;

    return ($option, $usage);
}
