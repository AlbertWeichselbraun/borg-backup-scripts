# BorgBackup scripts for push and pull backups

 1. [BorgBackup push backups](borgbackup-push-backups) ... Backups that are triggered by the client
 2. [BorgBackup pull backups](borgbackup-pull-backups) ... Triggering backups from the backup server
 3. [Scheduling daily backups](scheduling-daily-backups) ... Scheduling daily backups that even work across reboots

## BorgBackup push backups

BorgBackup push backups are initiated by the client which pushes the backup to the given REPOSITORY.

The script backups the whole file system with the 
exception of the patterns excluded in the `EXCLUDE_PATTERN_FILES` (please refer to `man borg-pattners` for a
specification of the exclude patterns supported by borg.

```bash
Usage: push-backup.sh REPOSITORY EXCLUDE_PATTERN [EXCLUDE_PATTERN] ...

  REPOSITORY       the local or remote repository path
  EXCLUDE_PATTERN  name of the exclude pattern(s) to use

Examples:
  1. Push a backup to the repository on `server.org` applying the `client-full`
     and `client-data` exclude patterns.
       push-backup.sh backup-user@server.org:/backup/borg \
           /etc/borg/client-full.cfg /etc/borg/client-data.cfg

  2. Push a backup to a local repository using the `client-full` exclude patterns.
       push-backup.sh /backup/myborg-repo /etc/borg/client-full.cfg
```

## BorgBackup pull backups

BorgBackup pulls backups from a remote machine.

### Requirements:
- BorgBackup and `socat` must be installed on both machines


## Scheduling daily backups

We use systemd-timers for scheduling daily backups, since they will trigger
backups even if the clients misses the scheduled time (e.g., due to a shut down, 
network outage or hibernation).

 1. copy the backup scripts to `/usr/local/bin`.
 2. copy the systemd files from the repository to `/etc/systemd/system`
 3. reload the systemd configuration and activate the time:
    ```bash
    sudo systemctl enable borgbackup.timer
    sudo systemctl start borgbackup.timer
    ```
 4. verify that the timer has been started
    ```bash
    sudo systemctl list-timers
    ```

