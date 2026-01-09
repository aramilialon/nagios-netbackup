#!"C:\perl\perl\bin\perl.exe"


# Developer: Giorgio Maggiolo
# Email: giorgio@maggiolo.net
# --
# check_meru_ap_status - Check AP Status
# Copyright (C) 2016 Giorgio Maggiolo, http://www.maggiolo.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

use strict;
#use warnings;

use lib 'c:/perl/perl/vendor/lib/';

use common::sense;
use Getopt::Long;

GetOptions (
	"operation=s" => \my $operation,
	"warning=i" => \my $warning,
	"critical=i" => \my $critical,
	"stype=s" => \my $stype,					# for diskpools
	"diskpool=s" => \my $diskpool,				# for diskpools
	"tapelibrary=i" => \my $tapelibrary,		# for tapelibrary
	"policyname=s" => \my $policyname,			# for backupcheck
	"backupnumber=i" => \my $backupnumber,		# for backupcheck
	'help|?' =>			sub {exec perldoc => -F => $0 or die "Cannot execute perldoc: $!\n";}
) or Error("$0: Error in command line arguments\n");

sub Error {
    print "$0: " . $_[0] . "\n";
    exit 2;
}

my $output;



sub check_diskpools{
	Error('Option --warning required') unless $warning;
	Error('Option --critical required') unless $critical;
	Error('Option --diskpool required') unless $diskpool;
	Error('Option --stype required') unless $stype;
	eval {
		$output = `nbdevquery -listdv -stype $stype -dp $diskpool -U`;
	};
	if ($@) {
		print "UNKNOWN: Something went wrong - $@\n";
		exit(3);
	}
	my $percetuale;
	foreach my $line ($output){
		if ($line =~ /Use%/ && !$percetuale){
			$line =~ /[^\d]*: ([\d]*)\n/;
			$percetuale = $1;
			if ($1 > $critical){
				print "CRITICAL: Diskpool $diskpool has ".($percetuale)."% used space\n";
				exit(2);
			} elsif ($1 > $warning) {
				print "WARNING: Diskpool $diskpool has ".($percetuale)."% used space\n";
				exit(1);
			} 
		}
	}
	print "OK: Diskpool $diskpool has ".($percetuale)."% used space\n";
	exit(0);
}


sub check_drive_status{
	Error('Option --tapelibrary required') unless ($tapelibrary || $tapelibrary eq "0");
	Error('Option --warning required') unless $warning;
	Error('Option --critical required') unless $critical;
	eval {
		$output = `vmquery -rn $tapelibrary -bx | findstr -i scratch | find /v /c \"\"`;
	};
	if ($@) {
		print "UNKNOWN: Something went wrong - $@\n";
		exit(3);
	}
	$output =~ /(.*)\n/;
	$output = $1;
	if($output > $warning ){
		print "OK: There are $output scratch cassettes in the $tapelibrary tape library\n";
		exit(0);
	} elsif($output < $warning and $output > $critical){
		print "WARNING: There are $output scratch cassettes in the $tapelibrary tape library\n";
		exit(1);
	} else {
		print "CRITICAL: There are $output scratch cassettes in the $tapelibrary tape library\n";
		exit(2);
	}
}

sub check_backup{
	Error('Option --policyname required') unless $policyname;
	Error('Option --backupnumber required') unless $backupnumber;
	eval {
		$output = `bpimagelist -policy \"$policyname\" -hoursago 24 -U`;
	};
	if ($@) {
		print "UNKNOWN: Something went wrong - $@\n";
		exit(3);
	}
	my $counter = 0;
	# my $counter = ($output =~ tr/($policyname)//);
	while ($output =~ /$policyname/g) { $counter++; }
	if($counter == $backupnumber){
		print "OK: the task $policyname has $counter backups\n";
		exit(0);
	} else {
		print "WARNING: the task $policyname has $counter backups (requested $backupnumber)\n";
		exit(1);
	}
}

sub check_down_drive {
	eval {
		$output = `vmoprcmd -devmon ds`;
	};
	if ($@) {
		print "UNKNOWN: Something went wrong - $@\n";
		exit(3);
	}
	foreach my $line ($output){
		if ($line =~ /down/i || $line =~ /avr/i){
			print "CRITICAL: There is a down drive\n";
			exit(2);
		}
	}
	print "OK: there isn't any down drive\n";
	exit(0);
}

Error('Option --operation required') unless $operation;

if ($operation eq "diskpools"){
	check_diskpools();
} elsif ($operation eq "tapelibrary"){
	check_drive_status();
} elsif ($operation eq "downdrive"){
	check_down_drive();
} elsif ($operation eq "backupcheck"){
	check_backup();
} else {
	print "UNKNOWN: Operation not recognized\n";
	exit(3);
}

__END__

=head1 NAME

check_netbackup - Check Netbackup

=head1 SYNOPSIS

check_netbackup.pl --operation OPERATION [--warning WARNING] [--critical CRITICAL] [--diskpool DISKPOOL] [--stype STYPE] [--tapelibrary #] [--policyname NAME_POLICY] [--backupnumber #]

=head1 DESCRIPTION

Checks the status of a NetBackup installation

=head1 OPTIONS

=over 4

=item --hostname FQDN

The Hostname of the controller to monitor

=item --perf

Flag for performance data output

=item -help

=item -?

to see this Documentation

=back

=head1 EXIT CODE

3 on Unknown Error
2 if there are some offline APs
1 if there are some disabled APs or any problem occured
0 if everything is ok

=head1 AUTHORS

 Giorgio Maggiolo <giorgio at maggiolo dot net>


