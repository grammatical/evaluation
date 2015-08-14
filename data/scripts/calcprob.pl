#!/usr/bin/perl

use Inline CPP;

use strict;
use Data::Dumper;

srand(time());

my ($IT, @FILES) = @ARGV;

my $M = 5;
my $N = 13;

my $psum = 0;
my @P;
my @S;

open(IN, "paste " . join(" ", @FILES) . " | ") or die;

@FILES = map { s/^.*\///g; $_ } @FILES;

while (<IN>) {
    chomp;
    s/\r//g;
    my @s = map { s/^\s+|\s+$//g; $_ } split(/\t/, $_);
    push(@S, [@s]);
    
    my $p = p($M, $N, @s);
    push(@P, $p);
    $psum += $p;
}

# normalize probs
$_ /= $psum foreach(@P);

my $k = 0;
while($IT--) {
    my $r = rand();
    my $i = get($r, \@P);
    my %chosen = selectM($i, $M, $S[$i], \@FILES);
    my $N = keys %chosen;
    print "$k\t$N\t$i\t$P[$i]\n";
    printChosen(%chosen);
    $k++;
}

sub printChosen {
    my %chosen = @_;
    foreach(keys %chosen) {
        print "$_\t", join(" ", @{$chosen{$_}}), "\n";
    }
    print "\n";
}

sub selectM {
    my $i = shift;
    my $M = shift;
    
    my $S = shift;
    my $F = shift;
    
    my %H;
    foreach(0 .. $#$S) {
        push(@{$H{$S->[$_]}}, $F->[$_]);
    }
    
    my $min = $M < keys %H ? $M : keys %H;
    
    my %chosen;
    my @keys = keys %H;
    while (keys %chosen < $min) {
        my $j = int(rand() * $min);
        $chosen{$keys[$j]} = $H{$keys[$j]};
    }
    return %chosen;
}

sub get {
    my $r = shift;
    my $P = shift;
    
    my $sum = 0;
    foreach(0 .. $#$P) {
        $sum += $P->[$_];
        if($sum >= $r) {
            return $_;
        }
    }
    return $#$P;
}

sub p {
    my ($M, $N, @s) = @_;
    
    my %COUNTS;
    $COUNTS{$_}++ foreach(@s);
    my @U = sort values %COUNTS;
    
    my $c = C($M, $N, @U);
    my $p = binom($M,2)/binom($c,2); 
}

sub C {
    my ($M, $N, @U) = @_;
    my $C = scalar @U;

    my %SUMS;
    for(0 .. 2**$C-1) {
        my @bin = split //, sprintf("%0${C}b", $_),"\n";
        if(ones(\@bin) <= $M) {
            $SUMS{sum(\@U, \@bin)}++;
        }
    }
    
    my $NUM = 0;
    my $DEN = 0;
    
    for($M .. $N) {
        $NUM += $SUMS{$_} * $_;
        $DEN += $SUMS{$_};
    }
    
    return $NUM/$DEN;
}

sub sum {
    my $U = shift;
    my $b = shift;
    
    my $sum = 0;
    my $i = 0;
    foreach(@$b) {
        $sum += $U->[$i] if ($_);
        $i++;
    }
    return $sum;
}

sub ones {
    my $ones = 0;
    $ones += $_ foreach(@{$_[0]});
    return $ones;
}

__END__
__CPP__

#include <cmath>

double binom(double x, double y) {
    return exp(lgamma(x+1)-lgamma(y+1)-lgamma(x-y+1));
}
