#!/bin/bash
#
# This script will setup vnc server on RHEL6/RHEL7 remote machine.
#

DISTRO_VERSION=$(grep -o "[0-9]*" /etc/redhat-release | head -1)

grep -q <USERNAME> /etc/passwd
if [ $? -ne 0 ]; then
	useradd -m <USERNAME>
fi


create_vnc_password() {
	# to force any password, we create it manually
	su - <USERNAME> -c "mkdir -p ~/.vnc && echo \"<PASSWD>\" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"
}


create_vncserver_unit_file () {
	cp /{lib,etc}/systemd/system/vncserver@.service
	sed -i "s|<USER>|<USERNAME>|g" /etc/systemd/system/vncserver@.service
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
	yum install -y tigervnc-server

	create_vncserver_unit_file
	systemctl daemon-reload
	systemctl enable vncserver@:1.service

	create_vnc_password
}


post_setup_vncserver_rhel8() {
	setenforce 0
	systemctl start vncserver@:1.service
	# wait to be sure that the configfile is created
	sleep 1
	# maybe add Environment=XDG_SESSION_TYPE=x11 under [Service]
	sed -i 's|^/etc/X11/xinit/xinitrc|# \0\nexport XDG_SESSION_TYPE=x11\nexport DISPLAY=:1\ngnome-session|' "/home/<USERNAME>/.vnc/xstartup"
	systemctl restart vncserver@:1.service
}


if [ $DISTRO_VERSION = "6" ]; then
	yum groupinstall -y Desktop
	yum install -y ansible

	setup_vncserver_upstart

	/sbin/service vncserver start
elif [ $DISTRO_VERSION = "7" ]; then
	yum groupinstall -y 'Server with GUI'
	yum install -y ansible

	setup_vncserver_systemd

	systemctl start vncserver@:1.service
elif [ $DISTRO_VERSION = "8" ]; then
	yum install -y dbus-x11 \
		gnome-session gnome-shell gnome-terminal \
		firefox python3-{pyyaml,jinja2,markupsafe,bcrypt,paramiko,pynacl,pyasn1,pip}

	# ansible can't be installed by dnf (yet)
	pip3 install ansible

	setup_vncserver_systemd

	post_setup_vncserver_rhel8
else
	echo "Error: Unknown distro: '$DISTRO_VERSION'" 1>&2
	exit 1
fi

gpasswd -a "<USERNAME> wheel
