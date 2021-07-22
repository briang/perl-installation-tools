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

my $perl = 'perl-5.34.0';

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
        [ sort qw(dbg NIL)   ],
        [ sort qw(qm ld NIL) ],
        [ sort qw(th NIL)    ],
    ],
    sub {
        [ grep { $_ ne 'NIL'} @_ ]
    }
);

for my $perm (@config_permutations) {
    my @terms = @$perm;

    my $binary_name = join '-', $perl, @terms;
    my $command = join ' ',
      qw(perlbrew install), $perl,
      map { $configure_options{$_} } @terms;

    say "$command --as $binary_name";
}
