#!/bin/bash

# borgbackup local backup script
# author: Albert Weichselbraun

if [ "$#" -lt 2 ]; then
    echo "Usage: $(basename $0) REPOSITORY EXCLUDE_PATTERN [EXCLUDE_PATTERN] ..."
    echo 
    echo "  REPOSITORY       the local or remote repository path"
    echo "  EXCLUDE_PATTERN  name of the exclude pattern(s) to use"
    echo 
    echo "Examples:"
    echo "  $(basename $0) ssh://server.org/backup/borg /etc/borg/client-full.cfg /etc/borg/client-data.cfg"
    echo "  $(basename $0) /backup/myborg-repo /etc/borg/client-full.cfg"
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
