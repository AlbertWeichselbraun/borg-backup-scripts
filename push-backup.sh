#!/bin/bash

#
# Perform a push backup of the local host with borgbackup
# author: Albert Weichselbraun
#

echo "$*"
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

BORG_OPTS=("create" "--stats" "--compression" "zstd,9" "--exclude-caches" "--progress")
BORG_REPOSITORY=$1
shift
HOST=$(hostname -f)
DATE=$(date --iso-8601)

# create exclude parameter
while getopts x: opt 
do
    case $opt in
    x) if [ ! -f "$OPTARG" ]; then
          echo "Cannot find exclude file at $OPTARG"
          exit 1
       fi

       while read -r pattern; do
          BORG_OPTS+=("--exclude")
          BORG_OPTS+=("$pattern")
       done < <(sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$OPTARG")
       ;;
    ?) help
       ;;
    esac
done;
shift $((OPTIND-1))

BORG_OPTS+=("$BORG_REPOSITORY::$HOST.$DATE" $@)

echo "Creating backup $HOST.$DATE."
borg "${BORG_OPTS[@]}"

# return the borg exit code
exit $? 
