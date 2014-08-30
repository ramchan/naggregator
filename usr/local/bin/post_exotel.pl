#!/usr/bin/perl

use strict;
#libyaml-tiny-perl libcrypt-ssleay-perl libdata-dump-perl libxml-simple-perl
use DBI;
use LWP::Simple;
use XML::Simple;
use LWP::UserAgent;
use Data::Dumper;
use YAML::Syck;


unless (caller) {
  &main(@ARGV); 
}

# SQLite handle. Incase required.
#sub db_handle(){
#	my $dbh;
#	$dbh=DBI->connect("dbi:SQLite:dbname=/tmp/alerts.sqlt", "", "",{RaiseError => 1, AutoCommit => 1});
#	$dbh->do("CREATE TABLE IF NOT EXISTS alert (id INTEGERS PRIMARY KEY, alert TEXT, sid TEXT)");
#	return $dbh;
#}

sub main(){
	my ($message, $number)= (shift, shift);
	#print $message, $number;
	my $sid=&exotel_Post($number);
	my $alert={"sid"=>$sid, "message"=>$message};
	#print Dumper($alert);
	&write_file($sid, $alert);
}

# Write the alert as a serialized associative array to a file whose name is $SID.txt 
sub write_file(){
	my $sid=$_[0];
	my $alert=$_[1];
	my $filename="/var/tmp/$sid.txt";
	#print $filename;
	open my $FH,">", $filename or die "Couldn't open file for writing $!";
	#print $FH Dumper($alert);
	#print Dump($data);	
	DumpFile($FH, $alert);
	close($FH);
}


# Do a HTTP Post to Exotel with the number and get the SID from the xml, which is used as an identifier
sub exotel_Post(){
	my $url='https://';
	my $dst_number=$_[0];
	my $src_number=112233445;
	my $data=("From=$src_number&To=$dst_number");
        my $browser = LWP::UserAgent->new;
	my $response = $browser->post($url, ["From"=>$src_number, "To"=>$dst_number]);
	die "$url error: ", $response->status_line unless $response->is_success;
	my $xml_response=XMLin($response->content);
	Dumper($xml_response);
	my $sid=$xml_response->{Call}->{Sid};
	#print $sid."\n";
	return $sid;
}

