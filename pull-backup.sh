#!/bin/bash

#
# Perform a pull backup of the remote host using borgbackup + socat
# author: Albert Weichselbraun
#

PROG=$(basename "$0")
BIN_DIR="/usr/bin"
BORG_OPTS="--stats --compression zstd,9 --exclude-caches --progress"
SOCKET_DIR=$HOME
BORG_SOCKET=.borg-$(uuidgen --random).sock
DATE=$(date --iso-8601)

help() {
    echo "Usage: $PROG [USER@]HOST REPOSITORY [-s REMOTE_SOCKET_DIR] [-b BORG_BINARY_PATH] [-x EXCLUDE_PATTERN_FILE] PATH"
    echo 
    echo "  [USER@]HOST           host and optional username of the host to backup"
    echo "  REPOSITORY            the local or remote repository path"
    echo "  BIN_PATH              optional path of the directory holding the borg and socat binaries (default: ${BIN_DIR})"
    echo "  EXCLUDE_PATTERN_FILE  optional files containing exclude pattern(s) to apply"
    echo "  REMOTE_SOCKET_DIR     optional path to the directory in which the remote socket shell be created (default: ${SOCKET_DIR})"
    echo "  PATH                  paths to backup"
    echo 
    echo "Examples:"
    echo "  1. Pull a backup of '/etc', '/home', '/root', '/usr/local' and"
    echo "     '/var' from 'root@server.org' to the local repository applying"
    echo "     the 'client-full' and 'client-data' exclude patterns:"
    echo "        $PROG root@server.org /backup/myborg-repo \\"
    echo "              -x /etc/borg/client-full.cfg \\"
    echo "              -x /etc/borg/client-data.cfg \\"
    echo "              /etc /home /root /usr/local /var"
    echo
    echo "  2. Pull a backup of '/' from 'root@server.org' to a local"
    echo "     repository using the 'client-full' exclude patterns:"
    echo "        $PROG root@server.org /backup/myborg-repo \\"
    echo "              -x /etc/borg/client-full.cfg /"
    exit 0
}

if [ "$#" -lt 3 ]; then
    help
fi


HOST=$1
BORG_REPOSITORY=$2
shift 2

# create exclude parameter
exclude=()
while getopts b:s:x: opt 
do
    case $opt in
    x) if [ ! -f "$OPTARG" ]; then
          echo "Cannot find exclude file at $OPTARG"
          exit 1
       fi

       while read -r pattern; do
          exclude+=("--exclude \"$pattern\"")
       done < <(sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$OPTARG")
       ;;
    b) BIN_DIR="$OPTARG"
       ;;
    s) SOCKET_DIR="$OPTARG"
       ;;
    ?) help
       ;;
    esac
done;
shift $((OPTIND-1))

echo "Open local socket to borg serve..."
killall -q socat
socat UNIX-LISTEN:"$HOME/$BORG_SOCKET",fork EXEC:"/usr/bin/borg serve --append-only --restrict-to-path $BORG_REPOSITORY" &
echo "Waiting until the socket becomes available..."
while [ ! -S "$HOME/$BORG_SOCKET" ]; do sleep 1; done


echo "Connecting the local socket to the remote host"
ssh -R "$SOCKET_DIR/$BORG_SOCKET":"$HOME/$BORG_SOCKET" "$HOST" \
   BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes \
   $BIN_DIR/borg create $BORG_OPTS \
      --rsh \"sh -c \'exec $BIN_DIR/socat STDIO UNIX-CONNECT:\'$BORG_SOCKET\" \
      --exclude pp:/dev \
      --exclude pp:/lost+found \
      --exclude pp:/mnt \
      --exclude pp:/proc \
      --exclude pp:/run \
      --exclude pp:/snap \
      --exclude pp:/sys \
      --exclude pp:/tmp \
      --exclude pp:/var/cache \
      --exclude pp:/var/crash \
      --exclude pp:/var/lib/apt \
      --exclude pp:/var/lib/docker \
      --exclude pp:/var/lib/flatpak \
      --exclude pp:/var/lib/snapd \
      --exclude pp:/var/lock \
      --exclude pp:/var/log \
      --exclude pp:/var/snap \
      --exclude pp:/var/tmp \
       ${exclude[@]} ssh://hc$BORG_REPOSITORY::$HOST.$DATE $* ';' \ 
   rm -f "$BORG_SOCKET"

killall socat
rm -f "$BORG_SOCKET"
