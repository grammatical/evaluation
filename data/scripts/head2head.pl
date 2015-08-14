use strict;
use Data::Dumper;
use XML::Twig;
use Getopt::Long;

use Statistics::R;

$| = 1;

my $USER;
my $P = 0.05;
my $L = 0;
my $T = 0;

GetOptions(
  "u|user=s" => \$USER,
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

my @rank = rank(@PR);
print "\\setlength{\\tabcolsep}{1.2pt}\n";
print '\begin{tabular}{r@{\hspace{4pt}}|@{\hspace{3pt}}cccccccccc|c|cc}', "\n";
foreach my $r1 (map { $_->[0] } @rank) {
    print " & \\rotatebox[origin=l]{90}{$r1}\n";
}
print '\\\\[-4pt] \hline', "\n";
foreach my $r1 (map { $_->[0] } @rank) {
    my @l = ( $r1 );
    foreach my $r2 (map { $_->[0] } @rank) {
        my $f2 = $WIN->{$r1}->{$r2} ? $WIN->{$r1}->{$r2} : 1;
        my $f1 = $WIN->{$r2}->{$r1} ? $WIN->{$r2}->{$r1} : 1;
        my $f = $f1/($f1 + $f2);
        
        my $p = sign($f1, $f2);
        my $sign = "";
        if ($p <= 0.1) {
            $sign = '$\star$'
        }
        if ($p <= 0.05) {
            $sign = '$\dagger$'
        }
        if ($p <= 0.01) {
            $sign = '$\ddagger$'
        }
        
        
        my $w = $f > 0.5 ? 1 : 0;
        if ($r1 eq $r2) {
            push(@l, sprintf("  -- ", $f));    
        }
        else {
            my $s = sprintf("%0.2f ", $f);
            $s =~ s/^0//;
            if ($w) {
                $s = "{\\bf $s}$sign";
            }
            else {
                $s = "$s$sign";
            }
            
            push(@l, $s);
        }
    }
    print "\\hline\n" if($l[0] eq "INPUT");
    print join(" & ", @l);
    print "\\\\ \n";
    print "\\hline\n" if($l[0] eq "INPUT");
}
print "\n\\end{tabular}\n";

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

sub sign {
    my ($t1, $t2) = @_;
    my $total = $t1 + $t2;
    my $prob = $t1 / $total;
    
    my $R = Statistics::R->new() ;
    $R->startR ;
    $R->send("binom.test($t1,$total,0.5)") ;
    my $ret = $R->read();
    $R->stopR() ;
    
    #print $ret, "\n";
    $ret =~ m/p-value .+ (.+)/m;
    return $1;
}