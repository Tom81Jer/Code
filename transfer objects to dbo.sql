DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @objName NVARCHAR(255);
DECLARE @objType NVARCHAR(100);
DECLARE @schemaTransfer NVARCHAR(MAX);

-- Object types that support schema transfer
DECLARE object_cursor CURSOR FOR
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('mySchema')
  AND type IN ('U', 'V', 'P', 'FN', 'TF', 'IF') -- Tables, Views, Procedures, Functions

OPEN object_cursor;
FETCH NEXT FROM object_cursor INTO @objName, @objType;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @schemaTransfer = 'ALTER SCHEMA dbo TRANSFER mySchema.' + QUOTENAME(@objName) + ';';
    SET @sql += @schemaTransfer + CHAR(13);

    FETCH NEXT FROM object_cursor INTO @objName, @objType;
END

CLOSE object_cursor;
DEALLOCATE object_cursor;

PRINT '-- Executing schema transfer commands:';
PRINT @sql;

-- If you're ready, uncomment this line to actually run it:
-- EXEC sp_executesql @sql;
