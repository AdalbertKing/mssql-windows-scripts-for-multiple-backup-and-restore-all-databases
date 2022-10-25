sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i backupall.sql -v _path="%2" -v _parameters=%1
sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i gensql.sql -v _what=restore -v _path="%2" -v _recovery=NORECOVERY -v _files=1 -W >%2restoreall.sql
sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i gensql.sql -v _what=setrecovery -v _path="%2" -v _recovery=RECOVERY -v _files=1 -W >%2setrecovery.sql
@PowerShell "(get-Content %2setrecovery.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2setrecovery.sql"
@PowerShell "(get-Content %2restoreall.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %2restoreall.sql"
