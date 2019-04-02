# Installing from Source

The commands:

```
mkdir B
cd B
cmake ..
make
make install
```

Should compile and install this program. Add a
-DCMAKE_INSTALL_PREFIX=[prefix] option
to cmake to install it under a different location in the tree.

# Compiling an RPM.

Type "rpmbuild -tb" followed by the tar.xz archive filename to create an
RPM of the program. You can then install it by using "rpm -Uvh".

# Requirements:

* A UNIX-compatible System.

* Website Meta Language - https://github.com/thewml/website-meta-language

* Perl 5

* The Following Perl 5 CPAN Modules:
    - Config::IniFiles
    - MIME::Types
    - HTML::Links::Localize
    - CGI
    - Data::Dumper
    - File::Find
    - Getopt::Long
    - Pod::Usage

All of them can be installed by installing [Task::QuadPres](https://metacpan.org/pod/Task::QuadPres) using the CPAN interface.
