#!/usr/bin/perl

use strict;
use Time::HiRes qw(gettimeofday);


main();

sub main
{

my $notify_type = $ARGV[0];
my $host = $ARGV[1];
my $service = $ARGV[2];
my $priority = $ARGV[3];
my $msg = $ARGV[4];
my $contact = $ARGV[5];

my $time =  gettimeofday;
chomp($time);

my $dir = "/var/lib/naggregator/files/" . $contact;


my $file = $dir . "/" . $time;
my $log = "/var/log/naggregator/enqueue-pl.log";
my $date = localtime(time);

unless(-d $dir )
{
system("/bin/mkdir -p $dir");
}
open(F, ">>$file");
print F "TYPE: $notify_type\n";
print F "HOST: $host\n";
print F "SRV: $service\n";
print F "PRI: $priority\n";
print F "MSG: $msg\n";
close(F);
my $msg = "\n\n" . $date .  " [" . $notify_type . "," . $host . "," . $service . "," . $priority . "," . $msg . "," . $contact . "]"; 
open(FLOG, ">>$log");
print FLOG $msg;
close(FLOG);
system("/usr/bin/tail -5000 $log > /tmp/enqueue-pl.log; /bin/mv /tmp/enqueue-pl.log $log");
return 1;
}



