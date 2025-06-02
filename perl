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








use strict;
use warnings;
use File::Basename;
use File::Spec;

my $input_csv = "job_counts.csv";
my $log_dir = "./logs";
my $output_csv = "job_summary_output.csv";

# Step 1: Read input CSV into %job_input_counts
my %job_input_counts;

open(my $in_fh, "<", $input_csv) or die "Cannot open $input_csv: $!";
<$in_fh>;  # skip header
while (my $line = <$in_fh>) {
    chomp $line;
    my ($job, $count) = split /,/, $line;
    $job_input_counts{$job} = $count;
}
close $in_fh;

# Step 2: Get list of server logs
opendir(my $dh, $log_dir) or die "Cannot open directory $log_dir: $!";
my @log_files = grep { /\.log$/ && -f File::Spec->catfile($log_dir, $_) } readdir($dh);
closedir($dh);

my @servers = sort map { basename($_, '.log') } @log_files;

# Step 3: Parse logs and count job matches
my %job_server_counts;

foreach my $file (@log_files) {
    my $server = basename($file, ".log");
    my $path = File::Spec->catfile($log_dir, $file);

    open my $fh, "<", $path or die "Cannot open $path: $!";
    while (my $line = <$fh>) {
        if ($line =~ /End of (\S+)/) {
            my $job = $1;
            $job_server_counts{$job}{$server}++;
        }
    }
    close $fh;
}

# Step 4: Write output CSV manually
open(my $out_fh, ">", $output_csv) or die "Cannot write to $output_csv: $!";

# Write header
print $out_fh "job_name,input_count,new_total_count";
foreach my $server (@servers) {
    print $out_fh ",${server}_count";
}
print $out_fh "\n";

# Write data rows
foreach my $job (sort keys %job_input_counts) {
    my $input_count = $job_input_counts{$job};
    my $total = $input_count;
    my @server_counts;

    foreach my $server (@servers) {
        my $count = $job_server_counts{$job}{$server} // 0;
        push @server_counts, $count;
        $total += $count;
    }

    print $out_fh "$job,$input_count,$total," . join(",", @server_counts) . "\n";
}

close $out_fh;

print "Job summary written to $output_csv\n";