# This program will receive the commands to be executed on the host
# through the standard input. The standard output of this program
# will be send to the receiver via pipeline.

sdisend()
{
    # Check if the host was given
    if test $# != 1 ; then
        echo "ERROR: no host given to the sender"
        exit 1
    fi

    # Get the host name
    HOST="$1"

    # Try to load the configuration file
    eval $($PREFIX/configsdiparser.py $SENDDIR/ssh.conf all)
    if test $? != 0; then
        echo "ERROR: failed to load the ssh sender configuration file"
        exit 1
    fi

    # Open the ssh tunnel
    ssh $SSHOPTS -p $SSHPORT -l $SDIUSER $HOST "bash -s" 2>&1
}
