#!/usr/bin/perl -w
# Regression test for analyzer.
# Reads words with required analyses from stdin.

use strict;
use Data::Dumper;

open(LU, '| lookup -q model.fst | singleline.pl > regtest.dat') or die $!;
my %dict;
while(<>) {
    my ($w, $p) = split;
    $dict{$w}{$p}++;
    print LU "$w\n";
}
close(LU);

open(BAD, '>regtest.bad') or die $!;
open(NON, '>regtest.non') or die $!;

my %cnt;
my %seen;
open(FP, 'regtest.dat') or die $!;
while(<FP>) {
    my ($w, @g) = split;
    die if not @g;
    next if $seen{$w}++;
    my @p = keys(%{$dict{$w}});
    die if not @p;
    $cnt{instance}++;
    my %g; $g{$_}++ for @g;
    for my $p (@p) {
	$cnt{parse}++;
	if (defined $g{$p}) {
	    $cnt{goodparse}++;
	} else {
	    $cnt{badparse}++;
	    print BAD join("\t", $w, @p, "|", @g)."\n";
	}
    }
    if (@g == 1 and $g[0] =~ /\+\?$/) {
	$cnt{noparse}++;
	print NON join("\t", $w, @p)."\n";
    }
}
close(FP);
close(NON);
close(BAD);

print Dumper(\%cnt);
