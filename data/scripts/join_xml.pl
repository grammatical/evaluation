use strict;
use Data::Dumper;
use XML::Twig;
use Getopt::Long;
use POSIX;

my $LIMIT = 0;
GetOptions(
    "l|limit=i" => \$LIMIT,
);
my %COUNT;
my %judge;

print <<END;
<?xml version="1.0" encoding="UTF-8"?>
<appraise-results>

<error-correction-ranking-result source-language="err" id="10000.0.txt-0" target-language="cor">
END


for(my $i = 0; $i < @ARGV; $i++) {        
    my $t = XML::Twig->new( 
        twig_roots   => {
            'ranking-item' => \&item,
        },
        pretty_print => 'indented',        
    );
    $t->parsefile($ARGV[$i]);
}

delete $judge{admin};
foreach my $j (sort keys %judge) {
    my @a = @{$judge{$j}};
    @a = roundrobin(@a);
    print "$_\n" foreach(@a);
}

print <<END;
</error-correction-ranking-result>

</appraise-results>
END

sub item {
    my($t, $p)= @_;
    my $user = $p->{att}->{user};
    $COUNT{$user}++;
    my $duration = $p->{att}->{duration};
    my $id = $p->{att}->{id};
    my $srcid = $p->{att}->{'src-id'};
    
    push(@{$judge{$user}}, $p->sprint());
}

sub roundrobin {
    my @a = @_;
    my @b;
    my $step = ceil(@a/$LIMIT);
    my $i = 0;
    my $j = 0;
    while(@b < @a and @b < $LIMIT) {
        if ($i >= @a) {
            $j++;
            $i = $j;
        }
        
        push(@b, $a[$i]);
        $i += $step;
    }
    return @b;
}