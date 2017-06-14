#!/bin/bash
#
# This script will setup vnc server on RHEL6/RHEL7 remote machine.
#

DISTRO_VERSION=$(grep -o "[0-9]*" /etc/redhat-release | head -1)

grep -q <USERNAME> /etc/passwd
if [ $? -ne 0 ]; then
	useradd <USERNAME>
fi


if [ $DISTRO_VERSION = "6" ]; then
	yum groupinstall -y Desktop
	yum install -y tigervnc-server

	echo "VNCSERVERS=\"1:<USERNAME>\"
	VNCSERVERARGS[1]=\"-geometry 1024x768\"" >> /etc/sysconfig/vncservers

	/sbin/service vncserver start
	/sbin/service vncserver stop
	/sbin/chkconfig vncserver on
	/sbin/service iptables stop

	su - <USERNAME> -c "printf \"<PASSWD>\n<PASSWD>\n\" | vncpasswd"

	/sbin/service vncserver start
	/sbin/service vncserver stop

	su - <USERNAME> -c "printf \"<PASSWD>\n<PASSWD>\n\n\" | vncpasswd"

	/sbin/service vncserver start
	echo -e "\n\nConnect to vnc server using '<REMOTE_MACHINE_IP>:1' and password '<PASSWD>'."
elif [ $DISTRO_VERSION = "7" ]; then
	yum groupinstall -y 'Server with GUI'
	yum install -y tigervnc-server

	sed -i "s|<USER>|<USERNAME>|g" /lib/systemd/system/vncserver@.service
	systemctl daemon-reload
	systemctl enable vncserver@:1.service

	su - <USERNAME> -c "printf \"<PASSWD>\n<PASSWD>\n\" | vncpasswd"

	systemctl start vncserver@:1.service
	echo -e "\n\nConnect to vnc server using '<REMOTE_MACHINE_IP>:1' and password '<PASSWD>'."
else
	echo "Error: Unknown distro: '$DISTRO_VERSION'" 1>&2
fi
