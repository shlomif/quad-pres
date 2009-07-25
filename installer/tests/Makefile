all:

BASH_TESTS = html-correctness stop-on-error lang-settings body-dir credit gen-hd-html template-toolkit bolded-nav-links update-images

BASH_TESTS_TARGETS = $(addprefix test-,$(BASH_TESTS))

$(BASH_TESTS_TARGETS) :: test-% :
	cd $(patsubst test-%,%,$@) && bash test1.bash

PERL_TESTS = CmdLine-Moose

PERL_TESTS_TARGETS = $(addprefix perl-test-,$(PERL_TESTS))

$(PERL_TESTS_TARGETS) :: perl-test-% :
	perl perl/$(patsubst perl-test-%,%,$@).pl

bash-tests: $(BASH_TESTS_TARGETS)

perl-tests: $(PERL_TESTS_TARGETS) perl-tests-t

check: perl-tests bash-tests 

TEST_VERBOSE = 0
TEST_FILES = t/*.t

perl-tests-t:
	cd "perl" && PERL_DL_NONLAZY=1 perl "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE))" $(TEST_FILES)
