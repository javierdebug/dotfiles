rsync -avh --delete /media/javierd/JV/ /media/javierd/Storage_Backup/Backups/BackupUSB && curl -d "backup JV to HDD finished..." ntfy.sh/jv || curl -d "Error: HDD folder not available" ntfy.sh/jv
