all:

BASH_TESTS = html-correctness stop-on-error lang-settings body-dir credit

BASH_TESTS_TARGETS = $(addprefix test-,$(BASH_TESTS))

$(BASH_TESTS_TARGETS) :: test-% :
	cd $(patsubst test-%,%,$@) && bash test1.bash

PERL_TESTS = Getopt

PERL_TESTS_TARGETS = $(addprefix perl-test-,$(PERL_TESTS))

$(PERL_TESTS_TARGETS) :: perl-test-% :
	perl perl/$(patsubst perl-test-%,%,$@).pl

bash-tests: $(BASH_TESTS_TARGETS)

perl-tests: $(PERL_TESTS_TARGETS)

check: perl-tests bash-tests 

