DECLARE @folderpath VARCHAR (1000)
DECLARE @recovery VARCHAR (12)
DECLARE @What VARCHAR (12)
DECLARE @files VARCHAR (12)
DECLARE @onlynew NVARCHAR(5)

SELECT @folderpath = '$(_path)' -- Backup Location
SELECT @recovery = '$(_recovery)' -- model of recovery
SELECT @what = '$(_what)' -- Type of generated .sql script
SELECT @files = '$(_files)' -- No. of archive in .bak for restore
SET @onlynew = '$(_onlynew)'


IF @what = 'restore'
	BEGIN
		IF @files < = 1
 			BEGIN
				SELECT 'RESTORE DATABASE['+z.name+'] FROM DISK = ''' +@folderpath + "" + z.name+'.bak'' WITH $(_recovery),
REPLACE, STATS = 5
'
				FROM master.sys.databases AS z
				WHERE z.name NOT IN ('master','model','msdb','tempdb','distribution')
				AND ( @onlynew = 'all' OR NOT EXISTS        
								( SELECT
									bs.database_name
									FROM msdb.dbo.backupset AS bs
									WHERE bs.type = 'D' AND z.name = bs.database_name
								)
				)
			 END;

		IF @files > 1
 			BEGIN
			        SELECT 'RESTORE DATABASE['+z.name+'] FROM DISK = ''' +@folderpath + "" + z.name+'.bak'' WITH $(_recovery),
REPLACE, STATS = 5, FILE = $(_files)
'
				FROM master.sys.databases AS z
				WHERE z.name NOT IN ('master','model','msdb','tempdb','distribution')
				AND ( @onlynew = 'all' OR NOT EXISTS        
								( SELECT
									bs.database_name
									FROM msdb.dbo.backupset AS bs
									WHERE bs.type = 'D' AND z.name = bs.database_name
								)
					)

			 END;

	END;


IF @what = 'attach'
	BEGIN

		SELECT
		'CREATE DATABASE [' + z.name +'] ON
		( FILENAME = N'''+@folderpath + z.name + '.mdf'' ),
		( FILENAME = N'''+@folderpath + z.name + '_log.ldf'' )
		 FOR ATTACH
		'
		FROM master.dbo.sysdatabases AS z
		WHERE z.name not in ('master','msdb','model','tempdb')

		ORDER BY z.name
	END;

IF @what = 'setrecovery'
	BEGIN
		SELECT 'RESTORE DATABASE['+z.name+'] WITH $(_recovery)
'
		FROM master.sys.databases AS z
		WHERE z.name NOT IN ('master','model','msdb','tempdb','distribution')
		AND ( @onlynew = 'all' OR NOT EXISTS        
								( SELECT
									bs.database_name
									FROM msdb.dbo.backupset AS bs
									WHERE bs.type = 'D' AND z.name = bs.database_name
								)
					)
		
	END;








