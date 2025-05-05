#!/bin/bash

#Declarar un arreglo con los usuarios a realizar busqueda
cadenas=(user_1 user_2 user_3 user_4)

# Imprimir las cadenas almacenadas
for elemento in "${cadenas[@]}"; do
	echo "$Buscando usuario $elemento"

#dia,mes y año como argumentos
diahoy=$(date +%d)
#mes actual con sus respectivos dias
#month=$(date +%m)
year=$(date +%Y) 
#buscar en los dias de un mes en especifico
month=02
#imprime año corto dos ultimos digitos
yearcorto=$(date +%Y | cut -c3-4) 
#dia de ayer
ayer=$(date -d "yesterday" +%02d)

#Obtener el número de días en el mes actual
days_last=$(cal $month $year | awk 'NF {DAYS = $NF}; END {print DAYS}')

	#Imprimir todos los días del mes
	for day in $(seq 1 $days_last); do
		#para imprimir siempre los dias en 2 digitos
		printf -v day "%02d" $day
		echo "-----------*********Log encontrado en postgresql-$yearcorto$month$day.tar.gz********-----------" >> /tmp/log_user_$elemento.txt
		#zcat /sysx/data/pg_log/postgresql-250228.tar.gz | grep -i -a "syshuellasemps" | grep -i -a "connection authorized" | tail -2 >> /tmp/log_user_syshuellasemps.txt
		zcat /sysx/data/pg_log/postgresql-$yearcorto$month$day.tar.gz | grep -i -a "$elemento" | grep -i -a "connection authorized" | tail -2 >> /tmp/log_user_$elemento.txt
			
	done
done
