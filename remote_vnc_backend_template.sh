#!/bin/bash
#
# This script will setup vnc server on RHEL 6/7/8/9 remote machine.
#

DISTRO_VERSION=$(grep -o "[0-9]*" /etc/redhat-release | head -1)
DISTRO_FULL_VERSION=$(grep -o "[0-9]\+\.[0-9]\+" /etc/redhat-release)


grep -q <USERNAME> /etc/passwd
if [ $? -ne 0 ]; then
	useradd -m -G wheel <USERNAME>
fi


create_vnc_password() {
	# to force any password, we create it manually
	su - <USERNAME> -c "mkdir -p ~/.vnc && echo \"<PASSWD>\" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"
}


create_vncserver_unit_file () {
	if [ -f /lib/systemd/system/vncserver@.service ] ; then
		cp /{lib,etc}/systemd/system/vncserver@.service
		sed -i "s|<USER>|<USERNAME>|g" /etc/systemd/system/vncserver@.service
	elif [ -f /usr/lib/systemd/system/vncserver@.service ] ; then
		cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service
		sed -i "s|<USER>|<USERNAME>|g" /etc/systemd/system/vncserver@.service
	else
		cp /usr/lib/systemd/user/vncserver@.service /etc/systemd/system/vncserver@.service
		sed -i '/\[Service\]/a User=<USERNAME>' /etc/systemd/system/vncserver@.service
	fi
}


setup_vncserver_upstart() {
	yum install -y tigervnc-server
	echo "VNCSERVERS=\"1:<USERNAME>\"
	VNCSERVERARGS[1]=\"-geometry 1024x768\"" >> /etc/sysconfig/vncservers

	/sbin/chkconfig vncserver on
	/sbin/service iptables stop

	create_vnc_password
}


setup_vncserver_systemd() {
	yum install -y tigervnc-server bc

	if (( $(echo "$DISTRO_FULL_VERSION >= 8.3" | bc -l) )); then
		# Since 8.3 version vnc needs to be configured differently.
		echo "session=gnome" >> /etc/tigervnc/vncserver-config-defaults
		echo ":1=<USERNAME>" >> /etc/tigervnc/vncserver.users
	else
		create_vncserver_unit_file
		systemctl daemon-reload
	fi

	systemctl enable vncserver@:1.service
	create_vnc_password
}


post_setup_vncserver_rhel8() {
	if (( $(echo "$DISTRO_FULL_VERSION >= 8.3" | bc -l) )); then
		systemctl start vncserver@:1.service
	else
		setenforce 0
		systemctl start vncserver@:1.service
		# wait to be sure that the configfile is created
		timeout 1m bash -c "while [ ! -f /home/<USERNAME>/.vnc/xstartup ]; do sleep 1; done"
		if [ $? -eq 0 ]; then
			# maybe add Environment=XDG_SESSION_TYPE=x11 under [Service]
			sed -i 's|^/etc/X11/xinit/xinitrc|# \0\nexport XDG_SESSION_TYPE=x11\nexport DISPLAY=:1\ngnome-session|' "/home/<USERNAME>/.vnc/xstartup"
			systemctl restart vncserver@:1.service
		fi
	fi
}


if [ "$DISTRO_VERSION" = "6" ]; then
	yum groupinstall -y Desktop || exit 1

	setup_vncserver_upstart

	/sbin/service vncserver start
elif [ "$DISTRO_VERSION" = "7" ]; then
	yum groupinstall -y 'Server with GUI' || exit 1

	setup_vncserver_systemd

	systemctl start vncserver@:1.service
elif [ "$DISTRO_VERSION" = "8" ]; then
	yum groupinstall -y Workstation
	if [ $? -ne 0 ]; then
		# If Workstation group is not available install 'Server with GUI'
		yum groupinstall -y 'Server with GUI' || exit 1
	fi

	setup_vncserver_systemd

	post_setup_vncserver_rhel8
elif [ "$DISTRO_VERSION" = "9" ]; then
	yum groupinstall -y Workstation
	if [ $? -ne 0 ]; then
		# If Workstation group is not available install 'Server with GUI'
		yum groupinstall -y 'Server with GUI' || exit 1
	fi

	setup_vncserver_systemd

	systemctl start vncserver@:1.service
else
	echo "Error: Unknown distro: '$DISTRO_VERSION'" 1>&2
	exit 1
fi

gpasswd -a "<USERNAME>" wheel
