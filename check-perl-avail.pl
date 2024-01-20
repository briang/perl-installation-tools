#!/usr/bin/env perl

#:TAGS:

use v5.36;
use autodie ':all';
use utf8;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use Data::Dump; # FIXME
################################################################################
use HTTP::Tiny;

my $URL   = 'https://metacpan.org/recent';
my $EVERY = 300; # seconds
my $RE    = qr/>(perl-5.*?)</;

while () {
    my $response = HTTP::Tiny->new->get($URL);
    die "Failed: $response->{status} - $response->{reason}\n"
        unless $response->{success};
    my $recent = $response->{content}
        or die "empty response\n";

    for (split /\n/, $recent) {
        if (/$RE/) {
            say "$1 is available";

            while () { $|=1; beep(); print "*"; sleep 1 }
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
