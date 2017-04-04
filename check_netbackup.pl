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
	"policy=s" => \my $policyname,				# for backupcheck
	"backupnumber=i" => \my $backupnumber,		# for backupcheck
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
	if ($warning > $critical){
		my $temp = $warning;
		$warning = $critical;
		$critical = $temp; 
	}
	eval {
		$output = system("nbdevquery -listdv -stype DataDomain -dp $diskpool -U");
	};
	if ($@) {
		print "UNKNOWN: Something went wrong - $@\n";
		exit(3);
	}
	foreach my $line (<$output>){
		if ($line =~ /Use%/){
			$line =~ /[^\d]*: ([\d]*)\n/;
			if ($1 > $critical){
				print "CRITICAL: Diskpool $diskpool has ".(100-%$1)." free space\n";
				exit(2);
			} elsif ($1 > $warning) {
				print "WARNING: Diskpool $diskpool has ".(100-%$1)." free space\n";
			}
		}
	}
	exit(0);
}



# sub check_drive_status{
# 	Error('Option --tapelibrary required') unless $tapelibrary;
# 	eval {
# 		$output = capture("perl plugins/vminfo.pl --vmname ".ucfirst(lc($old_vm_name))." --username $username --password $password --server $vc_server --fields overallStatus");
# 	};
# 	if ($@) {
# 		print "UNKNOWN: Something went wrong - $@\n";
# 		exit(3);
# 	}
# }

# sub check_backup{
# 	Error('Option --policyname required') unless $policyname;
# 	Error('Option --backupnumber required') unless $backupnumber;
# 	eval {
# 		$output = capture("perl plugins/vminfo.pl --vmname ".ucfirst(lc($old_vm_name))." --username $username --password $password --server $vc_server --fields overallStatus");
# 	};
# 	if ($@) {
# 		print "UNKNOWN: Something went wrong - $@\n";
# 		exit(3);
# 	}
# }

Error('Option --operation required') unless $operation;

if ($operation eq "diskpools"){
	check_diskpools();
} elsif ($operation eq "tapelibrary"){
	check_drive_status();
} elsif ($operation eq "backupcheck"){
	check_backup();
} else {
	print "UNKNOWN: Operation not recognized\n";
	exit(3);
}