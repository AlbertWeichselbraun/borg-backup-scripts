# BorgBackup scripts for push and pull backups

**Contents:**
 1. [Push backups](#borgbackup-push-backups) ... Backups that are triggered by the client
 2. [Pull backups](#borgbackup-pull-backups) ... Triggering backups from the backup server
 3. [Automatic backups](#scheduling-daily-backups) ... Scheduling daily backups that even work across reboots

## BorgBackup push backups

BorgBackup push backups are initiated by the client which pushes the backup to the given REPOSITORY.

The script backups the specified paths with the exception of patterns excluded in the `EXCLUDE_PATTERN_FILES` (please refer to `man borg-pattners` for a
specification of the exclude patterns supported by borg).

```
Usage: push-backup.sh REPOSITORY [-x EXCLUDE_PATTERN] PATH

  REPOSITORY            the local or remote repository path
  EXCLUDE_PATTERN_FILE  optional files containing exclude pattern(s) to apply"
  PATH                  paths to backup"

Examples:
  1. Push a backup `/etc`, `/home`, `/root`, `/usr/local` and `/var` to the repository on `server.org` 
     applying the `client-full` and `client-data` exclude patterns:
       push-backup.sh backup-user@server.org:/backup/borg \
           -x /etc/borg/client-full.cfg -x /etc/borg/client-data.cfg \
           /etc /home /root /usr/local /var

  2. Push a backup of `/` to a local repository using the `client-full` exclude patterns:
       push-backup.sh /backup/myborg-repo -x /etc/borg/client-full.cfg /
```

## BorgBackup pull backups

Pull backups are initiated by the backup server rather than the client. 

### Requirements:
- `BorgBackup`, `socat`, `psmisc` and the `uuid-runtime` must be installed on both machines
  ```bash
  apt install borgbackup socat psmisc uuid-runtime
  ``` 

### Usage:
```
Usage: pull-backup.sh [USER@]HOST REPOSITORY [-x EXCLUDE_PATTERN_FILE] PATH

  [USER@]HOST           host and optional username of the host to backup
  REPOSITORY            the local or remote repository path
  BIN_PATH              optional path of the directory holding the borg and socat binaries (default: /usr/bin)"
  EXCLUDE_PATTERN_FILE  optional files containing exclude pattern(s) to apply"
  REMOTE_SOCKET_DIR     optional path to the directory in which the remote socket shell be created (default: /root)"
  PATH                  paths to backup

Examples:
  1. Pull a backup of '/etc', '/home', '/root', '/usr/local' and
     '/var' from 'root@server.org' to the local repository applying
     the 'client-full' and 'client-data' exclude patterns:
        pull-backup.sh root@server.org /backup/myborg-repo \
              -x /etc/borg/client-full.cfg \
              -x /etc/borg/client-data.cfg \
              /etc /home /root /usr/local /var

  2. Pull a backup of '/' from 'root@server.org' to a local
     repository using the 'client-full' exclude patterns:
        pull-backup.sh root@server.org /backup/myborg-repo \
              -x /etc/borg/client-full.cfg /
```

## Scheduling daily backups

We use systemd-timers for scheduling daily backups, since they will trigger
backups even if the clients misses the scheduled time (e.g., due to a shut down, 
network outage or hibernation).

 1. copy the backup scripts to `/usr/local/bin`.
 2. copy the systemd files from the repository to `/etc/systemd/system`
 3. adapt the backup command in `/etc/systemd/system/borgbackup.service`
 4. reload the systemd configuration and activate the time:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable borgbackup.timer
    sudo systemctl start borgbackup.timer
    ```
 5. verify that the timer has been started
    ```bash
    sudo systemctl list-timers
    ```

## Resources
- [BorgBackup](https://www.borgbackup.org/)
- [Setting up scheduled Borg Backups with systemd-timers](https://dextervolkman.com/posts/borg_backups/)
- [archlinux Wiki on systemd/Timers](https://wiki.archlinux.org/index.php/Systemd/Timers)
