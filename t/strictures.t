BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }

use Test::More qw(no_plan);

our ($hints, $warning_bits);

sub capture_hints {
  # ignore lexicalized hints
  $hints = $^H & ~ 0x20000;
  $warning_bits = defined ${^WARNING_BITS} ? (unpack "H*", ${^WARNING_BITS}) : undef;
}

sub test_hints {
  my $name = shift;
  my $want_hints = $hints;
  my $want_bits = $warning_bits;
  capture_hints;
  is($hints,        $want_hints, "Hints ok for $name");
  is($warning_bits, $want_bits,  "Warnings ok for $name");
}

{
  use strict;
  use warnings FATAL => 'all';
  BEGIN { capture_hints }
}

{
  use strictures 1;
  BEGIN { test_hints "version 1" }
}

my $v;
eval { $v = strictures->VERSION; 1 } or diag $@;
is $v, $strictures::VERSION, '->VERSION returns version correctly';

ok(!eval q{use strictures 2; 1; }, "Can't use strictures 2 (this is version 1)");
