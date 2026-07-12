#!/bin/bash

packageurl="https://pypi.org/pypi/tinytuya/json"
pluginname=$(perl -e 'use LoxBerry::System; print $lbpplugindir; exit;')
oldversion=$(pip3 show tinytuya 2>/dev/null | grep Version: | cut -d: -f 2 | sed 's/[[:blank:]]//g')

# print out versions
if [[ $1 == "current" ]]; then
	echo -n $oldversion
	exit 0
fi
if [[ $1 == "available" ]]; then
	newversion=$(curl -s --max-time 15 $packageurl | jq -r '.info.version')
	if [[ $newversion == "null" ]]; then
		newversion=""
	fi
	echo -n $newversion
	exit 0
fi

if [ "$UID" -ne 0 ]; then
	echo "This script has to be run as root."
	exit 1
fi

# Logging
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=$pluginname
NAME=upgrade
LOGDIR=${LBPLOG}/${PACKAGE}
LOGSTART "TinyTuya upgrade started."

# Install
LOGINF "Installing TinyTuya via pip3..."

yes | python3 -m pip install --upgrade pip >> $FILENAME 2>&1
yes | python3 -m pip install --upgrade tinytuya >> $FILENAME 2>&1

# End
newversion=$(pip3 show tinytuya 2>/dev/null | grep Version: | cut -d: -f 2 | sed 's/[[:blank:]]//g')
if [[ -n $newversion && $newversion != $oldversion ]]; then
	LOGOK "Upgraded TinyTuya from $oldversion to $newversion"
else
	LOGINF "TinyTuya version now: $newversion (before: $oldversion)"
fi
LOGEND "TinyTuya upgrade finished."

chown loxberry:loxberry $FILENAME

exit 0
