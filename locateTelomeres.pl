#!/usr/bin/env perl
use strict;
use Getopt::Long;

my $usage = <<USAGE;
Description: Locate telomeres
Usage:
    perl $0 
      --infile  -i  input genome fasta
      --outfile -o  output telomere info
      --split   -s  split length
      --overlap -o  overlap length
      --repeat  -r  repeat unit 
      --min     -m  minimum repeat number
      --help    -h  print this help info
USAGE

my ($infile, $outfile, $splitLength, $overlapLength, $repeatunit, $minRepeatNum, $help);

GetOptions(
    "infile|i:s" => \$infile,
    "outfile|o:s" => \$outfile,
    "split|s:i" => \$splitLength,
    "overlap|o:i" => \$overlapLength,
    "repeat|r:s" => \$repeatunit,
    "min|m:i" => \$minRepeatNum,
    "help|h" => \$help,
);

die $usage unless (@ARGV > 0);

$splitLength ||= 100000;
$overlapLength ||= 10000;
$repeatunit ||= "CCCTAAA";
$repeatunit = uc($repeatunit);
my $repeatunit_rev = reverse $repeatunit;
$repeatunit_rev =~ tr/ATCG/TAGC/;
$minRepeatNum ||= 3;

open IN, $infile or die "Can not open file $infile $!";
open OUT, ">$outfile" or die "Cannot write to this file $outfile $!";
my (%seq, $seq_id);
while (<IN>) {
    chomp;
    if (m/^>(\S+)/) {
        $seq_id = $1;
    }
    else {
        $_ = uc($_);
        $seq{$seq_id} .= $_;
    }
}
close IN;

my (%seq_split, %seq_length);
foreach my $id (keys %seq) {
    my $seq = $seq{$id};
    my $length = length($seq);
    $seq_length{$id} = $length;
    my $pos = 0;
    while ($pos < $length) {
        $seq_split{$id}{$pos} = substr($seq, $pos, $splitLength + $overlapLength);
        $pos += $splitLength;
    }
}

print OUT "SeqID\tSeqLength\tStart\tEnd\tLength\tType\n";
foreach my $id (sort keys %seq_split) {
    foreach my $pos (sort {$a <=> $b} keys %{$seq_split{$id}}) {
        my $seq = $seq_split{$id}{$pos};
        while ($seq =~ m/(($repeatunit){$minRepeatNum,})/g) {
            my $length = length($1);
            my $end = pos($seq);
            $end = $end + $pos;
            my $start = $end - $length + 1;
            print OUT "$id\t$seq_length{$id}\t$start\t$end\t$length\t$repeatunit\n";
        }
        while ($seq =~ m/(($repeatunit_rev){$minRepeatNum,})/g) {
            my $length = length($1);
            my $end = pos($seq);
            $end = $end + $pos;
            my $start = $end - $length + 1;
            print OUT "$id\t$seq_length{$id}\t$start\t$end\t$length\t$repeatunit_rev\n";
        }
    }
}

