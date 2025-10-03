

# Carpeta donde están los logs
LOG_DIR="/sysx/data/pg_log"

# Expresiones a buscar
EXPRESIONES="maria|jose"

RESULT="$LOG_DIR/$(hostname -I | awk '{print $1}' |  tr '.' '_').txt"

# Recorremos los archivos
for archivo in "$LOG_DIR"/*; do
    if [[ "$archivo" == *.log ]]; then
        grep -Ei "$EXPRESIONES" "$archivo"  >> $RESULT 
    elif [[ "$archivo" == *.gz ]]; then
        tar --to-stdout -xf "$archivo" | grep -Ei "$EXPRESIONES" >> $RESULT 
    fi
done


head "/sysx/data/pg_log/$(hostname -I | awk '{print $1}' |  tr '.' '_').txt" 
hostname -I

 watch "ps -fea | grep pg_log"




