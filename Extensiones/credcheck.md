
# credcheck 
```sql
select name,setting,short_desc from pg_settings where name ilike '%credcheck.%' order by name;


ejemplos: https://github.com/MigOpsRepos/credcheck/tree/master/test/expected

https://stackoverflow.com/questions/68400120/how-to-generate-scram-sha-256-to-create-postgres-13-user

```
