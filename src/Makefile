all: model.foma

# Compiling with foma and hfst:

model.hfst: model.att
	hfst-txt2fst -e'@0@' -i $^ -o $@.s
	hfst-invert -i $@.s -o $@.r
	hfst-lookup-optimize -i $@.r -o $@

model.att: comp.att main.att yanl.att mlex.att phon.att norm.att
	foma \
	-e "ratt comp.att" \
	-e "ratt main.att" -e rotate -e compose \
	-e "ratt yanl.att" -e rotate -e compose \
	-e "ratt mlex.att" -e rotate -e compose \
	-e "ratt phon.att" -e rotate -e compose \
	-e "ratt norm.att" -e rotate -e compose \
	-e "watt > $@" -e quit

comp.att: comp.xfst
main.att: main.lexc
yanl.att: yanl.xfst
mlex.att: mlex.xfst
phon.att: phon.xfst
norm.att: norm.xfst

%.att: %.lexc
	foma -e "read lexc $^" -e "watt > $@" -e quit

%.att: %.xfst
	foma -e "source $^" -e "watt > $@" -e quit



# Compiling with Xerox tools:

model.fst: comp.fst main.fst yanl.fst mlex.fst phon.fst norm.fst
	xfst \
	-e "load comp.fst" \
	-e "load main.fst" -e rotate -e compose \
	-e "load yanl.fst" -e rotate -e compose \
	-e "load mlex.fst" -e rotate -e compose \
	-e "load phon.fst" -e rotate -e compose \
	-e "load norm.fst" -e rotate -e compose \
	-e "save $@" -stop

comp.fst: comp.xfst
mlex.fst: mlex.xfst
phon.fst: phon.xfst
yanl.fst: yanl.xfst
norm.fst: norm.xfst

main.fst: main.lexc
	xfst -e "read lexc $^" -e "upper net" -e "save $@" -stop

main.lexc: main.lext multichar.lext dict.lext nderiv.lext vderiv.lext vflect.lext nflect.lext ulkeler.lext

dict.lext: tdk2dict.pl
	tdk2dict.pl > dict.lext 2> tdk2dict.err

%.fst: %.xfst
	xfst -e "source $^" -e "save $@" -stop

%.fst: %.lexc
	xfst -e "read lexc $^" -e "save $@" -stop

%.lexc: %.lext
	include.pl $< > $@


dtest: dict.lext
	make model.fst
	cd ../disamb; touch model.fst; make dtest

etest: dict.lext
	make model.fst
	cd ../stemmer; make etest

ktest: dict.lext
	make model.fst
	cd ../stemmer; make ktest

vflect.test.lexc: include.pl vflect.test.lext multichar.lext vflect.lext

phon.extra: phon.test phon.xfst mlex.xfst deriv.lexc nflect.xfst vflect.lext vzero.lexc deriv.regex

deriv.extra: deriv.test deriv.lexc nflect.xfst vflect.lext vzero.lexc deriv.regex

nflect.extra: nflect.test nflect.xfst vzero.lexc deriv.regex

vflect.extra: vflect.test vflect.lext

vzero.extra: vzero.test vzero.lexc

%.extra: %.test
	$<
	wc -l *.extra
	wc -l *.missing

Milliyet.rcount: Milliyet.clean.bz2
	bunzip2 -c $^ | \
	iconv -f latin5 -t utf8 | \
	lookup tfeaturesulx.fst | \
	perl -pe 's/^([^+]+[^\t])\+/$$1\t+/' | \
	rcount > $@

Milliyet.regex: Milliyet.rcount
	cut -f4 $^ | \
	perl -ne 'print if /\S/' | \
	perl -pe 's/[+^][^+^\s]+/"$$&" /g; s/$$/|/;' | \
	rcount | cut -f2 > $@
	echo '"END";' >> $@

Milliyet.fst: Milliyet.regex Milliyet.xfst
	Milliyet.xfst

Milliyet.dict: Milliyet.rcount
	cut -f3,4 $< | \
	grep . | grep -v +? | grep -v ^+ | grep -v +Prop | \
	perl -pe 's/\^DB.*//;s/(\t\+(Noun|Verb|Adj|Adverb|Ques|Pron\+[^+]+)).*/$$1/;' | \
	perl -C -pe 's/\S+/lc($$&)/e' | \
	LANG=tr_TR.UTF-8 sort -k1,1 -k2,2 -u > $@

clean:
	-rm *.missing *.extra
	-rm model.fst main.lexc
