use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'strictures',
  VERSION_FROM => 'lib/strictures.pm',
  ABSTRACT_FROM => 'lib/strictures.pm',
  AUTHOR => do { local (@ARGV) = 'AUTHOR'; <> },
  LICENSE => 'perl',
);
