#!/bin/bash

# borgbackup local backup script
# author: Albert Weichselbraun

if [ "$#" -lt 2 ]; then
    PROG=$(basename "$0")
    echo "Usage: $PROG REPOSITORY EXCLUDE_PATTERN [EXCLUDE_PATTERN] ..."
    echo 
    echo "  REPOSITORY       the local or remote repository path"
    echo "  EXCLUDE_PATTERN  name of the exclude pattern(s) to use"
    echo 
    echo "Examples:"
    echo "  1. Push a backup to the repository on 'server.org' applying the 'client-full'"
    echo "     and 'client-data' exclude patterns."
    echo "        $PROG backup-user@server.org:/backup/borg \\"
    echo "              /etc/borg/client-full.cfg /etc/borg/client-data.cfg"
    echo
    echo "  2. Push a backup to a local repository using the 'client-full' exclude patterns."
    echo "        $PROG /backup/myborg-repo /etc/borg/client-full.cfg"
    exit 0
fi

BORG_OPTS="--stats --compression zstd,9 --exclude-caches --noatime --progress"
BORG_REPOSITORY=$1
HOST=$(hostname -f)
DATE=$(date --iso-8601)

# compute BORG_EXCLUDE
shift
for exclude_profile do
    if [ ! -f "$exclude_profile" ]; then
        echo "Cannot find exclude file at $exclude_profile"
        exit 1
    fi
    BORG_EXCLUDE="$BORG_EXCLUDE --exclude-file $exclude_profile"
done;

echo "Creating backup $HOST.$DATE."
borg create "$BORG_OPTS"  \
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
   "$BORG_EXCLUDE" \
   "$BORG_REPOSITORY::$HOST.$DATE" /
