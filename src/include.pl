#!/usr/bin/perl -w
use strict;

sub process {
    open(my $in, shift) || die $!;
    while(<$in>) {
	if (/^#include\s+\"([^\"]+)\"/) {
	    process($1);
	} else {
	    print;
	}
    }
}

while(<>) {
    if (/^#include\s+\"([^\"]+)\"/) {
	process($1);
    } else {
	print;
    }
}

