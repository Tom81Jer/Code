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
    print @schemaTransfer

    FETCH NEXT FROM object_cursor INTO @objName, @objType;
END

CLOSE object_cursor;
DEALLOCATE object_cursor;


- === Transfer sequences ===
DECLARE @seqName NVARCHAR(255);

DECLARE sequence_cursor CURSOR FOR
SELECT name
FROM sys.sequences
WHERE schema_id = SCHEMA_ID('mySchema');

OPEN sequence_cursor;
FETCH NEXT FROM sequence_cursor INTO @seqName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @schemaTransfer = 'ALTER SCHEMA dbo TRANSFER mySchema.' + QUOTENAME(@seqName) + ';';
    print @schemaTransfer

    FETCH NEXT FROM sequence_cursor INTO @seqName;
END

CLOSE sequence_cursor;
DEALLOCATE sequence_cursor;
