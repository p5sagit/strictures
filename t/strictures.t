BEGIN { delete $ENV{PERL_STRICTURES_EXTRA} }

use Test::More qw(no_plan);

our (@us, @expect);

sub capture_stuff { [ $^H, ${^WARNING_BITS} ] }

sub capture_us { push @us, capture_stuff }
sub capture_expect { push @expect, capture_stuff }

{
  BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }
  use strictures 1;
  BEGIN { capture_us }
  BEGIN { delete $ENV{PERL_STRICTURES_EXTRA} }
}

{
  use strict;
  use warnings FATAL => 'all';
  BEGIN { capture_expect }
}

# I'm assuming here we'll have more cases later. maybe not. eh.

foreach my $idx (0 .. $#us) {
  # ignore lexicalized hints
  $us[$idx][0] &= ~ 0x20000;
  is($us[$idx][0], $expect[$idx][0], 'Hints ok for case '.($idx+1));
  is($us[$idx][1], $expect[$idx][1], 'Warnings ok for case '.($idx+1));
}

my $v;
eval { $v = strictures->VERSION; 1 } or diag $@;
is $v, $strictures::VERSION, '->VERSION returns version correctly';

ok(!eval q{use strictures 2; 1; }, "Can't use strictures 2 (this is version 1)");
