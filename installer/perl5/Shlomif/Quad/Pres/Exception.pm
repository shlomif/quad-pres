package Shlomif::Quad::Pres::Exception;

use vars qw(@ISA);

use Error;

@ISA=qw(Error);

package Shlomif::Quad::Pres::Exception::RenderFile;

use vars qw(@ISA);

@ISA=qw(Shlomif::Quad::Pres::Exception);

1;


