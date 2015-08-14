#!/usr/bin/env perl

use strict;

my $fold_max = {};

while (<STDIN>) {
    chomp;
    my ($fold, $d, $acc) = split(/\t/, $_);
    if(!exists($fold_max->{$fold}) or $fold_max->{$fold} < $acc) {
        $fold_max->{$fold} = $acc;
    }
}

my $sum = 0;
foreach(keys %$fold_max) {
    $sum += $fold_max->{$_}
}

print $sum / scalar keys %$fold_max, "\n";
