#!/bin/bash
#

# ARG_POSITIONAL_SINGLE([hostname],[The IP address or hostname of the target machine])
# ARG_OPTIONAL_SINGLE([user],[u],[The username for running tests. Should be somebody else than root, and it will be created if needed],[test])
# ARG_OPTIONAL_SINGLE([password],[p],[The password of the user who runs tests],[redhat])
# ARG_OPTIONAL_SINGLE([provision],[],[A script that should be ran on the target machine under root])
# ARG_HELP([This script will setup vnc server on RHEL6/RHEL7 remote machine.])
# ARG_OPTION_STACKING([none])
# DEFINE_SCRIPT_DIR([])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.5.1 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info

die()
{
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}


# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_user="test"
_arg_password="redhat"
_arg_provision=

print_help ()
{
	printf "%s\n" "This script will setup vnc server on RHEL6/RHEL7 remote machine."
	printf 'Usage: %s [-u|--user <arg>] [-p|--password <arg>] [--provision <arg>] [-h|--help] <hostname>\n' "$0"
	printf "\t%s\n" "<hostname>: The IP address or hostname of the target machine"
	printf "\t%s\n" "-u,--user: The username for running tests. Should be somebody else than root, and it will be created if needed (default: '"test"')"
	printf "\t%s\n" "-p,--password: The password of the user who runs tests (default: '"redhat"')"
	printf "\t%s\n" "--provision: A script that should be ran on the target machine under root (no default)"
	printf "\t%s\n" "-h,--help: Prints help"
	echo
	echo 'Short options stacking mode is not supported.'
}

parse_commandline ()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-u|--user)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_user="$2"
				shift
				;;
			--user=*)
				_arg_user="${_key##--user=}"
				;;
			-p|--password)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_password="$2"
				shift
				;;
			--password=*)
				_arg_password="${_key##--password=}"
				;;
			--provision)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_provision="$2"
				shift
				;;
			--provision=*)
				_arg_provision="${_key##--provision=}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			*)
				_positionals+=("$1")
				;;
		esac
		shift
	done
}


handle_passed_args_count ()
{
	_required_args_string="'hostname'"
	test ${#_positionals[@]} -ge 1 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${#_positionals[@]}." 1
	test ${#_positionals[@]} -le 1 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${#_positionals[@]} (the last one was: '${_positionals[*]: -1}')." 1
}

assign_positional_args ()
{
	_positional_names=('_arg_hostname' )

	for (( ii = 0; ii < ${#_positionals[@]}; ii++))
	do
		eval "${_positional_names[ii]}=\${_positionals[ii]}" || die "Error during argument parsing, possibly an Argbash bug." 1
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args

# OTHER STUFF GENERATED BY Argbash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || die "Couldn't determine the script's running directory, which probably matters, bailing out" 2

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash


BACKEND_TEMPLATE="$script_dir/remote_vnc_backend_template.sh"
BACKEND="remote_vnc_backend.sh"

if [ ! -f $BACKEND_TEMPLATE ]; then
	echo "Error: vnc setup script '$BACKEND_TEMPLATE' not found!" 1>&2
	exit 1
fi

USERNAME="$_arg_user"
PASSWD="$_arg_password"
REMOTE_MACHINE_IP="$_arg_hostname"
PROVISION="$_arg_provision"

cat "$BACKEND_TEMPLATE" \
    | sed "s|<USERNAME>|$USERNAME|g" \
    | sed "s|<PASSWD>|$PASSWD|g" \
    | sed "s|<REMOTE_MACHINE_IP>|$REMOTE_MACHINE_IP|g" \
    > "$BACKEND"

test -f "$PROVISION" && cat "$PROVISION" >> "$BACKEND"

read -p "User with admin rights to '$REMOTE_MACHINE_IP' machine [root]: " REMOTE_USER
REMOTE_USER="${REMOTE_USER:-root}"

NO_KNOWN_HOSTS_WARNING=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

echo "### Copying vnc setup script to $REMOTE_USER@$REMOTE_MACHINE_IP:"
scp "${NO_KNOWN_HOSTS_WARNING[@]}" "$BACKEND" "$REMOTE_USER@$REMOTE_MACHINE_IP:"
echo "### Running vnc setup script on $REMOTE_USER@$REMOTE_MACHINE_IP:"
ssh "${NO_KNOWN_HOSTS_WARNING[@]}" -t "$REMOTE_USER@$REMOTE_MACHINE_IP" "chmod +x $BACKEND && ./$BACKEND"

if test $? = 0
then
    # SecurityTypes=VncAuth is there because of the vncviewer TLS-related bug that causes it to crash.
    echo -e "\n\nConnect to vnc server using 'vncviewer SecurityTypes=VncAuth $REMOTE_MACHINE_IP:1' and password '$PASSWD'."
else
    echo "Something went wrong on the remote server."
fi

rm -f "$BACKEND"

# ] <-- needed because of Argbash
