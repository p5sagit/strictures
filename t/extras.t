BEGIN { delete $ENV{PERL_STRICTURES_EXTRA} }
use strict;
use warnings;
use Test::More $] >= 5.008_004 ? qw(no_plan)
  : (skip_all => 'Extra tests disabled on perls <= 5.008003');

use File::Temp;

my $tempdir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
chdir $tempdir;

my %extras;
BEGIN {
  %extras = map { $_ => 1 } qw(
    indirect.pm
    multidimensional.pm
    bareword/filehandles.pm
  );
  $INC{$_} = __FILE__
    for keys %extras;
}

use strictures ();

my $indirect = 0;
sub indirect::unimport {
  $indirect++;
};

{
  local $strictures::Smells_Like_VCS = undef;
  eval qq{
#line 1 "t/nogit.t"
use strictures;
1;
} or die "$@";
  ok defined $strictures::Smells_Like_VCS, 'VCS dir has been checked';
  ok !$strictures::Smells_Like_VCS,        'VCS dir not detected with no .git';
}

mkdir '.git';

{
  local $strictures::Smells_Like_VCS = undef;
  eval qq{
#line 1 "t/withgit.t"
use strictures;
1;
} or die "$@";
  ok defined $strictures::Smells_Like_VCS, 'VCS dir has been checked';
  ok $strictures::Smells_Like_VCS,         'VCS dir detected with .git';
}

$strictures::Smells_Like_VCS = 1;

for my $check (
  ["file.pl"            => 0],
  ["test.pl"            => 0],
  ["library.pm"         => 0],
  ["t/test.t"           => 1],
  ["xt/test.t"          => 1],
  ["t/one.faket"        => 1],
  ["lib/module.pm"      => 1],
  ["other/one.pl"       => 0],
  ["other/t/test.t"     => 0],
  ["blib/module.pm"     => 1],
) {
  my ($file, $want) = @$check;
  $indirect = 0;
  eval qq{
#line 1 "$file"
use strictures;
1;
  } or die "$@";
  my $not = $want ? '' : ' not';
  is $indirect, $want,
    "file named $file does$not get extras";
}

{
  local $ENV{PERL_STRICTURES_EXTRA} = 1;
  local %strictures::extra_load_states = ();
  local @INC = (sub {
    die "Can't locate $_[1] in \@INC (...).\n"
      if $extras{$_[1]};
  }, @INC);
  local %INC = %INC;
  delete $INC{$_}
    for keys %extras;

  {
    open my $fh, '>', \(my $str = '');
    {
      local *STDERR = $fh;
      eval qq{
#line 1 "t/load_fail.t"
use strictures;
1;
      } or die "$@";
    }

    strictures->import;
    like(
      $str,
      qr/Missing were:\n\n  indirect multidimensional bareword::filehandles/,
      "failure to load all three extra deps is reported"
    );
  }

  {
    open my $fh, '>', \(my $str = '');
    {
      local *STDERR = $fh;
      eval qq{
#line 1 "t/load_fail.t"
use strictures;
1;
      } or die "$@";
    }

    is $str, '', "extra dep load failure is not reported a second time";
  }
}
