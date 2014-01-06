use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
BEGIN { if ( $^O eq 'cygwin' ) {
  require ExtUtils::MM_Cygwin;
  require ExtUtils::MM_Win32;
  if ( ! defined(&ExtUtils::MM_Cygwin::maybe_command) ) {
    *ExtUtils::MM_Cygwin::maybe_command = sub {
      my ($self, $file) = @_;
      if ($file =~ m{^/cygdrive/}i and ExtUtils::MM_Win32->can('maybe_command')) {
        ExtUtils::MM_Win32->maybe_command($file);
      } else {
        ExtUtils::MM_Unix->maybe_command($file);
      }
    }
  }
}}


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
  && can_xs();

my $support_configure_requires
  = $ENV{PERL5_CPANM_IS_RUNNING}
  || !$ENV{PERL5_CPAN_IS_RUNNING}
  || ! eval { require CPAN }
  || $CPAN::VERSION > 1.94_55
  || $CPAN::VERSION > 1.91_51 && $CPAN::VERSION < 1.93_51;


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
        ( $] >= 5.008004 && !($have_compiler && $support_configure_requires)
          ? ( recommends => \%extra_prereqs ) : () ),
      },
    },
  },

  ($] >= 5.008004 && $have_compiler && $support_configure_requires
    ? ( PREREQ_PM => \%extra_prereqs ) : () ),
);

# can we locate a (the) C compiler
sub can_cc {
  my @chunks = split(/ /, $Config::Config{cc}) or return;

  # $Config{cc} may contain args; try to find out the program part
  while (@chunks) {
    return can_run("@chunks") || (pop(@chunks), next);
  }

  return;
}

# check if we can run some command
sub can_run {
  my ($cmd) = @_;

  return $cmd if -x $cmd;
  if (my $found_cmd = MM->maybe_command($cmd)) {
    return $found_cmd;
  }

  require File::Spec;
  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $cmd);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

# Can our C compiler environment build XS files
sub can_xs {
  # Do we have the configure_requires checker?
  local $@;
  eval "require ExtUtils::CBuilder; ExtUtils::CBuilder->VERSION(0.27)";
  if ( $@ ) {
    # They don't obey configure_requires, so it is
    # someone old and delicate. Try to avoid hurting
    # them by falling back to an older simpler test.
    return can_cc();
  }

  # Do we have a working C compiler
  my $builder = ExtUtils::CBuilder->new(
    quiet => 1,
  );
  unless ( $builder->have_compiler ) {
    # No working C compiler
    return 0;
  }

  # Write a C file representative of what XS becomes
  require File::Temp;
  my ( $FH, $tmpfile ) = File::Temp::tempfile(
    "compilexs-XXXXX",
    SUFFIX => '.c',
  );
  binmode $FH;
  print $FH <<'END_C';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main(int argc, char **argv) {
    return 0;
}

int boot_sanexs() {
    return 1;
}

END_C
  close $FH;

  # Can the C compiler access the same headers XS does
  my @libs   = ();
  my $object = undef;
  eval {
    local $^W = 0;
    $object = $builder->compile(
      source => $tmpfile,
    );
    @libs = $builder->link(
      objects     => $object,
      module_name => 'sanexs',
    );
  };
  my $result = $@ ? 0 : 1;

  # Clean up all the build files
  foreach ( $tmpfile, $object, @libs ) {
    next unless defined $_;
    1 while unlink;
  }

  return $result;
}
