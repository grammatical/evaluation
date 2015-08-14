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


my $bb = $RANGE * 100;
while($bb > 0) {
  $B = $bb/100;
  my %F;
  for(keys %S) {
    $F{$_} = f(@{$S{$_}}, $B);
  }
  print $B, "\t", cor({s2r(%R)}, {s2r(%F)}), "\n";
  $bb -= 1;
}

sub f {
  my ($p, $r, $b) = @_;
  return 0 if(not $p or not $r);
  return ((1 + $b**2) * $p * $r) / ($b**2 * $p + $r)
}

sub s2r {
  my %s = @_;
  my $c = 1;
  my %r = map { $_ => $c++ } sort { $s{$b} <=> $s{$a} } keys %s;
  return %r;
}

sub cor {
  my ($r, $f) = @_;
  my $dsum = 0;
  my $n = keys %$r;
  foreach(keys %$r) {
     $dsum += ($r->{$_} - $f->{$_})**2;
  }
  return 1 - (6 * $dsum) / ($n * ($n**2 - 1))
}
