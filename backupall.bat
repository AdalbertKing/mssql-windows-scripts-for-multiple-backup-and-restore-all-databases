echo off
if [%3] ==[] ( GOTO not_defined)
IF [%3] == [all] ( GOTO not_defined)
IF [%3] == [new] ( GOTO defined) ELSE (GOTO error  )

:defined
set onlynew=%3
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i gensql.sql -v _what=restore -v _path="%2" -v _recovery=NORECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%2restorenew.sql
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i gensql.sql -v _what=setrecovery -v _path="%2" -v _recovery=RECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%2setrecoverynew.sql
	@PowerShell "(get-Content %2setrecoverynew.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2setrecoverynew.sql"
	@PowerShell "(get-Content %2restorenew.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2restorenew.sql"
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i backupall.sql -v _path="%2" -v _parameters=%1 -v _onlynew="%onlynew%"
	echo "backup tylko nowych baz"
	type %2restorenew.sql>>%2restoreall.sql
	type %2setrecoverynew.sql>>%2setrecovery.sql
	goto end
:not_defined
set onlynew=all
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i backupall.sql -v _path="%2" -v _parameters=%1 -v _onlynew="%onlynew%"
	echo backup wszystkich baz parametr %onlynew%
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i gensql.sql -v _what=restore -v _path="%2" -v _recovery=NORECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%2restoreall.sql
	sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i gensql.sql -v _what=setrecovery -v _path="%2" -v _recovery=RECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%2setrecovery.sql
	@PowerShell "(get-Content %2setrecovery.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2setrecovery.sql"
	@PowerShell "(get-Content %2restoreall.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2restoreall.sql"
        goto :end
:error
echo unknow parameter
:end

