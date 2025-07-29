SELECT 
    s.session_id AS SPID,
    s.login_name AS LoginName,
    s.host_name AS HostName,
    s.program_name AS ProgramName,
    s.status AS SessionStatus,
    DB_NAME(s.database_id) AS DatabaseName
FROM 
    sys.dm_exec_sessions s
INNER JOIN 
    sys.dm_exec_connections c ON s.session_id = c.session_id
WHERE 
    DB_NAME(s.database_id) = 'YourDatabaseName'  -- Replace with your database name
ORDER BY 
    s.session_id;
