#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;
use File::Temp 'tempdir';

use Data::Dump; # XXX
@ARGV = '/home/cpan/perl-source/perl-5.28.3.tar.gz';

die "No archives given" if @ARGV == 0;
dd
my $cwd = getcwd;

for my $archive (@ARGV) {
    for ($archive) {
        die qq["$_" does not exist\n] unless -e;
        die qq["$_" is not a file\n]  unless -f;
        die qq["$_" doesn't look like a perl archive\n] unless /\bperl-5\./;
    }

    # Here's some typical values:
    #
    # $archive       = "/home/cpan/perl-source/perl-5.28.3.tar.gz"
    # $cwd           = "/home/cpan/perlbrew/tools"
    # $temp_folder   = "/tmp/0nIOKcqESN"
    # $perl_version  = "perl-5.28.3"
    # $source_folder = "/tmp/0nIOKcqESN/perl-5.28.3"
    #
    # I hate these var names :(

    my $temp_folder = tempdir;
    my ($perl_version) = $archive =~ m{.*/(.*?)(?:\.tar\.gz|\.tar\.bz2|\.tar\.xz|\.tgz)$};
    untar($archive, $temp_folder);
    my ($source_folder) = glob "$temp_folder/*";
    system_(qw(chmod -R +rw), $source_folder);
    write_file_from_data("$source_folder/ext/GDBM_File/t/fatal.t");
    chdir $temp_folder or die qq(Cannot change to "$temp_folder": $!);
    tar("$perl_version.tar.gz", $perl_version);
    system_('mv', "$temp_folder/$perl_version.tar.gz", $cwd);
}

sub tar {
    my ($archive, $folder) = @_;
    system_(qw(tar cfa), $archive, $folder); # tar a => compress based on archive suffix
}

sub untar {
    my ($archive, $folder) = @_;
    system_(qw(tar xf), $archive, "--directory", $folder); # tar auto decompresses based on archive suffix
}

sub system_ {
    print "@_\n";
    system(@_) == 0 or die "system() failed: $?";
}

sub write_file_from_data {
    my $dest = shift;
    open my $OUT, ">", $dest
      or die qq(Cannot open "$dest" for writing: $!);

    print $OUT <DATA>;
}
__DATA__
#!./perl -w
#
# Exercise the error handling callback mechanism in gdbm.
#
# Try to trigger an error by surreptitiously closing the file handle which
# gdbm has opened.  Note that this won't trigger an error in newer
# releases of the gdbm library, which uses mmap() rather than write() etc:
# so skip in that case.

use strict;

use Test::More;
use Config;

BEGIN {
    plan(skip_all => "GDBM_File was not built")
	unless $Config{extensions} =~ /\bGDBM_File\b/;

    # https://rt.perl.org/Public/Bug/Display.html?id=117967
    plan(skip_all => "GDBM_File is flaky in $^O")
        if $^O =~ /darwin/;

    plan(tests => 8);
    use_ok('GDBM_File');
}

unlink <fatal_dbmx*>;

open my $fh, '<', $^X or die "Can't open $^X: $!";
my $fileno = fileno $fh;
isnt($fileno, undef, "Can find next available file descriptor");
close $fh or die $!;

is((open $fh, "<&=$fileno"), undef,
   "Check that we cannot open fileno $fileno. \$! is $!");

umask(0);
my %h;
isa_ok(tie(%h, 'GDBM_File', 'fatal_dbmx', GDBM_WRCREAT, 0640), 'GDBM_File');

isnt((open $fh, "<&=$fileno"), undef, "dup fileno $fileno")
    or diag("\$! = $!");
isnt(close $fh, undef,
     "close fileno $fileno, out from underneath the GDBM_File");

# store some data to a closed file handle

my $res = eval {
    $h{Perl} = 'Rules';
    untie %h;
    99;
};

SKIP: {
    skip "Can't trigger failure", 2 if (defined $res and $res == 99);

    is $res, undef, "eval should return undef";

    # Observed "File write error" and "lseek error" from two different
    # systems.  So there might be more variants. Important part was that
    # we trapped the error # via croak.
    like($@, qr/ at .*\bfatal\.t line \d+\.\n\z/,
         'expected error message from GDBM_File');
}

unlink <fatal_dbmx*>;
