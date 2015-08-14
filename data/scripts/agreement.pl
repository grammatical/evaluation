use strict;
use Data::Dumper;
use XML::Twig;

$| = 1;

my $USER = $ARGV[0];

my $t = XML::Twig->new( 
    twig_roots   => {
        'ranking-item' => \&item,
    },
);

my $WIN = {};
my $COL = {};
my $ANN = {};

my @PR;
my @DUR;

my $acount = {};

sub item {
    my($t, $p)= @_;
    my $user = $p->{att}->{user};
    my $duration = $p->{att}->{duration};
    my $id = $p->{att}->{id};
    my $srcid = $p->{att}->{'src-id'};
     
    return if $user eq "admin";
    my @trans= $p->children('translation');
    
    my @rnks;
    foreach my $t (@trans) {
        my $sys = $t->{att}->{system};
        my $rnk = $t->{att}->{rank};
        
        push(@{$rnks[$rnk]}, $sys);
        
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
    
    my $tid = 0;
    while (exists($COL->{$srcid}->{$user}->{$tid})) {
        $tid++;
    }
    
    
    $COL->{$srcid}->{$user}->{$tid} = [sort @pp];
    $ANN->{$user} = 1;
}

$t->parse(\*STDIN);

###############################################################################

foreach my $a (keys %$ANN) {
    #print $a, "\n";
    
    my $IN;
    foreach my $sid (keys %$COL) {
        foreach my $id (keys %{$COL->{$sid}->{$a}}) {
            if (exists($COL->{$sid}->{$a}->{$id})) {
                my @pairs = @{$COL->{$sid}->{$a}->{$id}};
                foreach my $p (@pairs) {
                    my ($s1, $s2, $j) = split(/,/, $p);
                    push(@{$IN->{"$sid,$s1,$s2"}}, $j);
                }                        
            }
        }
    }
    $ANN->{$a} = $IN;
}

my $INTER = 0;
my $INTERD = 0;
my $INTRA = 0;
my $INTRAD = 0;

my $TABLE = {};

my $i = 1;
my %MAP = map { $_ => $i++ } sort keys %$ANN;

foreach my $a (sort keys %$ANN) {
    #printf("$a duration: Mean: %.2f Median: %.2f\n", duration(map { $_->[1] } grep { $_->[0] eq $a } @DUR));
    foreach my $b (sort keys %$ANN) {
        next if $a gt $b;
        #print "Kappa($a,$b) = ";
        my ($K, $L) = agree($ANN->{$a}, $ANN->{$b}, $a eq $b);
        #printf("%.4f (%d)\n", $K, $L);

        $TABLE->{$MAP{$a}}->{$MAP{$b}} = [$K, $L];        
        
        if ($L < 50) {
            next;
        }
        
        if ($a eq $b) {
             $INTRA += $K * $L;
             $INTRAD += $L;
        }
        else {
             $INTER += $K * $L;
             $INTERD += $L;            
        }
    }
}
    
my $INTER_AGREEMENT = sprintf("%.2f", $INTER/$INTERD);
my $INTRA_AGREEMENT = sprintf("%.2f", $INTRA/$INTRAD);

print STDERR Dumper($TABLE);

print <<END;
\\subcaptionbox{Inter-annotator and intra-annotator agreement for all judges\\label{kappa-inter}}{
\\begin{tabular}{ccc}
\\toprule
Agreement &  Value &  Degree  \\\\ \\midrule
Inter-annotator &  $INTER_AGREEMENT & Weak \\\\
Intra-annotator &  $INTRA_AGREEMENT & Moderate \\\\
\\bottomrule
\\end{tabular}}
\\vspace{0.5cm}

\\subcaptionbox{Pairwise inter-annotator and intra-annotator agreement per judge. Stars indicate too few overlapping judgements.\\label{kappa-intra}}{
\\setlength{\\tabcolsep}{4pt}
END

print "\\begin{tabular}{c|", "c"x scalar keys %MAP , "}\n";

print join(" & ", map { sprintf("% 4s", $_) } " ", sort values %MAP), " \\\\ \\hline \n";


foreach my $j1 (sort values %MAP) {
    my @row = ( $j1 );
    foreach my $j2 (sort values %MAP) {
        if ($j1 > $j2) {
            push(@row, "--");
        }
        else {
            if ($TABLE->{$j1}->{$j2}->[1] < 50) {
                push(@row, "*");
            }
            else {
                push(@row, map{ s/0\././; $_ } sprintf("%.2f", $TABLE->{$j1}->{$j2}->[0]));
            }
        }
    }
    print join(" & ", map { sprintf("% 4s", $_) } @row), " \\\\\n";
}

print "\\end{tabular}}\n";


sub agree {
    my ($a, $b, $i) = @_;
    my ($C, $L, $EQ, $LT, $GT, $L2) = (0, 0, 0, 0, 0, 0);
    foreach my $p (keys %$a) {
        if (exists($b->{$p})) {

            my @a = @{$a->{$p}};
            my @b = @{$b->{$p}}; 
            if ($i) {
                next if(@a == 1);
                foreach my $ja (0 .. $#a) {
                    foreach my $jb ($ja + 1 .. $#a) {
                        if ($a[$ja] eq $a[$jb]) {
                            $C++;
                        }
                        $L++;
                    }
                }                             
                $L2 += @a;
                $EQ += grep { $_ eq "=" } @a;
                $LT += grep { $_ eq "<" } @a;
                $GT += grep { $_ eq ">" } @a;
            }
            else {
                foreach my $ja (@a) {
                    foreach my $jb (@b) {
                        if ($ja eq $jb) {
                            $C++;
                        }
                        $L++;
                    }
                }
                    
                $L2 += @a + @b;
                $EQ += grep { $_ eq "=" } (@a, @b);
                $LT += grep { $_ eq "<" } (@a, @b);
                $GT += grep { $_ eq ">" } (@a, @b);
            }
        }
    }
    
    return (0,0) if not $L;
    
    my $PA = $C/$L;
    my $PE = ($LT/$L2)**2 + ($EQ/$L2)**2 + ($GT/$L2)**2;
    my $K = ($PA - $PE) / (1 - $PE);
    
    return ($K, $L);
}

sub duration {
    my @DUR = @_;
    @DUR = sort { $a <=> $b } @DUR;
    @DUR = @DUR[0.05 * @DUR .. 0.95 * @DUR];

    my $avg = 0;
    $avg += $_ foreach(@DUR);
    $avg /= @DUR;

    my $median = $DUR[$#DUR*0.5];

    return ($avg, $median);
}
