:: ver 3.5
:: typical usage: backupall.bat serwer\insertgt sa "" "FORMAT,INIT,NO_COMPRESSION" J:\dump\insertgt\full\
:: by lurk@lurk.com.pl 2022-11

echo off
if [%6] ==[] ( GOTO not_defined)
IF [%6] == [all] ( GOTO not_defined)
IF [%6] == [new] ( GOTO defined) ELSE (GOTO error  )

:defined
set onlynew=%6
	sqlcmd -S %1 -U %2 -P %3 -i gensql.sql -v _what=restore -v _path="%5" -v _recovery=NORECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%5restorenew.sql
	sqlcmd -S %1 -U %2 -P %3 -i gensql.sql -v _what=setrecovery -v _path="%5" -v _recovery=RECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%5setrecoverynew.sql
	@PowerShell "(get-Content %5setrecoverynew.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %5setrecoverynew.sql"
	@PowerShell "(get-Content %5restorenew.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %5restorenew.sql"
	sqlcmd -S %1 -U %2 -P %3 -i backupall.sql -v _path="%5" -v _parameters=%4 -v _onlynew="%onlynew%"
	echo "backup tylko nowych baz"
	type %5restorenew.sql>>%5restoreall.sql
	type %5setrecoverynew.sql>>%5setrecovery.sql
	goto end
:not_defined
set onlynew=all
	sqlcmd -S %1 -U %2 -P %3 -i backupall.sql -v _path="%5" -v _parameters=%4 -v _onlynew="%onlynew%"
	echo backup wszystkich baz parametr %onlynew%
	sqlcmd -S %1 -U %2 -P %3 -i gensql.sql -v _what=restore -v _path="%5" -v _recovery=NORECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%5restoreall.sql
	sqlcmd -S %1 -U %2 -P %3 -i gensql.sql -v _what=setrecovery -v _path="%5" -v _recovery=RECOVERY -v _files=1 -v _onlynew="%onlynew%" -W>%5setrecovery.sql
	@PowerShell "(get-Content %5setrecovery.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %5setrecovery.sql"
	@PowerShell "(get-Content %5restoreall.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %5restoreall.sql"
        goto :end
:error
echo unknow parameter
:end

