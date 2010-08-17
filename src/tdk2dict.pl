#!/usr/bin/perl -w -CSD
# Generates a lexc format dictionary file from maddeler.tab and anlams.tab from tdk
# See dict/tdk-cd/README for the column descriptions of these files.  The important ones are:
# maddeler[2,3]: WORD_ID, altsay (primary key, 83415 unique)
# maddeler[6]: maddebas (main spelling), maddeler[16]: ARAMA (reduced spelling)
# maddeler[9,10,11]: onek, cogul, ozel (useful info for dict)
# maddeler[15]: birlekel (multiwords)
# anlams[4,5,6,7,8]: kelimeturu0,1,2,3,4 (0 gives count, 1-4 actual types)
# anlams[14]: fiil (boolean)

# Special characters in TDK stems:
# Stems may consist of all uppercase and lowercase characters plus:
# [ ]: multiwords contain spaces: su muhallebisi
# [()]: alternatives contain parens: daim etmek (veya eylemek)
# [,]: some multiwords have commas: anca beraber, kanca beraber
# [...]: some multiwords have ellipses: hem ... hem ...
# [!]: some entries have exclamation mark: yürü!, ye kürküm ye!
# [?]: some entries have question mark: zorun ne? vay sen misin?
# [-]: some multiwords have hyphens: e-mail, Kitab-ı Mukaddes
# ["]: some phrases have quotes: gelini ata bindirmişler "ya nasip" demiş
# [']: some entries have apostrophe: Kur'an, a'dan z'ye (kadar)
# [;]: some phrases have semicolons: söz var, iş bitirir; söz var, baş yitirir
# [/]: slash shows alternatives: mı / mi, mu / mü; ...-ında / ...-inde değil
# [:]: one phrase has a colon: aza sormuşlar: "nereye?" "çoğun yanına" demiş

use strict;
use utf8;

sub oneof { my $x = shift; ($_ eq $x) && return 1 for @_; }

my %seen;
my %pos1;
my %exc;

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
    38 => 'Postp',		# edat	       
    39 => 'Conj',		# bağlaç	       
    40 => 'Pron',		# zamir	       
    271 => 'Verb',		# (yardımcı fiil)
    274 => 'Verb'		# (-de)
    );

while(<DATA>) {			# list exceptions at the end of this file
    next if /^\#/;		# allow comments
    print if /\t\S/;		# copy to output if second field
    my ($word) = /^([^^\t]+)/;	# word may have phonetic flags starting with ^
    $exc{$word}++;		# create exception list to ignore tdk
}

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
	my $wpos = $POS{$a[$i]};
	if (defined $wpos) {	
	    # regular part of speech
	    output($m, \@a, $wpos);
	    $pos1{$key} = $wpos if not defined $pos1{$key};
	} elsif (oneof($a[$i], '0', '\N')) {
	    # most part of speech fields are left undefined.
	    # in this case the last known pos is used if defined.
	    output($m, \@a, $pos1{$key}) if defined $pos1{$key};
	} else {
	    die "Error: $a[$i] not a recognized part of speech.\n";
	}
    }
    output($m, \@a, 'Noun') if not defined $pos1{$key};
}
close(A);

sub output {
    my ($m, $a, $wpos) = @_;
    my $word = $m->[6];		# maddebas
    my $birlekel = $m->[15];
    my $anlam = $a->[13];

    if (defined $exc{$word}) {	# skip exceptions listed at the end
	return;
    }
    if ($word =~ / /) {	# skip multiwords
	return;
    }
    if ($word =~ /m[ae]$/ and $anlam =~ /m[ae]k (işi|durumu)/) { # skip stems with -me suffix
	return if $birlekel eq '\N'; # keep ödeme, açıklama etc.
    }
    if ($word =~ /[ln]m[ae]k$/ and $anlam =~ /m[ae]k? (işi|durumu)/) { # skip the passive stems
	return;
    }
    if ($word =~ s/!$//) {	# remove final bang
	$wpos = 'Interj' if $wpos eq 'Noun';
    }
    $word =~ s/m[ae]k$// if $wpos eq 'Verb'; # get rid of mak/mek
    

    $wpos .= '+Prop' if ($wpos eq 'Noun' and $m->[11] == 1); # ozel
    $wpos .= '^PL'   if ($wpos eq 'Noun' and $m->[10] == 1); # cogul

    my $ek = $m->[9];		# onek
    $ek =~ s/[- ]//g;
    for my $ek1 (split(/,/, $ek)) {
	my $flag = onek($word, $ek1);
	my $str = "$word$flag\t+$wpos;\n";
	print $str unless $seen{$str}++;
    }
}

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
	
	if ($ek =~ /^([^aeıioöuüâîû])\1/) {
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
	    $ek =~ /^[pçtk]\'[ıiuü]$/ or
	    ($lastvowel =~ /^[aâıouû]$/ ?
	     $ek =~ /^$lastchar[ıu]$/ :
	     $ek =~ /^$lastchar[iü]$/)) {
	    # do nothing
	} else {
	    warn "Warning: $word-$ek not a recognized suffix (lastchar=$lastchar,lastvowel=$lastvowel,lastconspair=$lastconspair,lcp2=$lastconspair2,flag=$flag).\n";
	}
    }
    
    return $flag;
}


__DATA__
ait	+Postp+PCDat;
ak	+Adj;
ak	+Noun;
ak^AR	+Verb^C2;
akşam	+Noun^KI;
ama	+Adj;
ama	+Conj;
ama	+Noun;
amma	+Adverb;
amma	+Conj;
ancak	+Adverb;
ancak	+Conj;
art^AR	+Verb^C1;
art^CV	+Adj;
art^CV	+Noun;
aş	+Noun;
aşağı	+Adj;
aşağı	+Noun;
aşağı	+Postp+PCAbl;
aş^AR	+Verb^C1;
aşkın	+Adj;
aşkın	+Postp+PCAcc;
atfen	+Postp+PCDat;
az	+Adj;
az	+Adverb;
az	+Postp+PCAbl;
az^AR	+Verb;
başka	+Adj;
başka	+Postp+PCAbl;
bat	+Noun;
bat^AR	+Verb^C1;
bazı	+Det;
bazı	+Pron+Quant;
ben	+Noun;
ben	+Pron+Pers+A1sg;
beraber	+Adj;
beraber	+Adverb;
beraber	+Postp+PCIns;
beri	+Adverb;
beri	+Noun;
beri	+Postp+PCAbl;
binaen	+Postp+PCDat;
bir	+Adj;
bir	+Adverb;
bir	+Det;
birbiri	+Pron+Quant;
birçoğu	+Pron+Quant;
birçok	+Det;
biri	+Pron+Quant;
birkaç	+Det;
birkaçı	+Pron+Quant;
birlikte	+Adverb;
birlikte	+Postp+PCIns;
birtakım	+Adj;
birtakım	+Det;
birtakım	+Pron+Quant;
bit	+Noun;
bit^AR	+Verb^C1;
biz	+Noun;
biz	+Pron+Pers+A1pl;
boya	+Noun;
boya	+Verb^RF;
boyunca	+Postp+PCNom;
bu	+Det;
bu	+Pron+Demons;
bugün	+Adverb;
bugün	+Noun^KI;
çarp^AR	+Verb^C2;
çık^AR	+Verb^C3;
çoğu	+Det;
çoğu	+Pron+Quant;
çok	+Adj;
çok	+Adverb;
çok	+Det;
çok	+Postp+PCAbl;
çök^AR	+Verb^C4;
çünki	+Conj;
çünkü	+Conj;
da	+Conj;
dahi	+Adj;
dahi	+Conj;
dahi	+Noun;
dair	+Postp+PCDat;
de	+Conj;
de^AR	+Verb;
değil	+Conj;
değil	+Noun;	!! This should have its own class
değin	+Postp+PCDat;
değin	+Verb;
dek	+Noun;
dek	+Postp+PCDat;
dışarı	+Adj;
dışarı	+Noun;
dışarı	+Postp+PCAbl;
diye	+Postp+PCNom;
doğ^AR	+Verb^C1;
doğru	+Adj;
doğru	+Noun;
doğru	+Postp+PCDat;
dolayı	+Noun;
dolayı	+Postp+PCAbl;
doy^AR	+Verb^C1;
duy	+Noun;
duy^AR	+Verb^C1;
dün	+Adverb;
dün	+Noun^KI;
düş	+Noun;
düş^AR	+Verb^C1;
eğer	+Conj;
eğer	+Noun;
em	+Noun;
em^AR	+Verb^CX;		!! causative form is emzir
eşya	+Noun;	!! has ^PL in TDK
evvel	+Noun;
evvel	+Postp+PCAbl;
fakat	+Conj;
fazla	+Adj;
fazla	+Adverb;
fazla	+Postp+PCAbl;
gayrı	+Adj;
gayrı	+Adverb;
gayrı	+Postp+PCAbl;
gece	+Adverb;
gece	+Noun^KI;
geç	+Adj;
geç	+Adverb;
geç^AR	+Verb^C1;
geçe	+Postp+PCNom;
gel	+Verb^CX;		!! causative form is getir
gerek	+Conj;
gerek	+Verb;
gerek^CV	+Noun;
gerekse	+Conj;
gerekse	+Verb;
gibi	+Postp+PCGen;
gibi	+Postp+PCNom;
gir^AR	+Verb^CX;		!! causative = sok
git^CV^AR	+Verb^CX;	!! causative = götür
giy^AR	+Verb^RF;
gizle	+Verb^RF;
göre	+Postp+PCDat;
gündüz	+Adverb;
gündüz	+Noun^KI;
ha	+Conj;
ha	+Interj;
halbuki	+Conj;
hangi	+Adj;
hangi	+Pron+Ques;
hatta	+Adverb;
hatta	+Conj;
hazırla	+Verb^RF;
hem	+Adverb;
hem	+Conj;
hep	+Adverb;
hep	+Pron+Quant;
hepsi	+Pron+Quant;
her	+Det;
herbiri	+Pron+Quant;
herkes	+Pron+Quant;
hiçbir	+Det;
hiçbiri	+Pron+Quant;
hitaben	+Postp+PCDat;
hürmeten	+Noun;
hürmeten	+Postp+PCDat;
iç	+Adj;
iç	+Noun;
iç^AR	+Verb^C1;
için	+Postp+PCGen;
için	+Postp+PCNom;
ila	+Conj;
ilaveten	+Postp+PCDat;
ile	+Conj;
ile	+Postp+PCNom;
ilişkin	+Postp+PCDat;
ise	+Postp+PCNom;	!! This should have its own class
ister	+Conj;
ister	+Noun;
istinaden	+Postp+PCDat;
iştiraken	+Postp+PCDat;
ithafen	+Postp+PCDat;
itibaren	+Postp+PCAbl;
izafeten	+Postp+PCDat;
kaç	+Adj;
kaç	+Adj;
kaç	+Pron+Ques;
kaç	+Pron+Ques;
kaç^AR	+Verb^C1;
kaç^AR	+Verb^C1;
kadar	+Noun;
kadar	+Postp+PCDat;
kadar	+Postp+PCGen;
kadar	+Postp+PCNom;
kah	+Conj;
kah	+Noun;
kala	+Noun;
kala	+Postp+PCNom;
kalk^AR	+Verb^CX;		!! causative = kaldır
karşı	+Adj;
karşı	+Adverb;
karşı	+Noun;
karşı	+Postp+PCDat;
karşın	+Postp+PCDat;
kaşı	+Verb^RF;
kendi	+Pron+Reflex;
kıyasen	+Postp+PCDat;
ki	+Conj;
kim	+Pron+Ques;
kimi	+Det;
kimi	+Pron+Quant;
kimse	+Noun;
kimse	+Pron+Quant;
kop^AR	+Verb^C3;
kork^AR	+Verb^C2;
kurula	+Verb^RF;
lakin	+Conj;
mahsuben	+Postp+PCDat;
mamafih	+Conj;
meğer	+Adverb;
meğer	+Conj;
meğerse	+Adverb;
meğerse	+Conj;
mı	+Ques;
mi	+Noun;
mi	+Ques;
mu	+Ques;
mukabil	+Adj;
mukabil	+Postp+PCDat;
mü	+Ques;
müteakiben	+Postp+PCAcc;
nazaran	+Postp+PCDat;
ne	+Adverb;
ne	+Conj;
nere	+Pron+Ques;
ne^Y	+Adj;
ne^Y	+Pron+Ques;
o	+Det;
o	+Noun;
o	+Pron+Demons;
o	+Pron+Pers+A3sg;
onlar	+Pron+Pers+A3pl;
oysa	+Adverb;
oysa	+Conj;
öbür	+Adj;
öbür	+Pron+Quant;
öğren	+Verb^CX;		!! causative = öğret
önce	+Adverb;
önce	+Noun;
önce	+Postp+PCAbl;
örneğin	+Conj;
ört^AR	+Verb^RF;
öte	+Noun;
öte	+Postp+PCAbl;
ötürü	+Postp+PCAbl;
piş^AR	+Verb^C1;
rağmen	+Postp+PCDat;
sabah	+Adverb;
sabah	+Noun^KI;
sar^AR	+Verb^RF;
sark^AR	+Verb^C2;
sen	+Pron+Pers+A2sg;
siz	+Pron+Pers+A2pl;
sonra	+Adverb;
sonra	+Adverb;
sonra	+Noun^KI;
sonra	+Noun^KI;
sonra	+Postp+PCAbl;
sonra	+Postp+PCAbl;
süsle	+Verb^RF;
şayet	+Conj;
şimdi	+Adverb;
şimdi	+Noun^KI;
şiş	+Adj;
şiş	+Noun;
şiş^AR	+Verb^C1;
şu	+Det;
şu	+Pron+Demons;
takdirde	+Postp+PCNom;
takiben	+Postp+PCAcc;
tara	+Verb^RF;
taş	+Adj;
taş	+Noun;
taş^AR	+Verb^C1;
temizle	+Verb^RF;
tüm	+Det;
tümü	+Pron+Quant;
uç^AR	+Verb^C1;
uç^CV	+Adj;
uç^CV	+Noun;
uyarınca	+Postp+PCNom;
ürk^AR	+Verb^C2;
üzere	+Postp+PCNom;
vazgeç^AR	+Verb^C1;
ve	+Conj;
veya	+Conj;
veyahut	+Conj;
ya	+Conj;
ya	+Interj;
yahut	+Conj;
yana	+Postp+PCAbl;
yanısıra	+Postp+PCGen;
yani	+Conj;
yarın	+Adverb;
yarın	+Noun^KI;
yat	+Noun;
yat^AR	+Verb^C1;
yıka	+Verb^RF;
yit^AR	+Verb^C1;
yönelik	+Postp+PCDat;
yukarı	+Adj;
yukarı	+Noun;
yukarı	+Postp+PCAbl;
yuvarla	+Verb^RF;
zira	+Conj;
