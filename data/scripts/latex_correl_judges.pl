use strict;
use Data::Dumper;

my $STATS = {};
open(STATS, "<", "judges/stats.txt");
while (<STATS>) {
  chomp;
  my ($j, $c) = split(/\t/, $_);
  next if($j eq "Total");
  $STATS->{$j} = $c; 
}
close(STATS);

my $C = {};
foreach my $i (1 .. 8) {
  foreach my $j (1 .. 8) {
    if($i < $j) {
      chomp($C->{$i}->{$j} = `perl scripts/spearman.pl judges/EW.ranking.$i.txt judges/EW.ranking.$j.txt`)
    }
    elsif($i == $j) {
      $C->{$i}->{$j} = "--";
    }
    else {
      chomp($C->{$i}->{$j} = `perl scripts/pearson.pl judges/EW.ranking.$i.txt judges/EW.ranking.$j.txt`)
    }
  }
  chomp($C->{$i}->{F} = `perl scripts/spearman.pl judges/EW.ranking.no$i.txt judges/EW.ranking.$i.txt`);
  chomp($C->{F}->{$i} = `perl scripts/pearson.pl judges/EW.ranking.no$i.txt judges/EW.ranking.$i.txt`);
}

print STDERR Dumper($C);

my $avgR   = sprintf("%.2f", avg($STATS, map { $C->{F}->{$_} } sort keys %{$C->{F}}));
my $avgRho = sprintf("%.2f", avg($STATS, grep { defined } map { $C->{$_}->{F} } grep { exists($C->{$_}) } sort keys %{$C}));

$avgR =~ s/^0//g;
$avgRho =~ s/^0//g;

print <<'END';
\setlength{\tabcolsep}{3.2pt}
\begin{tabular}{c|cccccccc|cc}
END

print join(" & ", map { sprintf("% 3s", $_) } " ", 1 .. 8 , "\$\\rho\$", "\$\\bar{\\rho}\$"), " \\\\ \\hline \n";
foreach my $i (1 .. 8 , "F") {
    my @l;
    if($i eq "F") {
      @l = ("  \$r\$");
    }
    else {
      @l = ("  $i");
    }
    foreach my $j (1 .. 8 , "F") {
        push(@l, $i ne $j ? sprintf("%.2f", $C->{$i}->{$j}) : sprintf("% 3s","--"));
    }
    print "\\hline\n" if($i eq "F");
    print join(" & ", map { s/0\././g; $_ } @l);
    if($i eq 'F' or $i > 1) {
      print ' & \\\\', "\n";
    }
    else {
      print ' & \multirow{8}{*}{', $avgRho ,'} \\\\', "\n";  
    }
}
print '$\bar{r}$ & \multicolumn{8}{c|}{', $avgR   ,'}', ' & \\\\', "\n";

print '\end{tabular}' , "\n";

sub sum {
  my @v = @_;
  my $sum = 0;
  $sum += $_ foreach(@v);
  return $sum;
}

sub avg {
  my $w = shift;
  my @v = @_;
  print STDERR Dumper(\@v, $w);
  my $c = 1;
  return sum( map { $_ * $w->{$c++} } @v) / sum(values %$w);
}
