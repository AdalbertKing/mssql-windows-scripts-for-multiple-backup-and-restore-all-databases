A package of .BAT scripts and .sql queries for MSSQL for Windows to perform an automatic backup of all working databases on MSSQL ended with generating the SQL query needed to restore this backup. The included scripts support differential and full backups, and the scripts that restore databases from copies can set them to norecovery or recovery mode.

The main application, is a complete backup with automatic recovery procedure.

The second application is to implement a backup of two or more SQL servers by automatically uploading differential backups of all running databases to the backup server. 

(E.g. between MSSQL Server for Linux and for Windows )

Scripts description:

1. backupall.bat [option] [backup_path] [group_bases]-Backup all databases to the backup_path with options for .sql query.

        [options] - string with options pushed to the .sql query after "WITH" 
		[group-bases]- {new|all}  all databases or only new added after last full backup 
e.g:

C:\sql\backupall.bat FORMAT,INIT,NO_COMPRESSION c:\dump\sqlfull\ all
C:\sql\backupall.bat FORMAT,INIT,NO_COMPRESSION c:\dump\sqlfull\ new	
C:\sql\backupall.bat FORMAT,INIT,NO_COMPRESSION c:\dump\sqlfull\ all	
C:\sql\backupall.bat DIFFERENTIAL,FORMAT c:\dump\sqldiff\ all
		
2. backup.sql - used by backupall.bat	-SQL query with options for create backup all databases on 

launched from .bat script by command:

sqlcmd -S [ip_sqlserver] -U sa -P [sqlpassword] -i backupall.sql -v _path="%2" -v _parameters=%1 -v onlynew="%3"


@path = '$(_path)'    	-- database backup directory

@par = '$(_parameters)'	-- parameters added for restore/attach option to generated script
@onlynew - '$(_onlynew)'-- all or added databases after last full backup


4. gensql.sql	- used by backupall.bat		-SQL query with options to generate .sql scipt to the STDOUT for multiple operation on databases

launched from .bat script by command - an a example:

sqlcmd -S [ip_sqlserver] -U sa -P [sqlpassword] -i gensql.sql -v _what=restore -v _path="%2" -v _recovery=NORECOVERY -v _files=1 -v _onlynew=all -W >%2restoreall.sql

@folderpath = '$(_path)' 	-- Backup Location
@recovery = '$(_recovery)' 	-- model of recovery
@what = '$(_what)'		-- Type of generated .sql script [attach|restore|setrecovery]
@files = '$(_files)' 		-- FILES parameter
@onlynew - '$(_onlynew)'-- all or added databases after last full backup

4. copy_mdf.bat %1		-- Copy all databas files from sql server data after stop sql server, than start sql server.

 %1 - path for copy
 
I used scripts by Paul Hewson: https://www.sqlserversnippets.com/2013/10/generate-scripts-to-attach-multiple.html

Greg Robidoux: https://www.mssqltips.com/sqlservertip/1070/simple-script-to-backup-all-sql-server-databases/


__________________________________________________________________________________________________________________________________________________________________________________________
A working example:
1. Scripts path: c:\sql
2. Full backup Path: c:\dump\sqlfull\
3. Differential backup path: c:\dump\sqldiff\
4. MSSQL Server IP: 192.168.11.4

5. backupfull.xml  - Ones a day at 23:15 Task Scheduler runs task  used command:
				
				C:\sql\backupall.bat "FORMAT,INIT,NO_COMPRESSION" c:\dump\sqlfull\ all
				      					  
				creates full backups of all databases, and two scripts: restoreall.sql and setrecovery.sql for restore all backups and switch recovery state bases on final step of restoring backups.
6. backupdiff.xml  - Every day From 10:00 every two hours to 22:00 Task Scheduler runs task used command:

				1. C:\sql\backupall.bat "FORMAT,INIT,NO_COMPRESSION" c:\dump\sqlfull\ new
				
				creates full backups of new added databases after last full backup (they has not differential backup yet), and scripts for them: restorenew.sql and setrecoveryall.sql, than join them to main scripts in full backup path
				2. C:\sql\backupall.bat "DIFFERENTIAL,FORMAT" c:\dump\sqldiff\
				
				creates differential backups of all databases, and two scripts restoreall.sql and setrecovery.sql for restore all backups and switch recovery state bases on final step of restoring backups.
7. copymdf.xml	- used for scenario with first stopping sql server, than coping all .mdf and .ldf files to the c:\dump\mdfcopy\ and creates query attachall.sql for attach all copied databases
				Need to change IP with instance, name of MSSQLSERVER service running on windows and path to folder with .mdf,.ldf:
				C:\sql\copy_mdf.bat c:\dump\mdfcopy\
						NET STOP MSSQLSERVER
						copy -a C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\*.* c:\dump\mdfcopy
						NET STOP MSSQLSERVER
						SLEEP 120
						C:\sql\sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i gensql.sql -v _what=attach -v _path="C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\" -v _recovery=NORECOVERY -v _files=1 -W >c:\dump\mdfcopy\attachall.sql
						@PowerShell "(get-Content c:\dump\mdfcopy\attachall.sql|Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content c:\dump\mdfcopy\attachall.sql"
		 
Important:
In your scenario it is necessary to set the correct server IP with the SQL instance, password, name of MSSQLSERVER service running on windows (if you want to use copymdf.xml ), paths to data folder and backups folder.
You can map the network resource with backups to a local folder, in this scenario it is c:\dump\. It is important that it is equally visible on the server with MSSQL and on the workstation from which the scripts will be run.


Scenarios of recovery databses:
I. The scenario of fully restoring the databases from a .bak copy consists of three stages: 

Stage 1: running an automatically generated .sql query restoreall.sql for recovery databases from .bak for FULL copies by command:
	C:\sql\sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i c:\dump\sqlfull\restoreall.sql
	
  	Full copies, so the databases recovered in the first stage will be NORECOVERY. Since we assume that there are still differential copies waiting to be restored
	
Stage 2: running an automatically generated .sql query restoreall.sql From Differential Copies:
    
	C:\sql\sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i c:\dump\sqldiff\restoreall.sql
	
	The recovered databases in the second stage will be NORECOVERY (perheps to the next tasks of recovery )
	    	
Stage 3: running an automatically generated query setrecoveryall.sql for switch all databases into RECOVERY state.
	
	C:\sql\sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i c:\dump\sqldiff\setrecovery.sql
_________________________________________________________________________________________________________________________________________________________________________________________

II. The scenario for attach all previously copied .mdf and.ldf files to sql server. (It should run on a machine with MSSQL)
	Stage 1: copy c:\dump\mdfcopy\*.* C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\
 	
	Stage 2: running an automatically generated .sql query that performs ATTACH for every databases: 

	C:\sql\sqlcmd -S localhost -U sa -P 'sqlpassword' -i attachall.sql  -(check and correct  the paths inside .sql scripts if needed before running )
	
___________________________________________________________________________________________________________________________________________________________________________________________

Importants:
1. In your scenario it is necessary to set the correct server IP with the SQL instance, password, name of MSSQLSERVER service running on windows (if you want to use copymdf.xml variant ), paths to data folder and backups folder.
You can map the network resource with backups to a local folder, in this scenario it is c:\dump\. It is important that it is equally visible on the server with MSSQL and on the workstation from which the scripts will be run.
 Easest way is use mklink /d command on SQL SERVER machine and workstation.

2.Full copies are made with INIT,FORMAT parameters, resulting in the creation of a new file. bak and resetting the backup cycle with the writing of this information to the database.
 Differential copies are made with the FORMAT parameter. As a result, we have in the directories with backups the last full copy and the last differential copy.
 Which allows you to recover databases to the state after the full backup, or after the last differential. To recover databases to any point in the past, you need to add a mechanism for archiving directories with .bak. between
 backup tasks, or create them on a snapshot file system (ZFS, BTRFS). You can also exclude FORMAT and INIT parameters from the scripts, which will result in incrementing .bak files.
 However, this will affect the correctness of the restoreall.sql query, which in this version does not support the FILES = n parameter yet, that allows you to specify the archive position in the continuos .bak file.
 Implementing this mechanism is difficult because each database may be created at a different time , and thus will have a different FILES parameter at a given time.
 
 This version of the scripts allows you to extend the period between full backups, as I added a mechanism for identifying newly added databases (after the last full copy), and performing a full backup for them immediately
(during a differential copy)
 
 
I hope that my work will help someone to implement and automate backup or mirror on SQL server for Windows with multiple databases. I would appreciate reporting bugs and suggestions for improving the procedure.
 

						WOJCIECH KROL
						lurk@lurk.com.pl
						2022-10-11

