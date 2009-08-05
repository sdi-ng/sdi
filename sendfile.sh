# the parser API to send files to host
sendfile()
{
    # the fifo
    FILEFIFO="$FIFODIR/sendfile.fifo"
    FILEBLOCK="$TMPDIR/sendfile.blocked"

    # first secure the options are empty
    unset LIMIT FILE DESTINATION

    # arguments parser
    TEMP=$(getopt -o b:l:f:d: --long --block:--limit:--file:--dest: \
         -n 'example.bash' -- "$@")

    if [ $? != 0 ] ; then echo "Error running sendfile." >&2 ; return 1 ; fi

    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -b|--block) BLOCK=$2
                        shift 2 ;;
            -l|--limit) LIMIT=$2
                        shift 2 ;;
            -f|--file)  FILE=$2
                        shift 2 ;;
            -d|--dest)  DESTINATION=$2
                        shift 2 ;;
            --) shift ; break ;;
            *) echo "Internal error on sendfile." ; return 1 ;;
        esac
    done
    HOST=$1
    # end parser

    # block host to receive files
    test ! -z "$BLOCK" && echo "$BLOCK" >> $FILEBLOCK && return 0

    # check the arguments data
    test -z "$LIMIT" && LIMIT=0
    test -z "$FILE"  && exit 1
    test -z "$DESTINATION" && exit 1
    test -z "$HOST" && exit 1

    echo "$HOST $FILE $DESTINATION $LIMIT" >> $FILEFIFO
}
