_mdfpath="C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\"
NET STOP MSSQLSERVER
copy -a %_mdfpath%/* %1
NET START MSSQLSERVER


