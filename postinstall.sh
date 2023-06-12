#!/bin/bash
#
# Exit code must be 0 if executed successfull. 
# Exit code 1 gives a warning but continues installation.
# Exit code 2 cancels installation.
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Will be executed as user "root".
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# You can use all vars from /etc/environment in this script.
#
# We add 5 additional arguments when executing this script:
# command <TEMPFOLDER> <NAME> <FOLDER> <VERSION> <BASEFOLDER>
#
# For logging, print to STDOUT. You can use the following tags for showing
# different colorized information during plugin installation:
#
# <OK> This was ok!"
# <INFO> This is just for your information."
# <WARNING> This is a warning!"
# <ERROR> This is an error!"
# <FAIL> This is a fail!"

# To use important variables from command line use the following code:
COMMAND=$0    # Zero argument is shell command
PTEMPDIR=$1   # First argument is temp folder during install
PSHNAME=$2    # Second argument is Plugin-Name for scipts etc.
PDIR=$3       # Third argument is Plugin installation folder
PVERSION=$4   # Forth argument is Plugin version
#LBHOMEDIR=$5 # Comes from /etc/environment now. Fifth argument is
              # Base folder of LoxBerry
PTEMPPATH=$6  # Sixth argument is full temp path during install (see also $1)

# Combine them with /etc/environment
PCGI=$LBPCGI/$PDIR
PHTML=$LBPHTML/$PDIR
PTEMPL=$LBPTEMPL/$PDIR
PDATA=$LBPDATA/$PDIR
PLOG=$LBPLOG/$PDIR # Note! This is stored on a Ramdisk now!
PCONFIG=$LBPCONFIG/$PDIR
PSBIN=$LBPSBIN/$PDIR
PBIN=$LBPBIN/$PDIR

echo "<INFO> Installing TinyTuya"
cd $PDATA
git clone https://github.com/mschlenstedt/tinytuya -b mqtt

echo "<INFO> Creating Symlinks"
rm $PDATA/tinytuya/server/mqtt/mqtt.json
ln -s $PDATA/tinytuya/server/server.py $PBIN/server.py
ln -s $PDATA/tinytuya/server/mqtt/mqtt_gateway.py $PBIN/mqtt_gateway.py
ln -s $PDATA/tinytuya/server/mqtt/mqtt.json $PCONFIG/mqtt.json
ln -s $PDATA/tinytuya/server/devices.json $PCONFIG/devices.json
ln -s $PDATA/tinytuya/server/tinytuya.json $PCONFIG/tinytuya.json
ln -s $PDATA/tinytuya/server/snapshot.json $PCONFIG/snapshot.json

# Exit with Status 0
exit 0
