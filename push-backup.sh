#!/bin/sh

# borgbackup local backup script
# author: Albert Weichselbraun

PROG=$(basename "$0")

help() {
    echo "Usage: $PROG REPOSITORY [-x EXCLUDE_PATTERN_FILE] PATH"
    echo 
    echo "  REPOSITORY            the local or remote repository path"
    echo "  EXCLUDE_PATTERN_FILE  optional files containing exclude pattern(s) to apply"
    echo "  PATH                  paths to backup"
    echo 
    echo "Examples:"
    echo "  1. Push a backup of '/etc', '/home', '/root', '/usr/local' and"
    echo "     '/var' to the repository on 'server.org' applying the"
    echo "     'client-full' and 'client-data' exclude patterns:"
    echo "        $PROG backup-user@server.org:/backup/borg \\"
    echo "              -x /etc/borg/client-full.cfg -x /etc/borg/client-data.cfg \\"
    echo "              /etc /home /root /usr/local /var"
    echo
    echo "  2. Push a backup of '/' to a local repository using the"
    echo "     'client-full' exclude patterns:"
    echo "        $PROG /backup/myborg-repo -x /etc/borg/client-full.cfg /"
    exit 0
}

if [ "$#" -lt 2 ]; then
    help
fi

BORG_OPTS="--stats --compression zstd,9 --exclude-caches --noatime --progress"
BORG_REPOSITORY=$1
shift
HOST=$(hostname -f)
DATE=$(date --iso-8601)
BORG_EXCLUDE_FILE=$(mktemp /tmp/.borg-exclude-XXXXXXXXXX.tmp)

# create exclude file
while getopts x: opt 
do
    case $opt in
    x) if [ ! -f "$OPTARG" ]; then
          echo "Cannot find exclude file at $OPTARG"
          exit 1
       fi
       cat "$OPTARG" >> "$BORG_EXCLUDE_FILE"
       ;;
    ?) help
       ;;
    esac
done;
shift $((OPTIND-1))

echo "Creating backup $HOST.$DATE."
borg create ${BORG_OPTS}  \
   --exclude pp:/dev \
   --exclude pp:/lost+found \
   --exclude pp:/media \
   --exclude pp:/mnt \
   --exclude pp:/proc \
   --exclude pp:/run \
   --exclude pp:/snap \
   --exclude pp:/sys \
   --exclude pp:/tmp \
   --exclude pp:/var/cache \
   --exclude pp:/var/crash \
   --exclude pp:/var/lib/docker \
   --exclude pp:/var/lib/flatpak \
   --exclude pp:/var/lib/snapd \
   --exclude pp:/var/lib/apt \
   --exclude pp:/var/lock \
   --exclude pp:/var/run \
   --exclude pp:/var/log \
   --exclude pp:/var/snap \
   --exclude pp:/var/tmp \
   --exclude-from "$BORG_EXCLUDE_FILE" \
   "$BORG_REPOSITORY::$HOST.$DATE" \
   $*

rm -f "$BORG_EXCLUDE_FILE"
