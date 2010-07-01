#!/usr/bin/perl -w
# Generates a lexc format dictionary file from maddeler.tab and anlams.tab from tdk
# See README for the column descriptions of these files.  The important ones are:
# maddeler[2,3]: WORD_ID, altsay (primary key, 83415 unique)
# maddeler[6]: maddebas (main spelling), maddeler[16]: ARAMA (reduced spelling)
# maddeler[9,10,11]: onek, cogul, ozel (useful info for dict)
# anlams[4,5,6,7,8]: kelimeturu0,1,2,3,4 (0 gives count, 1-4 actual types)
# anlams[14]: fiil (boolean)


use strict;
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
    my $word = $m->[6];		# maddebas
    for my $i (5 .. 8) {	# kelimeturu1-4
	if (defined $POS{$a[$i]}) {
	    output($word, $POS{$a[$i]});
	} elsif ($a[$i] eq '0' or $a[$i] eq '\N') {
	    # do nothing
	} else {
	    warn "Warning: $a[$i] not a recognized part of speech.\n";
	}
    }
}
close(A);

sub output {
    my ($word, $pos) = @_;
    return if $word =~ / /;	# skip multiwords
    $word =~ s/m[ae]k$// if $pos eq 'Verb'; # get rid of mak/mek
    my $str = "$word\t+$pos;\n";
    print $str unless $seen{$str}++;
}
