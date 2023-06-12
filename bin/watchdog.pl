#!/usr/bin/perl

use LoxBerry::System;
use LoxBerry::IO;
use LoxBerry::Log;
use LoxBerry::JSON;
use Getopt::Long;
#use warnings;
use strict;
#use Data::Dumper;

# Version of this script
my $version = "0.1.1";

# Globals
my $error;
my $verbose;
my $action;

# Logging
# Create a logging object
my $log = LoxBerry::Log->new (  name => "watchdog",
package => 'poolex',
logdir => "$lbplogdir",
addtime => 1,
);
$log->default;

# Commandline options
# CGI doesn't work from other CGI skripts... :-(
GetOptions ('verbose=s' => \$verbose,
            'action=s' => \$action);

# Verbose
if ($verbose) {
        $log->stdout(1);
        $log->loglevel(7);
}

LOGSTART "Starting Watchdog";

# Lock
my $status = LoxBerry::System::lock(lockfile => 'poolex-watchdog', wait => 120);
if ($status) {
    print "$status currently running - Quitting.";
    exit (1);
}

# Read Configuration

# Todo
if ( $action eq "start" ) {

	&start();

}

elsif ( $action eq "stop" ) {

	&stop();

}

elsif ( $action eq "restart" ) {

	&restart();

}

elsif ( $action eq "check" ) {

	&check();

}

else {

	LOGERR "No valid action specified. action=start|stop|restart|check is required. Exiting.";
	print "No valid action specified. action=start|stop|restart|check is required. Exiting.\n";
	exit(1);

}

#LOGEND "This is the end - My only friend, the end...";
#LoxBerry::System::unlock(lockfile => 'landroid-ng-watchdog');

exit;


#############################################################################
# Sub routines
#############################################################################

##
## Start
##
sub start
{

	if (-e  "$lbpconfigdir/bridge_stopped.cfg") {
		unlink("$lbpconfigdir/bridge_stopped.cfg");
	}

	LOGINF "START called...";
	LOGINF "Starting Bridge...";
	# Logging for Bridge
	# Create a logging object
	my $logtwo = LoxBerry::Log->new (  name => "bridge",
	package => 'poolex',
	logdir => "$lbplogdir",
	addtime => 1,
	);
	# Loglevel
	my $loglevel = "INFO";
	$loglevel = "CRITICAL" if ($log->loglevel() <= 2);
	$loglevel = "ERROR" if ($log->loglevel() eq 3);
	$loglevel = "WARNING" if ($log->loglevel() eq 4 || $log->loglevel() eq 5);
	$loglevel = "DEBUG" if ($log->loglevel() eq 6 || $log->loglevel() eq 7);
	# Create Log
	$logtwo->LOGSTART("Bridge started.");
	$logtwo->INF("Bridge will be started.");
	my $bridgelogfile = $logtwo->filename();
	system ("pkill -f $lbpbindir/bridge.py");
	sleep 2;
	system ("cd $lbpbindir && python3 $lbpbindir/bridge.py --logfile=$bridgelogfile --loglevel=$loglevel 2>&1 &");

	LOGOK "Done.";

	return(0);

}

sub stop
{

	LOGINF "STOP called...";
	LOGINF "Stopping Bridge...";
	system ("pkill -f $lbpbindir/bridge.py");

	my $response = LoxBerry::System::write_file("$lbpconfigdir/bridge_stopped.cfg", "1");

	LOGOK "Done.";

	return(0);

}

sub restart
{

	LOGINF "RESTART called...";
	&stop();
	sleep (2);
	&start();

	return(0);

}

sub check
{

	LOGINF "CHECK called...";

	if (-e  "$lbpconfigdir/bridge_stopped.cfg") {
		LOGOK "Bridge was stopped manually. Nothing to do.";
		return(0);
	}
	
	# Creating tmp file with failed checks
	if (!-e "/dev/shm/poolex-watchdog-fails.dat") {
		my $response = LoxBerry::System::write_file("/dev/shm/poolex-watchdog-fails.dat", "0");
	}

	my ($exitcode, $output)  = execute ("pgrep -f $lbpbindir/bridge.py");
	if ($exitcode != 0) {
		LOGWARN "Bridge seems to be dead - Error $exitcode";
		my $fails = LoxBerry::System::read_file("/dev/shm/poolex-watchdog-fails.dat");
		chomp ($fails);
		$fails++;
		my $response = LoxBerry::System::write_file("/dev/shm/poolex-watchdog-fails.dat", "$fails");
		if ($fails > 9) {
			LOGERR "Too many failures. Will stop watchdogging... Check your configuration and start bridge manually.";
		} else {
			&restart();
		}
	} else {
		LOGOK "Bridge seems to be alive. Nothing to do.";
		my $response = LoxBerry::System::write_file("/dev/shm/poolex-watchdog-fails.dat", "0");
	}

	return(0);

}

##
## Always execute when Script ends
##
END {

	LOGEND "This is the end - My only friend, the end...";
	LoxBerry::System::unlock(lockfile => 'poolex-watchdog');

}
