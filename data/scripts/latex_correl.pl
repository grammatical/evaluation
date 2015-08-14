use strict;

my $sp_f1 = m2grep('^1\t', "include/m2.spearman.EW.tsv");
my $sp_f05 = m2grep('^0.5\t', "include/m2.spearman.EW.tsv");
my $sp_f025 = m2grep('^0.25\t', "include/m2.spearman.EW.tsv");
my $sp_f01 = m2grep('^0.1\t', "include/m2.spearman.EW.tsv");
my ($sp_b, $sp_max) = m2max("include/m2.spearman.EW.tsv");

my $pe_f1 = m2grep('^1\t', "include/m2.pearson.EW.tsv");
my $pe_f05 = m2grep('^0.5\t', "include/m2.pearson.EW.tsv");
my $pe_f025 = m2grep('^0.25\t', "include/m2.pearson.EW.tsv");
my $pe_f01 = m2grep('^0.1\t', "include/m2.pearson.EW.tsv");
my ($pe_b, $pe_max) = m2max("include/m2.pearson.EW.tsv");


my $sp_wacc = sp("EW.ranking.txt", "metrics/scores.iwacc");
my $pe_wacc = pe("EW.ranking.txt", "metrics/scores.iwacc");

my $sp_bleu = sp("EW.ranking.txt", "metrics/scores.bleu");
my $pe_bleu = pe("EW.ranking.txt", "metrics/scores.bleu");

my $sp_met = sp("EW.ranking.txt", "metrics/scores.meteor");
my $pe_met = pe("EW.ranking.txt", "metrics/scores.meteor");

print <<END;
\\begin{tabular}{lcc}
\\toprule
Metric & Spearman's \$\\rho\$ & Pearson's \$r\$ \\\\
\\midrule
M\$^2\$ F\$_{1.0}\$  & $sp_f1 & $pe_f1 \\\\
M\$^2\$ F\$_{0.5}\$\$^*\$  & $sp_f05 & $pe_f05 \\\\
M\$^2\$ F\$_{0.25}\$ & $sp_f025 & $pe_f025 \\\\
M\$^2\$ F\$_{$sp_b}\$  & \\textbf{$sp_max} & \\textbf{$pe_max} \\\\
M\$^2\$ F\$_{0.1}\$  & $sp_f01 & $pe_f01 \\\\ \\midrule
I-WAcc & $sp_wacc & $pe_wacc \\\\ \\midrule
BLEU   & $sp_bleu & $pe_bleu \\\\
METEOR & $sp_met & $pe_met \\\\
\\bottomrule
\\end{tabular}
END

sub sp {
    my ($r, $m) = @_;
    chomp(my $sp = `perl scripts/spearman.pl $r $m`);
    return sprintf("%.3f", $sp);
}

sub pe {
    my ($r, $m) = @_;
    chomp(my $pe = `perl scripts/pearson.pl $r $m`);
    return sprintf("%.3f", $pe);
}

sub m2grep {
    my ($exp, $path) = @_;
    chomp(my $line = `grep -P '$exp' $path`);
    my ($b, $r) = split(/\s/, $line);
    return sprintf("%.3f", $r);
}

sub m2max {
    my ($path) = @_;
    open(M2, "<", $path) or die "problem";
    my ($maxb, $maxr) = (1,0);
    while (<M2>) {
        chomp;
        my ($b, $r) = split(/\s/, $_);
        if ($r > $maxr) {
            $maxr = $r;
            $maxb = $b;
        }
        
    }
    
    close(M2);
    
    return (sprintf("%.2f", $maxb), sprintf("%.3f", $maxr));
}
