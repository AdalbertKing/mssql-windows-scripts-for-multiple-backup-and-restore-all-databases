DECLARE @name NVARCHAR(256) -- database name  
DECLARE @path NVARCHAR(512) -- path for backup files  
DECLARE @fileName NVARCHAR(512) -- filename for backup  
DECLARE @fileDate NVARCHAR(40) -- used for file name
DECLARE @par NVARCHAR(256) -- used for parameters
DECLARE @onlynew NVARCHAR(5)
SET @path = '$(_path)'
SET @par = '$(_parameters)'
SET @onlynew = '$(_onlynew)'
-- specify filename format
SELECT @fileDate = CONVERT(NVARCHAR(20),GETDATE(),112) 

DECLARE db_cursor CURSOR READ_ONLY FOR
SELECT z.name
FROM master.sys.databases AS z
WHERE z.name NOT IN ('master','model','msdb','tempdb')
AND state = 0 -- database is online
AND is_in_standby = 0 -- database is not read only for log shipping
AND ( @onlynew = 'all' OR NOT EXISTS        
								( SELECT
									bs.database_name
									FROM msdb.dbo.backupset AS bs
									WHERE bs.type = 'D' AND z.name = bs.database_name
								)
	)
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   
WHILE @@FETCH_STATUS = 0   
		BEGIN   
   			SET @fileName = @path + @name +'.bak'  
			BACKUP DATABASE @name TO DISK = @fileName WITH $(_parameters)
			/*PRINT @fileName*/
   			FETCH NEXT FROM db_cursor INTO @name   
		END
CLOSE db_cursor   
DEALLOCATE db_cursor
