all: check

check: stop-error perl test-lang-settings 

test-lang-settings: 
	bash test-lang-settings.bash

stop-error:
	cd stop-on-error && bash test1.bash

perl: perl-getopt

perl-getopt:
	perl perl/Getopt.pl
	
