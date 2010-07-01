#!/usr/bin/perl -w -CSD
# Generates a lexc format dictionary file from maddeler.tab and anlams.tab from tdk
# See README for the column descriptions of these files.  The important ones are:
# maddeler[2,3]: WORD_ID, altsay (primary key, 83415 unique)
# maddeler[6]: maddebas (main spelling), maddeler[16]: ARAMA (reduced spelling)
# maddeler[9,10,11]: onek, cogul, ozel (useful info for dict)
# anlams[4,5,6,7,8]: kelimeturu0,1,2,3,4 (0 gives count, 1-4 actual types)
# anlams[14]: fiil (boolean)


use strict;
use utf8;

my %seen;

my %POS = (
    29 => 'Interj', 		# ünlem	       
    30 => 'Noun',		# isim	       
    31 => 'Adj',		# sıfat	       
    32 => 'Verb',		# (-e)	       
    33 => 'Verb',		# (-i)	       
    34 => 'Verb',		# (nsz)	       
    35 => 'Adverb',		# zarf	       
    36 => 'Verb',		# (-le)	       
    37 => 'Verb',		# (-den)	       
    38 => 'Postp+PCNom',	# edat	       
    39 => 'Conj',		# bağlaç	       
    40 => 'Pron+Pers',		# zamir	       
    271 => 'Verb',		# (yardımcı fiil)
    274 => 'Verb'		# (-de)
    );

my %maddeler;
open(M, "maddeler.tab") or die $!;
while(<M>) {
    chop;
    my @m = split /\t/;
    my $key = "$m[2],$m[3]";	# WORD_ID and altsay
    die if defined $maddeler{$key};
    $maddeler{$key} = \@m;
}
close(M);

open(A, "anlams.tab") or die $!;
while(<A>) {
    chop;
    my @a = split /\t/;
    my $key = "$a[0],$a[1]";	# WORD_ID and altsay
    my $m = $maddeler{$key};
    if (not defined $m) {
	warn "Warning: $key not found in maddeler.tab\n";
	next;
    }
    for my $i (5 .. 8) {	# kelimeturu1-4
	if (defined $POS{$a[$i]}) {
	    output($m, \@a, $i);
	} elsif ($a[$i] eq '0' or $a[$i] eq '\N') {
	    # do nothing
	} else {
	    warn "Warning: $a[$i] not a recognized part of speech.\n";
	}
    }
}
close(A);

sub output {
    my ($m, $a, $i) = @_;
    my $word = $m->[6];		# maddebas
    my $wpos = $POS{$a->[$i]};

    return if $word =~ / /;	# skip multiwords
    $word =~ s/m[ae]k$// if $wpos eq 'Verb'; # get rid of mak/mek

#    $wpos .= '+Prop' if ($wpos eq 'Noun' and $m->[11] == 1); # ozel
    $wpos .= '^PL'   if ($wpos eq 'Noun' and $m->[10] == 1); # cogul

    my $ek = $m->[9];		# onek
    $ek =~ s/[- ]//g;
    for my $ek1 (split(/,/, $ek)) {
	my $flag = onek($word, $ek1);
	my $str = "$word$flag\t+$wpos;\n";
	print $str unless $seen{$str}++;
    }
}

sub oneof { my $x = shift; ($_ eq $x) && return 1 for @_; }

sub onek {
    my ($word, $ek) = @_;
    my $flag = '';

    return $flag if $ek eq '\N';

    # Verb aorist flags

    if (oneof($ek, 'dar', 'der')) {
	$flag = '^CV^AR';
    } elsif (oneof($ek, 'ar', 'er', 'r')) {
	$flag = '^AR';
    } elsif ($ek =~ /^[ıiuü]r$/) {
	# do nothing

    } else {

	my $lastchar = substr($word, -1);
	my ($lastvowel) = ($word =~ /([aeıioöuüâîû])[^aeıioöuüâîû]*$/);
	my ($lastconspair, $lastconspair2) = ('', '');
	$lastconspair = $word;
	$lastconspair =~ s/[aeıioöuüâîû]//g;
	$lastconspair = substr($lastconspair, -2);
	$lastconspair = '' unless length($lastconspair) == 2;

	if ($lastconspair and $lastconspair =~ /[pçtkg]$/) {
	    $lastconspair2 = $lastconspair;
	    if ($lastconspair2) {
		$lastconspair2 =~ s/p$/b/;
		$lastconspair2 =~ s/ç$/c/;
		$lastconspair2 =~ s/t$/d/;
		$lastconspair2 =~ s/[kg]$/ğ/;
	    }
	}

	# Noun flags
	
	if ($ek =~ /^$lastchar$lastchar/) {
	    $flag .= '^CD';
	}
	if ($lastchar =~ /^[pçtkg]$/ and $ek =~ /[bcdgğ][ıiuü]$/) {
	    $flag .= '^CV';
	}
	if ($lastconspair and $ek =~ /^$lastconspair/) {
	    $flag .= '^VD';
	}
	elsif ($lastconspair2 and $ek =~ /^$lastconspair2/) {
	    $flag .= '^VD';
	}
	if ($lastvowel =~ /^[aâıouû]$/ and $ek =~ /[iü]$/) {
	    $flag .= '^VF';
	}
	if ($ek eq 'yu') {
	    $flag .= '^Y';		# rename this yu, check out yi yı in tdk, rethink ne
	}
	
	# Unrecognized
	
	if ($flag ne '' or
	    $ek =~ /^y[ıi]$/ or
	    $ek =~ /^[pçtk]\'[ıiuü]$/) {
	    # do nothing
	} else {
	    warn "Warning: $word-$ek not a recognized suffix (lastchar=$lastchar,lastvowel=$lastvowel,lastconspair=$lastconspair,lcp2=$lastconspair2,flag=$flag).\n";
	}
    }
    
    return $flag;
}
