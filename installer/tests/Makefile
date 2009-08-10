all:

BASH_TESTS = template-toolkit bolded-nav-links update-images

BASH_TESTS_TARGETS = $(addprefix test-,$(BASH_TESTS))

$(BASH_TESTS_TARGETS) :: test-% :
	cd $(patsubst test-%,%,$@) && bash test1.bash

bash-tests: $(BASH_TESTS_TARGETS)

perl-tests: perl-tests-t

check: perl-tests bash-tests 

TEST_VERBOSE = 0
TEST_FILES = t/*.t

perl-tests-t:
	cd "perl" && PERL_DL_NONLAZY=1 perl "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE))" $(TEST_FILES)
