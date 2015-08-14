use strict;

use Getopt::Long;

my $HLINE = 0;
GetOptions(
    "h|hline" => \$HLINE
);

print <<'END';
\begin{tabular}{lrcl}
\toprule
\# & Score & Range & System \\
\midrule
END

my $lastrank = 0;
my $rank = 1;

while (<>) {
    if (/\+\+\+/) {
        $rank++;
    }
    else {
        my ($sys, $score, $r1, $r2) = m/^(\S+) (\S+) \((\S+), (\S+)\)$/;
        $score = sprintf("%.3f", $score);
        $r1 = int($r1);
        $r2 = int($r2);
        my $range = "$r1-$r2";
        if ($r1 == $r2) {
            $range = "$r1";
        }
        if ($rank > $lastrank) {
            if ($HLINE) {
                print '\hline', "\n" if($lastrank);    
            }
            else {
                print '\midrule', "\n" if($lastrank);    
            }
            print sprintf("% 2d", $rank);
        }
        else {
            print "  ";
        }
        
        print " & $score & $range & $sys \\\\\n";
        $lastrank = $rank;
    }
}

print <<'END';
\bottomrule
\end{tabular}
END
