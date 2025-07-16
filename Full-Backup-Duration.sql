-- Last full backup Duration
SELECT TOP 1
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS duration_seconds,
    DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS duration_minutes,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'My_db'
  AND bs.type = 'D'  -- 'D' stands for full database backup
ORDER BY bs.backup_finish_date DESC;
