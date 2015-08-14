use strict;
use Data::Dumper;
use XML::Twig;
use Getopt::Long;

$| = 1;

my $USER;
my $EXCLUDE;
my $P = 0.05;
my $L = 0;
my $T = 0;

GetOptions(
  "u|user=s" => \$USER,
  "x|exclude=s" => \$EXCLUDE,
  "p=f" => \$P,
  "l|latex" => \$L,
  "t|ties" => \$T,
);

my $t = XML::Twig->new( 
    twig_roots   => {
        'ranking-item' => \&item,
    },
);

my $WIN = {};
my $COL = {};
my $ANN = {};

my @PR;

sub item {
    my($t, $p)= @_;
    my $user = $p->{att}->{user};
    my $duration = $p->{att}->{duration};
    my $id = $p->{att}->{id};
    my $srcid = $p->{att}->{'src-id'};
    
    return if $user eq "admin";
    return if $user eq $EXCLUDE;
    return if $USER and $user ne $USER;
    my @trans= $p->children('translation');
    
    my @rnks;
    foreach my $t (@trans) {
        my $sys = $t->{att}->{system};
        my $rnk = $t->{att}->{rank};
        
        my @sys = split(/\s/, $sys);
        push(@{$rnks[$rnk]}, @sys);
        
    }
    @rnks = grep { defined } @rnks;
    
    my @pp;
    for my $i (0 .. $#rnks) {
        my @a1 = sort @{$rnks[$i]};
        for my $x (0 .. $#a1) {
            for my $y ($x + 1 .. $#a1) {
                push(@pp, "$a1[$x],$a1[$y],=");
            }
        }
        
        for my $j ($i + 1 .. $#rnks) {
            my @a2 = @{$rnks[$j]};
            for my $x (0 .. $#a1) {
                for my $y (0 .. $#a2) {
                    if ($a1[$x] lt $a2[$y]) {
                        push(@pp, "$a1[$x],$a2[$y],<");
                    }
                    else {
                        push(@pp, "$a2[$y],$a1[$x],>");
                    }
                }
            }        
        }
    }
    
    push(@PR, @pp);
    
    $COL->{$srcid}->{$id}->{$user} = [sort @pp];
    $ANN->{$user} = 1;
}


$t->parse(\*STDIN);

print STDERR "Judgements: ", scalar @PR, "\n";
print STDERR "Ties: ", (scalar grep { /=/ } @PR), "\n";


my $RANKS = {};
foreach(1 .. 1000) {
    print STDERR "." if($_ % 10 == 0);
    print STDERR "[$_]" if($_ % 100 == 0); 
 
    my @sample;
    my $N = $#PR;
    for(0 .. $N) {
        push(@sample, $PR[rand() * @PR]);
    }
    my @rank = rank(@sample);
    foreach my $i (0 .. $#rank) {
        push(@{$RANKS->{$rank[$i]->[0]}}, $i);
    }
}
print STDERR "\n";

my $SYS = {};
foreach my $sys (keys %$RANKS) {
    my @chopped = sort { $a <=> $b } @{$RANKS->{$sys}};
    my $n = scalar @chopped;
    @chopped = @chopped[ $n * $P * 0.5 .. $n - $n * $P * 0.5 ];
    my $start = $chopped[0] + 1;
    my $end   = $chopped[-1] + 1;
    $SYS->{$sys} = [$start, $end];
}

my @rank = rank(@PR);

my $lastend = 0;
my $no = 0;
if ($L) {
    print "\\begin{tabular}{llcl}\n";
    print "\\toprule\n";
    print "\\# & score & range & system \\\\\n";
}

foreach(@rank) {
    my ($start, $end) = @{$SYS->{$_->[0]}};
    my $range = "$start, $end";
    #if ($start == $end) {
    #    $range = $start;
    #}
    if($lastend < $start) {
        if ($L) {
            print "\\midrule\n";
        }
        else {
            if($lastend > 0) {
              print "++++++++++\n"; 
            }
        }
        $no++;
        if($L) {
          print "$no  ";
        }
    }
    if ($L) {
        printf(" & %.4f & %s & %s \\\\\n", $_->[1], $range, $_->[0]);
    }
    else {
        print "$_->[0] $_->[1] ($range)\n";
    }
    $lastend = $end;
}
if ($L) {
    print "\\bottomrule\n";
    print "\\end{tabular}\n"
}

sub rank {
    my @pr = @_;
    $WIN = {};
    foreach(@pr) {
        my ($s1, $s2, $j) = split(/,/, $_);
        if($j eq "<") {
            $WIN->{$s1}->{$s2}++;
        }
        if($j eq ">") {
            $WIN->{$s2}->{$s1}++;
        }
        if ($T) {
            if($j eq "=") {
                $WIN->{$s1}->{$s2} += 1;
            }
            if($j eq "=") {
                $WIN->{$s2}->{$s1} += 1;
            }
        }
    }
    
    my @rank;
    foreach my $s (keys %$WIN) {
        push(@rank, [$s, sprintf("%.4f", ew($WIN->{$s}, $s, $WIN))]);
    }
    return sort { $b->[1] <=> $a->[1] } @rank;
}

sub ew {
    my $Sj = shift;
    my $si = shift;
    my $WIN = shift;
    
    my $N = scalar keys %$Sj;
    
    my $sum = 0;
    foreach my $sj (keys %$Sj) {
        $sum += $WIN->{$si}->{$sj} / ($WIN->{$si}->{$sj} + $WIN->{$sj}->{$si});
    }
    
    return 1/$N * $sum;
}
