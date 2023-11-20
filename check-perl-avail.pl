#!/usr/bin/env perl

#:TAGS:

use v5.36;
use autodie ':all';
use utf8;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use Data::Dump; # FIXME
################################################################################
use LWP::Simple;
my $URL = 'https://metacpan.org/recent';

my $recent = get $URL
    or die $!;

for (split /\n/, $recent) {
    if (/>(perl-5.*?)</) {
        say "$1 is available";
        exit;
    }
}

say "Nope!";
