#!/usr/bin/perl

use strict;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;
use MIME::Lite;

my $dirname = "/var/lib/naggregator/files/";
my $max_msg = 5;
my $pid_file = "/var/run/naggregator/naggergator.pid";
my $log = "/var/log/naggregator/dequeue-pl.log";


my %hash;
my @files;
my $contact;

main();

sub usage
{
	print "\n  Usage:\n\n";
	print "  $0 <start|stop|restart>\n";
	exit 1;

}


sub main
{
	if($ARGV[0] eq "start" )
	{
		log_pid();
		while(1)
		{
			start_daemon();
			sleep(60);
		}
	}
	elsif ($ARGV[0] eq "stop" )
	{
		stop_daemon();
	}
	elsif ($ARGV[0] eq "restart" )
	{
		stop_daemon();
		start_daemon();
	}
	else
	{
		usage;
	}
	return 1;
}

sub start_daemon
{
        open(FLOG, ">>$log");
	my $date = localtime(time);
	my $run_msg = "\n" . $date . "Probing new alerts...";
        print FLOG $run_msg;
        close(FLOG);

	my $filename;

	opendir ( DIR, $dirname ) || die "Error in opening dir $dirname\n";
	my  @dirs = grep { !/^\./ && -d "$dirname/$_" } readdir(DIR);
	closedir(DIR);


	foreach (@dirs)
	{
		$a = $dirname . $_;
		opendir ( DIR, $a ) || die "Error in opening dir $dirname\n";
		@files =  grep { -f "$a/$_" } readdir(DIR);
		closedir(dIR);
		@files =  map { $a . "/" . $_ } @files;
		unless(@files == () )
		{
		my @del_files = @files;

		parse_files(\@files);
		my @stat = unlink @del_files;
		}
	rmdir $_;
	}
	return 1;
}

sub parse_files
{
	my $ref = shift;
print "\nfi is @$ref";
	%hash = ();
	foreach (@$ref)
	{
		my @elts = split(/\//,$_);
		$contact = $elts[$#elts-1];
		my $file = $elts[$#elts];
#print "\ne is @elements";
#print "\nc is $contact";
		open(F, "$_");
		while(<F>)
		{
			if($_ =~ /(.*?):(.*)/ )
			{
				my $key = $1;
				my $val = $2;
				$key =~ s/^\s+|\s+$//go ;
				$val =~ s/^\s+|\s+$//go ;
				$hash{$file}{$key} = $val;
			}
		}
	}



#print "\nvv is $hostsrv{HOST}{'web1'}\n";

	my %dup = ();

	for my $file (keys %hash)
	{
		for my $file1 ( keys %hash)
		{
			if($file ne $file1)
			{
				if(($hash{$file}{HOST} eq $hash{$file1}{HOST} ) && ( $hash{$file}{SRV} eq $hash{$file1}{SRV} ) )
				{
					my $host_srv = $hash{$file}{HOST} . $hash{$file}{SRV};
#$dup{$host_srv} = $file;
					push @{$dup{$host_srv}}, $file;
				}
			}
		}
	}

	foreach my $file ( keys %dup ) {
		my @arr = uniq(@{$dup{$file}});
		$dup{$file} = [ @arr ];
	}


	foreach my $file ( keys %dup ) {
		foreach my $i ( 1 .. $#{ $dup{$file} } ) {
			my $dup_file = $dup{$file}[$i];
			delete($hash{$dup_file});
		}
	}

print Dumper(%hash);
	aggregate();
	return 1;
}


sub uniq 
{
	return keys %{{ map { $_ => 1 } @_ }};
}


sub aggregate
{

	my %hostsrv = ();
	my $msg = "";

	unless(%hash)
	{
		return 1;
		print "\nstart agg\n";
	}
	else
	{
		foreach my $file (keys %hash)
		{
#print "\nfile is $file";
#print "\n val is $hash{$file}{HOST}";
			my $host_val = $hash{$file}{HOST};
			my $srv_val = $hash{$file}{SRV};

			if($hostsrv{HOST}{$host_val})
			{
				$hostsrv{HOST}{$host_val}++;
			}
			else
			{
				$hostsrv{HOST}{$host_val} = 1;
			}

			if($hostsrv{SRV}{$srv_val})
			{
				$hostsrv{SRV}{$srv_val}++;
			}
			else
			{
				$hostsrv{SRV}{$srv_val} = 1;
			}


		}

		my $max = 0;
		for my $comp ( keys %hostsrv )
		{
			for my $k ( keys %{ $hostsrv{$comp}} )
			{
				if ($hostsrv{$comp}{$k} > $max )
				{
					$max = $hostsrv{$comp}{$k};
				}
			}
		}


		for my $comp ( sort keys %hostsrv )
		{
			for my $k ( keys %{ $hostsrv{$comp}} )
			{
				if ($hostsrv{$comp}{$k} == $max )
				{

					my $sub = "Alert: ";
					my $msg_count = 0;
					for my $file1 ( keys %hash )
					{
						if($hash{$file1}{$comp} eq "$k")
						{
							if($msg_count >= $max_msg)
							{
								last;
							}
							else
							{

								$msg .= "\n\n# " .  " " . $hash{$file1}{HOST} . " " .  $hash{$file1}{PRI} . " " . $hash{$file1}{SRV} . " " .  $hash{$file1}{MSG};
								$sub .= $hash{$file1}{HOST} . "/" . $hash{$file1}{SRV} . ", ";
								delete($hash{$file1});
								if(%hash == () )
								{
									send_alert($sub,$msg,$contact);
									return 1;
								}
								$msg_count++;
							}
						}

					}

					send_alert($sub,$msg,$contact);
					aggregate();
				}
			}
		}
	}
	return 1;
}

sub send_alert
{
	my $sub = shift;
	my $msg = shift;
	my $contact = shift;

	if($sub eq "Alert: ")
	{
	return 1;
	}

	print "\n\n Sub - $sub Msg- $msg Contact - $contact\n";
	my $date = localtime(time);

	my $log_data = "\n\n" . $date . " Sub - " . $sub . "Msg - " . $msg . "Contact - " . $contact;
	open(FLOG, ">>$log");
	print FLOG $log_data;
	close(FLOG);
	system("/usr/bin/tail -5000 $log > /tmp/dequeue-pl.log; /bin/mv /tmp/dequeue-pl.log $log");

	if($contact =~ /\@/)
	{
		my $msg = MIME::Lite->new(
				From        => 'nagios@domain.com',
				To          => $contact ,
				Subject     => $sub,
				#'Reply-To'  => 'oncall@domain.com',
				Type       => 'TEXT',
				Data       => $msg
				);
	$msg->send ;
	}
	else
	{
		my  $data = $sub . $msg;
	system("/usr/local/bin/send_sms \"$data\" $contact"); 
	#system("/usr/local/bin/post_exotel.pl \"$data\" $contact"); 
	}
	return 1;
}



sub log_pid
{
	my $ps_count = `/bin/ps aux |grep b.pl |grep perl | grep -v grep |wc -l `;
	if($ps_count > 1 )
	{
		print "\nAnother instance running. Exitting\n";
		exit 1;
	}
	else
	{
		my $pid = $$;
		system("echo $pid > $pid_file");
	}
	return 1;
}


sub stop_daemon
{
	if(-f $pid_file)
	{
		my $pid = `cat $pid_file`;
		print "\np is $pid\n";
		my $exists = kill 0, $pid;
		if($exists)
		{
			kill 9, $pid;
		}
	}
	return 1;
}
