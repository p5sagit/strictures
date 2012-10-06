use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'strictures',
  VERSION_FROM => 'lib/strictures.pm',
  MIN_PERL_VERSION => '5.006',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,

    resources => {
      # r/w: p5sagit@git.shadowcat.co.uk:strictures.git
      repository => {
        url => 'git://git.shadowcat.co.uk/p5sagit/strictures.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/strictures.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-strictures@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=strictures',
      },
    },

    prereqs => {
      runtime => {
        recommends => {
          indirect => 0,
          multidimensional => 0,
          'bareword::filehandles' => 0,
        },
      },
    },
  },

  (eval { require ExtUtils::CBuilder; 1 }
      and ExtUtils::CBuilder->new->have_compiler)
      ? (PREREQ_PM => {
            indirect => 0,
            multidimensional => 0,
            'bareword::filehandles' => 0,
      })
      : (),
);
