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

# Update the TinyTuya server files (server.py, mqtt_gateway.py, web UI) too.
# They come from the git clone in $LBPDATA and would otherwise stay on the
# state of the last plugin update, drifting apart from the pip module.
LOGINF "Updating TinyTuya server files from git..."
DATADIR="$LBPDATA/$pluginname"
CONFDIR="$LBPCONFIG/$pluginname"
TMPCLONE=$(mktemp -d /tmp/tinytuya_clone.XXXXXX)
chown loxberry:loxberry "$TMPCLONE"
# Clone to a temp dir first: if the clone fails (no network), the existing
# server files stay untouched. Clone as loxberry for consistent ownership.
if su loxberry -c "git clone -q https://github.com/jasonacox/tinytuya.git '$TMPCLONE/tinytuya'" >> $FILENAME 2>&1; then
	rm -rf "$DATADIR"
	mv "$TMPCLONE/tinytuya" "$DATADIR"
	# Recreate the config symlinks (same as postinstall.sh). mqtt.json is
	# tracked in the upstream repo, so the fresh clone contains a real file
	# that must be replaced by the symlink again.
	su loxberry -c "
		rm -f '$DATADIR/server/mqtt/mqtt.json'
		ln -sf '$CONFDIR/mqtt.json' '$DATADIR/server/mqtt/mqtt.json'
		ln -sf '$CONFDIR/devices.json' '$DATADIR/server/devices.json'
		ln -sf '$CONFDIR/tinytuya.json' '$DATADIR/server/tinytuya.json'
		ln -sf '$CONFDIR/snapshot.json' '$DATADIR/server/snapshot.json'
	"
	LOGOK "TinyTuya server files updated."
else
	LOGERR "Could not clone TinyTuya repository - keeping existing server files."
fi
rm -rf "$TMPCLONE"

# End
newversion=$(pip3 show tinytuya 2>/dev/null | grep Version: | cut -d: -f 2 | sed 's/[[:blank:]]//g')
if [[ -n $newversion && $newversion != $oldversion ]]; then
	LOGOK "Upgraded TinyTuya from $oldversion to $newversion"
else
	LOGINF "TinyTuya version now: $newversion (before: $oldversion)"
fi

# Restart the bridge so the new module and server files are actually used -
# unless the bridge was manually stopped via the WebUI.
if [ -e "$CONFDIR/bridge_stopped.cfg" ]; then
	LOGINF "bridge_stopped.cfg set - bridge stays stopped."
else
	LOGINF "Restarting bridge to activate the new version..."
	su loxberry --preserve-environment -c "$LBPBIN/$pluginname/watchdog.pl --action=restart" >> $FILENAME 2>&1
	LOGOK "Bridge restart triggered."
fi

LOGEND "TinyTuya upgrade finished."

chown loxberry:loxberry $FILENAME

exit 0
