WITH LatestFullBackup AS (
    SELECT
        database_name,
        MAX(backup_finish_date) AS latest_finish
    FROM msdb.dbo.backupset
    WHERE type = 'D'
      AND database_name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution')
    GROUP BY database_name
),
BackupDetails AS (
    SELECT
        bs.database_name,
        bs.backup_set_id,
        bs.backup_start_date,
        bs.backup_finish_date,
        DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS duration_minutes,
        CEILING(bs.backup_size / 1024.0 / 1024.0 / 1024.0) AS total_backup_size_gb,
        CEILING(bs.compressed_backup_size / 1024.0 / 1024.0 / 1024.0) AS total_compressed_size_gb
    FROM msdb.dbo.backupset bs
    JOIN LatestFullBackup lfb
      ON bs.database_name = lfb.database_name
     AND bs.backup_finish_date = lfb.latest_finish
    WHERE bs.type = 'D'
),
BackupFiles AS (
    SELECT
        bmf.media_set_id,
        STRING_AGG(bmf.physical_device_name, ', ') AS backup_files
    FROM msdb.dbo.backupmediafamily bmf
    GROUP BY bmf.media_set_id
)
SELECT
    bd.database_name,
    bd.backup_start_date,
    bd.backup_finish_date,
    bd.duration_minutes,
    bd.total_backup_size_gb,
    bd.total_compressed_size_gb,
    bf.backup_files
FROM BackupDetails bd
JOIN msdb.dbo.backupset bs ON bd.backup_set_id = bs.backup_set_id
JOIN BackupFiles bf ON bs.media_set_id = bf.media_set_id;
