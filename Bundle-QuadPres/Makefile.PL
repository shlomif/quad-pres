use ExtUtils::MakeMaker;
WriteMakefile(
              NAME	   => 'Bundle::QuadPres',
              VERSION_FROM => 'QuadPres.pm',
              'dist'       => {
                               COMPRESS => 'gzip -9f',
                               SUFFIX   => '.gz',
                               DIST_DEFAULT => 'all tardist',
                              },
             );
