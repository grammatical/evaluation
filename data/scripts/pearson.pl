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
  my ($s, $r) = split(/\s/, $_);
  $S{$s} = $r;
}

print cor(\%R, \%S), "\n";

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