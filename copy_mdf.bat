_mdfpath="C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\"
NET STOP MSSQLSERVER
copy /y %_mdfpath%*.* %1
NET START MSSQLSERVER
SLEEP 120
C:\sql\sqlcmd -S 192.168.11.4 -U sa -P sqlpassword -i gensql.sql -v _what=attach -v _path="%_mdfpath%" -v _recovery=NORECOVERY -v _files=1 -W >%1attachall.sql
@PowerShell "(get-Content %1attachall.sql |Select-Object -Skip 2 |select-string -pattern 'rows affected' -notmatch) | Set-Content %1attachall.sql"

