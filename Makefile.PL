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
      repository => 'git://git.shadowcat.co.uk/p5sagit/strictures.git',
      homepage => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/strictures.git',
    },

    recommends => {
        indirect => 0,
        multidimensional => 0,
        'bareword::filehandles' => 0,
    },
  },
);
