
:: Script for run any .sql query from command line
:: %1 - path to script
sqlcmd -S 192.168.11.4 -U sa -P Sq!2014 -i %1
