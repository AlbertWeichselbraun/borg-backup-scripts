#!/bin/bash

#
# Perform a pull backup of the remote host using borgbackup + socat
# author: Albert Weichselbraun
#

PROG=$(basename "$0")

help() {
    echo "Usage: $PROG [USER@]HOST REPOSITORY [-x EXCLUDE_PATTERN_FILE] PATH"
    echo 
    echo "  [USER@]HOST           host and optional username of the host to backup"
    echo "  REPOSITORY            the local or remote repository path"
    echo "  EXCLUDE_PATTERN_FILE  optional files containing exclude pattern(s) to apply"
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


BORG_OPTS="--stats --compression zstd,9 --exclude-caches --noatime --progress"
HOST=$1
BORG_REPOSITORY=$2
shift 2
BORG_SOCKET=/root/.borg-$(uuidgen --random).sock
DATE=$(date --iso-8601)

# create exclude parameter
exclude=()
while getopts x: opt 
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
    ?) help
       ;;
    esac
done;
shift $((OPTIND-1))

echo "Open local socket to borg serve..."
killall -q socat
socat UNIX-LISTEN:"$BORG_SOCKET",fork EXEC:"/usr/bin/borg serve --append-only --restrict-to-path $BORG_REPOSITORY" &
echo "Waiting until the socket becomes available..."
while [ ! -S "$BORG_SOCKET" ]; do sleep 1; done


echo "Connecting the local socket to the remote host"
ssh -R "$BORG_SOCKET":"$BORG_SOCKET" "$HOST" \
   BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes \
   /usr/bin/borg create $BORG_OPTS \
      --rsh \"sh -c \'exec socat STDIO UNIX-CONNECT:\'$BORG_SOCKET\" \
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
