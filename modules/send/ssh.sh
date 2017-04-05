

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

    if [ ! -e $SENDDIR'/ssh.conf' ]; then
        echo "ERROR: The $SENDDIR/ssh.conf  file does not exist or can not be accessed (ssh.sh)"
        exit 1
    fi

    source $SENDDIR'/ssh.conf'
    
    # Open the ssh tunnel
    ssh $SSHOPTS -p $SSHPORT -l $SDIUSER $HOST "bash -s" 2>&1
}
