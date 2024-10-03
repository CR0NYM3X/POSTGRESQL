aquí encontraras los manuales  de todos los binarios de postgresql desde las versiones 11 a la version 16


 
```sh 


mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7
  
mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7
  
mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7
 
mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7
 
mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7

 
 
mkdir -p /tmp/man_bin_psql/11/man1
mkdir -p /tmp/man_bin_psql/11/man3
mkdir -p /tmp/man_bin_psql/11/man7

 
ls -lhtr /usr/pgsql-11/share/man/man1 | awk '{ print "man /usr/pgsql-11/share/man/man1/"$9 " > /tmp/man_bin_psql/11/man1/"$9"__"}' | sed 's/.1__//g'  | grep -v "/__" > /tmp/otro.txt 
ls -lhtr /usr/pgsql-11/share/man/man3 | awk '{ print "man /usr/pgsql-11/share/man/man3/"$9 " > /tmp/man_bin_psql/11/man3/"$9"__"}' | sed 's/.3__//g'  | grep -v "/__" >> /tmp/otro.txt 
ls -lhtr /usr/pgsql-11/share/man/man7 | awk '{ print "man /usr/pgsql-11/share/man/man7/"$9 " > /tmp/man_bin_psql/11/man7/"$9"__"}' | sed 's/.7__//g'  | grep -v "/__" >> /tmp/otro.txt 
clear
clear
clear
cat /tmp/otro.txt  

 
```
