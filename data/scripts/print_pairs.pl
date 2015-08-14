use strict;
use Data::Dumper;
use XML::Twig;
use Getopt::Long;

my $RANK = 0;
GetOptions(
    "r|ranks" => \$RANK,
);

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
        #next if(@sys > 1);
        push(@{$rnks[$rnk]}, @sys); 
        
    }
    @rnks = grep { defined } @rnks;
    
    my @pp;
    for my $i (0 .. $#rnks) {
        my @a1 = sort @{$rnks[$i]};
        for my $x (0 .. $#a1) {
            for my $y ($x + 1 .. $#a1) {
                if ($RANK) {
                    print "$a1[$x]\t$a1[$y]\t",$i+1,"\t",$i+1,"\n";
                }
                else {
                    print "$a1[$x]\t$a1[$y]\t=\n";                    
                }
            }
        }
        
        for my $j ($i + 1 .. $#rnks) {
            my @a2 = @{$rnks[$j]};
            for my $x (0 .. $#a1) {
                for my $y (0 .. $#a2) {
                    if ($RANK) {
                        if($a1[$x] lt $a2[$y]) {
                           print "$a1[$x]\t$a2[$y]\t",$i+1,"\t",$j+1,"\n";
                        }
                        else {
                           print "$a2[$y]\t$a1[$x]\t",$j+1,"\t",$i+1,"\n";
                        }                                
                    }
                    else {
                        if($a1[$x] lt $a2[$y]) {
                           print "$a1[$x]\t$a2[$y]\t<\n";
                        }
                        else {
                           print "$a2[$y]\t$a1[$x]\t>\n";
                        }                                
                    }
                }
            }
        }
    }
}

$t->parse(\*STDIN);

