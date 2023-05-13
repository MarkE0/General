#!/bin/perl -w
# Convert a tli hex string to ip address and port number
# E.g. 0x200D487F000001 --> 127.0.0.1 3400

use strict;

sub usage
{
    print ("Usage: $0 <tliHexString>\n");
    exit $_[0]; # Exit with the passed in exit code
}

# Check Arguments passed in
if ($#ARGV != 0)        { usage (1) } # Wrong number of args
if ($ARGV[0] =~ "-[hH]"){ usage (0) } # Show help
if (length($ARGV[0])<16){ print("Hex string looks a little short - was expecting 16 chars. Ending. \n"); exit 2 }

my $hexString = $ARGV[0];
$hexString =~ s/^[\\]*x//; # Clean the string of the proceeding "\x"

# tli format: TLI Family (8), Port, IP1, IP2, IP3, IP4, Padding
for (my $i=8; $i<=15; $i+=2)
{
    print(eval("0x".substr($hexString,$i,2))); # Print IP address
    if($i<14){print (".")} else {print (" ")}; # Print seperator
}
print(eval("0x".substr($hexString,4,4))."\n"); # Print Port number

exit 0;
