# Perl Installation Tools

A set of (half-baked) tools to help with installing perl, particularly
old perls

## Purpose

I like to have a range of perls available for testing
purposes. However, compiling perls going back nearly 15 years is
problematical. perl-5.6.2 proved to be a step too far :(

This repository is a set of tools and notes I used to accomplish this.

## Requirements

* perlbrew
* any perl. Version shouldn't matter
* autodie.pm (included with perl-5.10.1), or write some error handling :)

## Workflow

TODO

### Result matrix

Perl | Compiler | Needs new GDBM_File/t/fatal.t?
-|-|-
5.6.2  | _failed_ |
5.8.9  | clang |
5.10.1 | gcc |
5.12.5 | gcc |
5.14.4 | gcc |
5.16.3 | gcc |
5.18.4 | gcc | Yes
5.20.3 | gcc | Yes
5.22.4 | gcc | Yes
5.24.4 | gcc | Yes
5.26.3 | gcc | Yes
5.28.3 | gcc | Yes
5.30.0 | gcc |
5.30.1 | gcc |
5.30.2 | gcc |
5.30.3 | gcc |
5.32.0 | gcc |

Compiled using clang-10.0.0 and gcc-10.0.1 on an Ubuntu 20.04
VirtualBox VM (6GB RAM, 4 CPUs) running on Windows 10.

Also tested with Ubuntu clang version 12.0.0-1ubuntu1 gcc (Ubuntu
10.3.0-1ubuntu1) 10.3.0.

## Catalog of contents

File | Description
-|-
fix-gdbm_file.pl | Repack perl sources with updated ```GDBM_File```.
install-dists.sh | install dists from file into many perls
install-perls | Attempt to install multiple perls with multiple compilers.
perlarch.pl | perl script to install arch variants (longdouble, quadmath, threaded etc)
obsolete/ | Folder containing old scripts
README | This!
