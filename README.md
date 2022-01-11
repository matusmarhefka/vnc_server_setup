# vnc_server_setup
Setup vnc server on RHEL 6/7/8/9 remote machine.

# Example usage

For best experience, make sure that your SSH keys are accepted to authenticate as `root` on the remote machine.

Assume `192.168.2.100` is a remote machine on which we have a user who can
install packages and add other users (`root` in the example below):

```sh
$ ./vnc_server_setup.sh 192.168.2.100
User with admin rights to '192.168.2.100' machine [root]:
### Copying vnc setup script to root@192.168.2.100:
root@192.168.2.100's password:
### Running vnc setup script on root@192.168.2.100:
root@192.168.2.100's password:
...
Connection to 192.168.2.100 closed.

Connect to vnc server using 'vncviewer SecurityTypes=VncAuth 192.168.2.100:1' and password 'redhat'.
```

Now you can use vnc client to connect to the remote machine (for example TigerVNC Viewer).

If it doesn't work (e.g. you get a black screen), rebooting the remote host may help.
