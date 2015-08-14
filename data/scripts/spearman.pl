use strict;
use Data::Dumper;

if(@ARGV < 2) {
    die;
}

my $RANK = $ARGV[0];
my $SCORES = $ARGV[1];
open(R, $RANK) or die;
open(S, $SCORES) or die;

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

print cor({s2r(%R)}, {s2r(%S)}), "\n";

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
