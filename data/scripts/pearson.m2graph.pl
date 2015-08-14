use strict;
use Data::Dumper;

if(@ARGV < 2) {
    die;
}

my $RANK = $ARGV[0];
my $SCORES = $ARGV[1];
open(R, $RANK) or die;
open(S, $SCORES) or die;
my $B;
my %R;

my $RANGE = 1;
if(defined($ARGV[2])) {
    $RANGE = $ARGV[2];
}

while(<R>) {
  chomp;
  next if(/\+\+\+/);
  my ($s, $r) = split(/\s/, $_);
  $R{$s} = $r;
}

my %S;
while(<S>) {
  chomp;
  next if(/\+\+\+/);
  my ($s, $f, $p, $r) = split(/\s/, $_);
  $S{$s} = [$p, $r];
}

sub f {
  my ($p, $r, $b) = @_;
  return 0 if(not $p or not $r);
  return ((1 + $b**2) * $p * $r) / ($b**2 * $p + $r)
}


my $bb = $RANGE * 100;
while($bb > 0) {
  $B = $bb/100;
  my %F;
  for(keys %S) {
    $F{$_} = f(@{$S{$_}}, $B);
  }
  print $B, "\t", cor(\%R, \%F), "\n";
  $bb -= 1;
}

sub cor {
  my ($r, $f) = @_;
  my $Havg = avg($r);
  my $Mavg = avg($f);
  
  my $num = sum(map { ($r->{$_} - $Havg) * ($f->{$_} - $Mavg) } keys %$r);
  my $denom = sqrt(sum(map { ($r->{$_} - $Havg)**2 } keys %$r))
    * sqrt(sum(map { ($f->{$_} - $Mavg)**2 } keys %$f));
    
  return $num/$denom;
}

sub sum {
  my @v = @_;
  my $sum = 0;
  $sum += $_ foreach(@v);
  return $sum;
}

sub avg {
  my $v = shift;
  return sum(values %$v) / scalar values %$v;
}
