#!/usr/bin/perl
use CGI;
use Data::Dumper;
use YAML::Syck;

unless(caller){
	&main();
}

sub main(){
	my $http_req = CGI->new;
	my $sid=$http_req->param('CallSid');	
	if ($sid =~ m/^([a-zA-Z0-9]+)$/){
		print $http_req->header(-type => 'text/plain');
		open $FH, "<", "/var/tmp/$sid.txt";
		my $data=LoadFile($FH);
		Dump($data);
		print $data->{message}."\n";
	}
	else {
		print $http_req->header(-type => 'text/plain');
		print "<eom>";
	}
}
