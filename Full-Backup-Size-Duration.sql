SELECT
    bs.database_name,
    MAX(bs.backup_start_date) AS backup_start_date,
    MAX(bs.backup_finish_date) AS backup_finish_date,
    DATEDIFF(SECOND, MAX(bs.backup_start_date), MAX(bs.backup_finish_date)) AS duration_seconds,
    DATEDIFF(MINUTE, MAX(bs.backup_start_date), MAX(bs.backup_finish_date)) AS duration_minutes,
    SUM(bs.backup_size) / 1024.0 / 1024.0 / 1024.0 AS total_backup_size_gb,
    SUM(bs.compressed_backup_size) / 1024.0 / 1024.0 / 1024.0 AS total_compressed_size_gb,
    STRING_AGG(bmf.physical_device_name, ', ') AS backup_files
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.type = 'D'
  AND bs.database_name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution')
  AND bs.backup_finish_date = (
      SELECT MAX(backup_finish_date)
      FROM msdb.dbo.backupset bs2
      WHERE bs2.database_name = bs.database_name AND bs2.type = 'D'
  )
GROUP BY bs.database_name;
