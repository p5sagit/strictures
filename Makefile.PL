use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %extra_prereqs = (
  indirect => 0,
  multidimensional => 0,
  'bareword::filehandles' => 0,
);

use Text::ParseWords;
sub parse_args {
  # copied from EUMM
  ExtUtils::MakeMaker::parse_args(
    my $tmp = {},
    Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
    @ARGV,
  );
  return $tmp->{ARGS} || {};
}

my $have_compiler
  = ! parse_args()->{PUREPERL_ONLY}
  &&  eval { require ExtUtils::CBuilder; 1 }
  && ExtUtils::CBuilder->new->have_compiler;

WriteMakefile(
  NAME => 'strictures',
  VERSION_FROM => 'lib/strictures.pm',
  MIN_PERL_VERSION => '5.006',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 1,

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
      configure => {
        requires => {
          'ExtUtils::CBuilder' => 0,
        },
      },
      runtime => {
        ( $] >= 5.008004 && !$have_compiler
          ? ( recommends => \%extra_prereqs ) : () ),
      },
    },
  },

  ($] >= 5.008004 && $have_compiler
    ? ( PREREQ_PM => \%extra_prereqs ) : () ),
);
