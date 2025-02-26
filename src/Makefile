#$Id: Makefile,v 1.17 2010/08/26 03:50:10 dyuret Exp $

XFST_SRC = comp.xfst yanl.xfst mlex.xfst phon.xfst norm.xfst
LEXC_SRC = main.lext multichar.lext nderiv.lext vderiv.lext vflect.lext nflect.lext ulkeler.lext include.pl
DICT_SRC = maddeler.tab anlams.tab ykkisa.tab tdk2dict.pl

all: model.foma model.hfst model.fst

# Packaging
yuretmor-1.17.tgz: ${XFST_SRC} ${LEXC_SRC} ${DICT_SRC} Makefile README
	tar -cvzHf $@ $^

# Building dictionary
dict.lext: ${DICT_SRC}
	tdk2dict.pl > dict.lext 2> tdk2dict.err

# Building morphotactics
main.lexc: dict.lext ${LEXC_SRC}
	include.pl main.lext > main.lexc

# Compiling with foma:
model.foma: comp.foma main.foma yanl.foma mlex.foma phon.foma norm.foma
	foma \
	-e "load comp.foma" \
	-e "load main.foma" -e rotate -e compose \
	-e "load yanl.foma" -e rotate -e compose \
	-e "load mlex.foma" -e rotate -e compose \
	-e "load phon.foma" -e rotate -e compose \
	-e "load norm.foma" -e rotate -e compose \
	-e "ss > $@" -e quit

comp.foma: comp.xfst
main.foma: main.lexc
yanl.foma: yanl.xfst
mlex.foma: mlex.xfst
phon.foma: phon.xfst
norm.foma: norm.xfst

%.foma: %.xfst
	foma -e "source $^" -e "ss > $@" -e quit

%.foma: %.lexc
	foma -e "read lexc $^" -e "ss > $@" -e quit


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
main.fst: main.lexc
yanl.fst: yanl.xfst
mlex.fst: mlex.xfst
phon.fst: phon.xfst
norm.fst: norm.xfst

%.fst: %.xfst
	xfst -e "source $^" -e "save $@" -stop

%.fst: %.lexc
	xfst -e "read lexc $^" -e "save $@" -stop


# Compiling for hfst:
%.att: %.foma
	foma -e "load $^" -e "watt > $@" -e quit

%.hfst: %.att
	hfst-txt2fst -e'@0@' -i $^ -o $@.s
	hfst-invert -i $@.s -o $@.r
	hfst-lookup-optimize -i $@.r -o $@


# Regression testing
dtest: dict.lext
	make model.fst
	cd ../disamb; touch model.fst; make dtest

etest0: dict.lext
	make model.fst
	cd ../stemmer; make etest0

ktest0: dict.lext
	make model.fst
	cd ../stemmer; make ktest0

etest: dict.lext
	make model.hfst
	cd ../stemmer; make etest

ktest: dict.lext
	make model.hfst
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
	-rm dict.lext main.lexc tdk2dict.err
	-rm comp.fst main.fst model.fst mlex.fst norm.fst phon.fst yanl.fst 
	-rm *.att *.foma *.hfst *.hfst.s *.hfst.r
