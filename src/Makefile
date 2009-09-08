all: deriv.extra nflect.extra nzero.extra vflect.extra vzero.extra

deriv.extra: deriv.test deriv.lexc nzero.lexc nflect.lexc vflect.lexc vzero.lexc deriv.regex

nflect.extra: nflect.test nflect.lexc nzero.lexc vzero.lexc deriv.regex

nzero.extra: nzero.test nzero.lexc

vflect.extra: vflect.test vflect.lexc

vzero.extra: vzero.test vzero.lexc

%.extra: %.test %.lexc
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
