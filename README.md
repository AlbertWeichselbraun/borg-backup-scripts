# BorgBackup scripts for push and pull backups

## BorgBackup pull backups

BorgBackup push backups are initiated by the client which pushes the backup to the given REPOSITORY.

The script backups the whole file system with the 
exception of the patterns excluded in the `EXCLUDE_PATTERN_FILES` (please refer to `man borg-pattners` for a
specification of the exclude patterns supported by borg.

```bash
Usage: push-backup.sh REPOSITORY EXCLUDE_PATTERN [EXCLUDE_PATTERN] ...

  REPOSITORY       the local or remote repository path
  EXCLUDE_PATTERN  name of the exclude pattern(s) to use

Examples:
  push-backup.sh ssh://server.org/backup/borg /etc/borg/client-full.cfg /etc/borg/client-data.cfg
  push-backup.sh /backup/myborg-repo /etc/borg/client-full.cfg
```

## BorgBackup push backups

BorgBackup pulls backups from a remote machine.

