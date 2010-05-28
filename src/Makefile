all: phon.extra deriv.extra nflect.extra vflect.extra vzero.extra

model.fst: main.lexc mlex.xfst phon.xfst compat.xfst build.xfst
	xfst -f build.xfst

%.lexc: %.lext
	include.pl $< > $@

vflect.test.lexc: include.pl vflect.test.lext multichar.lexc vflect.lexc

main.lexc: include.pl main.lext multichar.lexc dict.lexc nderiv.lexc vderiv.lexc vflect.lexc nflect.lexc

phon.extra: phon.test phon.xfst mlex.xfst deriv.lexc nflect.xfst vflect.lexc vzero.lexc deriv.regex

deriv.extra: deriv.test deriv.lexc nflect.xfst vflect.lexc vzero.lexc deriv.regex

nflect.extra: nflect.test nflect.xfst vzero.lexc deriv.regex

vflect.extra: vflect.test vflect.lexc

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
