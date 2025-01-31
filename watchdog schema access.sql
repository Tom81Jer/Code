-- Create login for the AD group
CREATE LOGIN [SQL_D_0300_InterfaceMetadata_watchdog] 
FROM WINDOWS WITH DEFAULT_DATABASE = [InterfaceMetadata];

-- Use the InterfaceMetadata database
USE [InterfaceMetadata];

-- Create a database user for the login
CREATE USER [SQL_D_0300_InterfaceMetadata_watchdog] FOR LOGIN [SQL_D_0300_InterfaceMetadata_watchdog];

-- Create a database role for watchdog access
CREATE ROLE [watchdog];

-- Grant DML access to the watchdog schema if it exists
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'watchdog')
BEGIN
    GRANT INSERT, DELETE, UPDATE ON SCHEMA::watchdog TO [watchdog];
END
ELSE
BEGIN
    PRINT 'The watchdog schema does not exist in the current database.';
END

-- Grant the watchdog role to the database user
ALTER ROLE [watchdog] ADD MEMBER [SQL_D_0300_InterfaceMetadata_watchdog];
