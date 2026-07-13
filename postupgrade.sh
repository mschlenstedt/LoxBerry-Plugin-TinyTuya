#!/bin/bash

ARGV0=$0 # Zero argument is shell command
ARGV1=$1 # First argument is temp folder during install
ARGV2=$2 # Second argument is Plugin-Name for scipts etc.
ARGV3=$3 # Third argument is Plugin installation folder
ARGV4=$4 # Forth argument is Plugin version
ARGV5=$5 # Fifth argument is Base folder of LoxBerry

echo "<INFO> Restoring saved config (mirror - only backed-up files survive)"
# Mirror the config dir back from the backup instead of merge-copying it.
# --delete removes files the new archive shipped but the backup did NOT
# contain - especially the bundled config/bridge_stopped.cfg of a fresh
# install, which would otherwise disable the watchdog after every upgrade.
# If the flag WAS in the backup (user deliberately stopped the bridge), it
# is restored and the bridge stays stopped. Trailing slash = copy contents.
rsync -a --delete /tmp/$ARGV1\_upgrade/config/$ARGV3/ $ARGV5/config/plugins/$ARGV3/

#echo "<INFO> Copy back existing log files"
#cp -p -v -r /tmp/$ARGV1\_upgrade/log/$ARGV3/* $ARGV5/log/plugins/$ARGV3/

echo "<INFO> Remove temporary folders"
rm -r /tmp/$ARGV1\_upgrade

# Restart the bridge unless it was manually stopped before the upgrade.
# preupgrade.sh killed the old processes (which were running deleted code
# anyway), postinstall.sh cloned the fresh TinyTuya server - so start the
# new one now. postupgrade.sh runs as user loxberry, matching the watchdog.
STOPPED_FLAG="$ARGV5/config/plugins/$ARGV3/bridge_stopped.cfg"
WATCHDOG="$ARGV5/bin/plugins/$ARGV3/watchdog.pl"

if [ -f "$STOPPED_FLAG" ]; then
	echo "<INFO> bridge_stopped.cfg set - leaving bridge stopped"
elif [ ! -x "$WATCHDOG" ]; then
	echo "<WARNING> $WATCHDOG not found or not executable - bridge not started"
else
	echo "<INFO> Starting bridge with new version"
	# setsid + redirected stdio detaches the bridge from the installer
	# process so it keeps running after this script exits.
	setsid "$WATCHDOG" --action=start </dev/null >/dev/null 2>&1 &
	echo "<OK> Bridge start triggered"
fi

# Exit with Status 0
exit 0
