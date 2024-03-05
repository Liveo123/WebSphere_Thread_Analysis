#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

## Script to analyse two thread dump files and create a easier to read report 
## with some of the most useful information along with dumps of threads that 
## are found in both dump files (i.e. threads that have been around a long time).

# Variables for filenames initialized to undef
my ($first_file, $second_file, $output_file) = (undef, undef, "output.txt");

# Help message
my $help = 0;
GetOptions('h|help' => \$help);

if ($help || @ARGV < 2) {
    print "Usage: $0 [options] first_file_name second_file_name\n";
    print "Options:\n";
    print "  -h, --help            Print this help message.\n";
    print "\nThis script processes two input files to extract and analyze thread dump information.\n";
    exit;
}

# Assigning command-line arguments to variables
($first_file, $second_file) = @ARGV;

my @file_sections_1 = ("1TIFILENAME", "1TIDATETIMEUTC ", "1TIDATETIME", "1TIREQFLAGS", "1TIPREPSTATE", "0SECTION       GPINFO ", "2XHOSLEVEL", "2XHCPUS", "3XHCPUARCH", "3XHNUMCPUS", "0SECTION       ENVINFO", "1CIJAVAVERSION", "1CIJITMODES", "1CIRUNNINGAS", "1CIVMIDLESTATE", "1CICONTINFO", "1CIJAVAHOMEDIR", "1CIJAVADLLDIR", "1STSEGTOTAL", "1STSEGINUSE", "1STSEGFREE", "1STSEGTYPE", "0SECTION    
   THREADS", "1XMPOOLINFO", "2XMPOOLLIVE");

 my @file_sections_2 = ("1CICMDLINE", "1CISYSCP", "2CIUSERARG", "1CIUSERLIMITS", "2CIUSERLIMIT", "1CIENVVARS", "2CIENVVAR", "1CICPUINFO", "2CIPHYSCPU", "2CIONLNCPU", "2CIBOUNDCPU", "2CIACTIVECPU", "2CITARGETCPU", "1CICGRPINF    O", "2CICGRPINFO", "3CICGRPINFO");

print("\nRunning... (Probably) not frozen. Please give it a few seconds.\n\n");

# First, go through the second file and find information useful for analysing
# the thread dump and ignore the rest.
open my $fh, '<', $second_file or die "Could not open file: $!";
open my $gh, '>', $output_file or die "Could not open file: $!";
print $gh "\n\n############# USEFUL INFO #############\n\n\n";
while (my $line = <$fh>) {
    chomp $line;
    foreach my $file_section_1 (@file_sections_1) {
        if ($line =~ /^$file_section_1.*/) {
                print $gh "$line\n";
        }
    }
}

close $fh;
close $gh;
    
# Open the first file, grab the thread ids and add to array, then return the array
sub get_thread_ids { 
        my @thread_ids = ();

        open my $fh, '<', $_[0] or die "Could not open file: $!";
        while (my $line = <$fh>) {
        if ($line =~ /3XMTHREADINFO\s.*WebContainer\s.*J9VMThread:(0x\w*)/) {
                push(@thread_ids, "$1");
        }
        }
        close $fh;

        return @thread_ids;
}

my @first_threads = ();
my @second_threads = ();

# Grab the thread ids from the the two file dumps
@first_threads = get_thread_ids($first_file);
@second_threads = get_thread_ids($second_file);

# Find the WebContainer thread ids repeated in both files.
my @repeated = ();
foreach my $first (@first_threads) {
        foreach my $second (@second_threads) {
                if ( $first eq $second) {
                        push(@repeated, $first);
                }
        }
}

## Go through the each line of the output file until a thread is found that is one of the repeated.
## Loop through each line of the dump until the end of that thread is found (NULL) outputting each
## of those lines to the output file.
my @thread_ids = ();

open $fh, '<', $second_file or die "Could not open file: $!";
open $gh, '>>', $output_file or die "Could not open file: $!";
print $gh "\n\n############# LONG LIVING THREADS #############\n\n\n";
while (my $line = <$fh>) {
    chomp $line;
    my $index = 0;
    foreach my $thread_id (@repeated) {
        if ($line =~ /\Q$thread_id\E/) {
            my $found_null = 0;
            do {
                print $gh "$line\n";
                defined($line = <$fh>) or last;
                chomp $line;
                $found_null = 1 if $line eq "NULL";
            } while (!$found_null);
            print $gh "\n\n\n" if $found_null;
            splice(@repeated, $index, 1);       # Removes the threadid just used for efficiency
        }
        $index++;
    }
}
close $fh;
close $gh;

# Go through the second file and find EXTRA information useful for analysing
# the thread dump and ignore the rest.
open $fh, '<', $second_file or die "Could not open file: $!";
open $gh, '>>', $output_file or die "Could not open file: $!";
print $gh "\n\n############# EXTRA USEFUL INFO #############\n\n\n";
while (my $line = <$fh>) {
    chomp $line;
    foreach my $file_section_2 (@file_sections_2) {
        if ($line =~ /^$file_section_2.*/) {
                print $gh "$line\n";
        }
    }
}
close $fh;
close $gh;

print("Complete.  Check out " . $output_file . " for your report.\n\n");
