all: check

check: stop-error perl test-html-correctness test-lang-settings 

test-lang-settings: 
	bash test-lang-settings.bash

stop-error:
	cd stop-on-error && bash test1.bash

perl: perl-getopt

perl-getopt:
	perl perl/Getopt.pl

test-html-correctness:
	cd html-correctness && bash test1.bash
