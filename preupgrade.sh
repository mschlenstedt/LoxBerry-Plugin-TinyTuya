#!/bin/bash

ARGV0=$0 # Zero argument is shell command
ARGV1=$1 # First argument is temp folder during install
ARGV2=$2 # Second argument is Plugin-Name for scipts etc.
ARGV3=$3 # Third argument is Plugin installation folder
ARGV4=$4 # Forth argument is Plugin version
ARGV5=$5 # Fifth argument is Base folder of LoxBerry

# Stop the running bridge/webserver before the upgrade. Kill directly instead
# of using watchdog.pl --action=stop, because stop() would create
# bridge_stopped.cfg - which would then be backed up and restored, leaving the
# bridge permanently stopped after the upgrade.
echo "<INFO> Stopping running bridge/webserver before upgrade"
pkill -f "$ARGV5/data/plugins/$ARGV3/server/mqtt/mqtt_gateway.py" 2>/dev/null
pkill -f "$ARGV5/data/plugins/$ARGV3/server/server.py" 2>/dev/null

echo "<INFO> Creating temporary folders for upgrading"
mkdir -p /tmp/$ARGV1\_upgrade
mkdir -p /tmp/$ARGV1\_upgrade/config
#mkdir -p /tmp/$ARGV1\_upgrade/log
#mkdir -p /tmp/$ARGV1\_upgrade/files

echo "<INFO> Backing up existing config files"
cp -p -v -r $ARGV5/config/plugins/$ARGV3/ /tmp/$ARGV1\_upgrade/config

#echo "<INFO> Backing up existing log files"
#cp -p -v -r $ARGV5/log/plugins/$ARGV3/ /tmp/$ARGV1\_upgrade/log

# Exit with Status 0
exit 0
