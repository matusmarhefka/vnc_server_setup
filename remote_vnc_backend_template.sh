#!/bin/bash
#
# This script will setup vnc server on RHEL6/RHEL7 remote machine.
#

DISTRO_VERSION=$(grep -o "[0-9]*" /etc/redhat-release | head -1)

grep -q <USERNAME> /etc/passwd
if [ $? -ne 0 ]; then
	useradd -m <USERNAME>
fi


if [ $DISTRO_VERSION = "6" ]; then
	yum groupinstall -y Desktop
	yum install -y tigervnc-server

	echo "VNCSERVERS=\"1:<USERNAME>\"
	VNCSERVERARGS[1]=\"-geometry 1024x768\"" >> /etc/sysconfig/vncservers

	/sbin/chkconfig vncserver on
	/sbin/service iptables stop

	# to force any password, we create it manually
	su - <USERNAME> -c "mkdir -p ~/.vnc && echo \"<PASSWD>\" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"

	/sbin/service vncserver start
elif [ $DISTRO_VERSION = "7" ]; then
	yum groupinstall -y 'Server with GUI'
	yum install -y tigervnc-server

	cp /{lib,etc}/systemd/system/vncserver@.service
	sed -i "s|<USER>|<USERNAME>|g" /etc/systemd/system/vncserver@.service
	systemctl daemon-reload
	systemctl enable vncserver@:1.service
	# to force any password, we create it manually
	su - <USERNAME> -c "mkdir -p ~/.vnc && echo \"<PASSWD>\" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"

	systemctl start vncserver@:1.service
else
	echo "Error: Unknown distro: '$DISTRO_VERSION'" 1>&2
	exit 1
fi
