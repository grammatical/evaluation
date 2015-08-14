use strict;

while (<>) {
    my ($s1, $s2, $r1, $r2) = split(/\s/, $_);
    my $op = "=";
    if ($r1 < $r2) {
        $op = "<";
    }
    if ($r1 > $r2) {
        $op = ">";
    }
    
    print join("\t", $s1, $s2, $op), "\n";
}
