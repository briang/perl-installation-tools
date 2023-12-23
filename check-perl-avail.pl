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

my $URL   = 'https://metacpan.org/recent';
my $EVERY = 300; # seconds
my $RE    = qr/>(perl-5.*?)</;

while () {
    my $recent = get $URL
        or die $!;

    for (split /\n/, $recent) {
        if (/$RE/) {
            say "$1 is available";

            while () { beep(); sleep 1 }
        }
    }

    beep("Nope at " . localtime);

    sleep $EVERY;
}

sub beep($msg="") {
    $| = 1;
    say $msg if $msg;
    print "\a";
}
