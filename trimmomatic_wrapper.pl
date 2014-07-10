#!/usr/bin/perl

#  trimmomatic_wrapper.pl
#  
#  Copyright 2012 Simon Gladman<simon.gladman@monash.edu>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

#Version 1.1 - goes with Trimmomatic-0.32.jar

use strict;
use warnings;
use File::Temp qw( tempdir tempfile);

my %stuff = @ARGV;

my $dir = tempdir(CLEANUP => 1);
my ($fwdtempfh, $fwdtemp) = tempfile( DIR => $dir );
my ($revtempfh, $revtemp) = tempfile( DIR => $dir );

foreach my $x (keys %stuff){
    print "$x\t" . $stuff{$x} . "\n";
}

my $tooldir = $stuff{"tool-dir"};
my $jar = "$tooldir/trimmomatic-0.32.jar";

my $numthreads = $stuff{"threads"};


my $cmd = "java -cp $jar org.usadellab.trimmomatic.Trimmomatic";

if($stuff{"paired"} eq "True"){
    $cmd .= "PE";
}
else {
    $cmd .= "SE";
}

$cmd .= " -threads $numthreads";

$cmd .= " -phred33" if($stuff{"phred"} eq "phred33");

if($stuff{"log"} eq "True"){
    $cmd .= " -trimlog " . $stuff{"logfile"};
}

if($stuff{"paired"} eq "True"){
    $cmd .= " " . join(" ",($stuff{"fwdfile"},$stuff{"revfile"},$stuff{"fwdpairs"},$fwdtemp,$stuff{"revpairs"},$revtemp));
}
else {
    $cmd .= " " . join(" ",($stuff{"fwdfile"},$stuff{"singles"}));
}

$cmd .= " " . join(":",("ILLUMINACLIP",$stuff{"adaptfile"},$stuff{"adaptseed"},$stuff{"adaptpalindrome"},$stuff{"adaptsimple"})) if $stuff{"cutadapt"} eq "True";

$cmd .= " " . join(":",("SLIDINGWINDOW",$stuff{"slidingsize"},$stuff{"slidingqual"})) if $stuff{"slidingwindow"} eq "True";

$cmd .= " " .join(":",("LEADING",$stuff{"leadingqual"})) if $stuff{"trimleading"} eq "True";

$cmd .= " " .join(":",("TRAILING",$stuff{"trailingqual"})) if $stuff{"trimtrailing"} eq "True";

$cmd .= " " .join(":",("CROP",$stuff{"croplen"})) if $stuff{"crop"} eq "True";

$cmd .= " " .join(":",("HEADCROP",$stuff{"headcroplen"})) if $stuff{"headcrop"} eq "True";

$cmd .= " " .join(":",("MINLEN",$stuff{"minlen"}));

print "Command:\t$cmd\n";

if(system($cmd) == 0){
    if ($stuff{"paired"} eq "True"){
        my $catcmd = "cat $fwdtemp $revtemp > " . $stuff{"singles"}; 
        system($catcmd) == 0 or die "Something went wrong with the cat command $!";
    }
}
else{
    print "There was an error with trimmomatic! $!";
    exit(1);
}

exit(0);
