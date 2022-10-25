DECLARE @folderpath VARCHAR (1000)
DECLARE @recovery VARCHAR (12)
DECLARE @What VARCHAR (12)
DECLARE @files VARCHAR (12)

SELECT @folderpath = '$(_path)' -- Backup Location
SELECT @recovery = '$(_recovery)' -- model of recovery
SELECT @what = '$(_what)' -- Type of generated .sql script
SELECT @files = '$(_files)' -- No. of archive in .bak for restore


IF @what = 'restore'
	BEGIN
		IF @files < = 1
 			BEGIN
				SELECT 'RESTORE DATABASE['+NAME+'] FROM DISK = ''' +@folderpath + "" + name+'.bak'' WITH $(_recovery),
REPLACE, STATS = 5'
				FROM master.sys.databases
				WHERE name NOT IN ('master','model','msdb','tempdb','distribution')
			 END;

		IF @files > 1
 			BEGIN
			        SELECT 'RESTORE DATABASE['+NAME+'] FROM DISK = ''' +@folderpath + "" + name+'.bak'' WITH $(_recovery),
REPLACE, STATS = 5, FILE = $(_files)'
				FROM master.sys.databases
				WHERE name NOT IN ('master','model','msdb','tempdb','distribution')

			 END;

	END;


IF @what = 'attach'
	BEGIN

		SELECT
		'CREATE DATABASE [' + name +'] ON
		( FILENAME = N'''+@folderpath + name + '.mdf'' ),
		( FILENAME = N'''+@folderpath + name + '_log.ldf'' )
		 FOR ATTACH
		'
		FROM master.dbo.sysdatabases
		WHERE name not in ('master','msdb','model','tempdb')

		ORDER BY name
	END;

IF @what = 'setrecovery'
	BEGIN
		SELECT 'RESTORE DATABASE['+name+'] WITH $(_recovery)'
		FROM master.sys.databases
		WHERE name NOT IN ('master','model','msdb','tempdb','distribution')

	END;








