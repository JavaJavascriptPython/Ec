#!/usr/bin/perl
use strict;
use warnings;

my $mock_dir = 'mock';
my $prod_dir = 'prod';

my (%mock_jobs, %prod_jobs);

# Read jobs from mock directory
read_jobs_from_dir($mock_dir, \%mock_jobs);

# Read jobs from prod directory
read_jobs_from_dir($prod_dir, \%prod_jobs);

# Open output file
open(my $out, '>', 'job_comparison_report.txt') or die "Cannot open output file: $!";

# Jobs in both
print $out "Jobs in BOTH prod and mock:\n";
foreach my $job (sort keys %prod_jobs) {
    print $out "$job\n" if exists $mock_jobs{$job};
}

# Jobs only in prod
print $out "\nJobs ONLY in prod:\n";
foreach my $job (sort keys %prod_jobs) {
    print $out "$job\n" unless exists $mock_jobs{$job};
}

# Jobs only in mock
print $out "\nJobs ONLY in mock:\n";
foreach my $job (sort keys %mock_jobs) {
    print $out "$job\n" unless exists $prod_jobs{$job};
}

close($out);

print "Comparison report saved in 'job_comparison_report.txt'\n";

# Function to read job names from logs in a directory
sub read_jobs_from_dir {
    my ($dir, $job_hash) = @_;

    opendir(my $dh, $dir) or die "Cannot open directory $dir: $!";
    my @files = grep { -f "$dir/$_" } readdir($dh);
    closedir($dh);

    foreach my $file (@files) {
        my $path = "$dir/$file";
        open(my $fh, '<', $path) or die "Cannot open file $path: $!";
        while (my $line = <$fh>) {
            if ($line =~ /start\s+(\S+)/) {
                $job_hash->{$1} = 1;
            }
        }
        close($fh);
    }
}