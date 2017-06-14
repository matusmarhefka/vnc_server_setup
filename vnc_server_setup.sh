#!/bin/bash
#
# This script will setup vnc server on RHEL6/RHEL7 remote machine.
#

BACKEND_TEMPLATE="remote_vnc_backend_template.sh"
BACKEND="remote_vnc_backend.sh"

if [ ! -f $BACKEND_TEMPLATE ]; then
	echo "Error: vnc setup script '$BACKEND_TEMPLATE' not found!" 1>&2
	exit 1
fi
if [ $# -ne 3 ]; then
	echo -e "Usage: $0 USER PASSWD REMOTE_MACHINE_IP\n"
	echo "USER:"
	echo "  User who will run vnc server (should be other than root)."
	echo "  If user USER does not exist it will be created by useradd."
	echo "PASSWD:"
	echo "  Password for logging into the vnc server on the remote machine"
	echo "  under user USER."
	echo "REMOTE_MACHINE_IP:"
	echo "  Machine on which vnc server will be installed and set up."
	exit 0
fi
USERNAME=$1
PASSWD=$2
REMOTE_MACHINE_IP=$3

cp $BACKEND_TEMPLATE $BACKEND
sed -i "s|<USERNAME>|$USERNAME|g" $BACKEND
sed -i "s|<PASSWD>|$PASSWD|g" $BACKEND
sed -i "s|<REMOTE_MACHINE_IP>|$REMOTE_MACHINE_IP|g" $BACKEND

read -p "User with admin rights to '$REMOTE_MACHINE_IP' machine (preferably root): " REMOTE_USER
echo "### Copying vnc setup script to $REMOTE_USER@$REMOTE_MACHINE_IP:"
scp $BACKEND $REMOTE_USER@$REMOTE_MACHINE_IP:~/
echo "### Running vnc setup script on $REMOTE_USER@$REMOTE_MACHINE_IP:"
ssh -t $REMOTE_USER@$REMOTE_MACHINE_IP "chmod +x $BACKEND && ./$BACKEND"

rm -f $BACKEND
