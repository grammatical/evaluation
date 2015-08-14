use strict;
use Data::Dumper;
use XML::Twig;
use Getopt::Long;

my $RAW = 0;
GetOptions(
    "r|raw" => \$RAW,
);

$| = 1;

my $USER = $ARGV[0];

my $t = XML::Twig->new( 
    twig_roots   => {
        'ranking-item' => \&item,
    },
);

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
    my @rnks2;
    
    $ANN->{$user}->{RANKS}++;
    $ANN->{TOTAL}->{RANKS}++;

    $ANN->{$user}->{UNEXPANDED} += coeff(scalar @trans);
    $ANN->{TOTAL}->{UNEXPANDED} += coeff(scalar @trans);
    
    my $c = 0;
    foreach my $t (@trans) {
        my $sys = $t->{att}->{system};
        my $rnk = $t->{att}->{rank};
        
        my @sys = split(/\s/, $sys);
        push(@{$rnks[$rnk]}, @sys);
        push(@{$rnks2[$rnk]}, $c++);
    }
    @rnks = grep { defined } @rnks;
    @rnks2 = grep { defined } @rnks2;
    $ANN->{$user}->{EXPANDED} += coeff(scalar map { @$_ } @rnks);
    $ANN->{TOTAL}->{EXPANDED} += coeff(scalar map { @$_ } @rnks);

    $ANN->{$user}->{UNEXPANDED_TIES} += coeff(scalar @$_) foreach(@rnks2);
    $ANN->{TOTAL}->{UNEXPANDED_TIES} += coeff(scalar @$_) foreach(@rnks2);
    
    $ANN->{$user}->{EXPANDED_TIES} += coeff(scalar @$_) foreach(@rnks);
    $ANN->{TOTAL}->{EXPANDED_TIES} += coeff(scalar @$_) foreach(@rnks);    
}

$t->parse(\*STDIN);

sub coeff {
    my $n = shift;
    return $n*($n-1)/2;
}

print STDERR Dumper($ANN);

if ($RAW) {
my $c = 1;
foreach my $j (grep { $_ ne "TOTAL" } sort keys %$ANN) {
    print "$c\t$ANN->{$j}->{RANKS}";
    print "\t$ANN->{$j}->{UNEXPANDED}";
    print "\t$ANN->{$j}->{UNEXPANDED_TIES}";
    print "\t$ANN->{$j}->{EXPANDED}";
    print "\t$ANN->{$j}->{EXPANDED_TIES}\n";
    $c++;
}

my $j = "TOTAL";
print "Total\t$ANN->{$j}->{RANKS}";
print "\t$ANN->{$j}->{UNEXPANDED}";
print "\t$ANN->{$j}->{UNEXPANDED_TIES}";
print "\t$ANN->{$j}->{EXPANDED}";
print "\t$ANN->{$j}->{EXPANDED_TIES}\n";
    
}
else {

print <<'END';
\begin{tabular}{crr@{\hspace{2pt}}rr@{\hspace{2pt}}r}
\toprule
Judge & Ranks & \multicolumn{2}{c}{Unexpanded} & \multicolumn{2}{c}{Expanded}\\  
\midrule
END

my $c = 1;
foreach my $j (grep { $_ ne "TOTAL" } sort keys %$ANN) {
    print " $c & $ANN->{$j}->{RANKS}";
    print " & $ANN->{$j}->{UNEXPANDED}";
    print " & ($ANN->{$j}->{UNEXPANDED_TIES})";
    print " & $ANN->{$j}->{EXPANDED}";
    print " & ($ANN->{$j}->{EXPANDED_TIES}) \\\\\n";
    $c++;
}

print '\midrule', "\n";

my $j = "TOTAL";
print " Total & $ANN->{$j}->{RANKS}";
print " & $ANN->{$j}->{UNEXPANDED}";
print " & ($ANN->{$j}->{UNEXPANDED_TIES})";
print " & $ANN->{$j}->{EXPANDED}";
print " & ($ANN->{$j}->{EXPANDED_TIES}) \\\\\n";
    
print <<'END';
\bottomrule
\end{tabular}
END

}