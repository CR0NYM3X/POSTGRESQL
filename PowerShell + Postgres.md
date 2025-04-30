Ref
```
https://stackoverflow.com/questions/9217650/connect-to-remote-postgresql-database-using-powershell 
https://www.cdata.com/kb/tech/postgresql-ado-powershell.rst
https://blog.mclaughlinsoftware.com/2022/03/31/postgresqlpowershell/
```

# Ejemplo Básico
```
$connectionString = "Driver={PostgreSQL Unicode};Server=your_server;Port=5432;Database=your_database;Uid=your_username;Pwd=your_password;"
$connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)

try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT * FROM your_table"
    $reader = $command.ExecuteReader()

    while ($reader.Read()) {
        # Procesa los datos
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    $reader.Close()
    $connection.Close()
}

```
