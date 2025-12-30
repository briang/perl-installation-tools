#!/usr/bin/env perl

use v5.36;
use autodie ':all';
use utf8;

use Data::Dump; # XXX
################################################################################
die qq[usage: perl $0 <config> <minimum perl5 version (as integer)> \n]
    if @ARGV != 2;

my ($config, $minimum_version) = @ARGV;
my @perls = perls_of_interest();

my @command = ( './algo-loops.pl', $config, @perls );
say "@command";
exit unless prompt('Proceed? ') eq 'y';

system(@command); # ignore fails
exit;
################################################################################
sub perls_of_interest() {
    my sub isnt_dev_perl($m) { $m % 2 == 0 }
    grep {
        my ($major, $minor, $patch) = version_components($_);
        $minor >= $minimum_version && isnt_dev_perl($minor)
    } all_perls();
}

sub version_components($version) { $version =~ /-(\d+)\.(\d+)\.(\d+)/ }

sub all_perls() {
    grep { /^perl-/ }
    map  { s/^i?\s+//; s/\s+$//; $_ } sort qx[perlbrew available];
}

sub prompt {
    $| = 1;
    print "@_";
    chomp(my $ans = lc <stdin>);
    return $ans;
}
