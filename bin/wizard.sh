#!/bin/bash

pluginname=$(perl -e 'use LoxBerry::System; print $lbpplugindir; exit;')

# Logging
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=$pluginname
NAME=wizard
LOGDIR=${LBPLOG}/${PACKAGE}
STDERR=1
LOGLEVEL=7
LOGSTART "TinyTuya Wizard started."

if [ ! -e $LBPCONFIG/$pluginname/tinytuya.json ]; then
	LOGERR "Please first configure ApiKey etc. before starting the wizard."
	exit 1
fi

LOGINF "Now scanning for Tuya Devices..."
cd $LBPCONFIG/$pluginname
yes | python3 -m tinytuya scan 2>&1 | tee -a $FILENAME

LOGINF "Now running the TinyTuya Wizard Devices..."
yes | python3 -m tinytuya wizard | tee -a $FILENAME

LOGINF "Converting Logfile..."
sed -i 's//\n/g' $FILENAME

if [ -e $LBPCONFIG/$pluginname/devices.json ]; then
	LOGOK "Seems that we were successfull. Found at least one device."
else
	LOGERR "Cannot not find any devices. Check credentials, Keys, etc."
fi

LOGEND "TinyTuya Wizard finished."
