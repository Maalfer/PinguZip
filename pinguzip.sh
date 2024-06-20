#!/bin/bash

# Definir colores usando códigos ANSI
BLUE="\033[38;5;39m"   # Azul fosforito
YELLOW="\033[38;5;226m"  # Amarillo fosforito
RESET="\033[0m"  

echo -e "
████████  ████ ██    ██  ██████   ██     ██ ████████ ████ ████████  
██     ██  ██  ███   ██ ██    ██  ██     ██      ██   ██  ██     ██ 
██     ██  ██  ████  ██ ██        ██     ██     ██    ██  ██     ██ 
████████   ██  ██ ██ ██ ██   ████ ██     ██    ██     ██  ████████  
██         ██  ██  ████ ██    ██  ██     ██   ██      ██  ██        
██         ██  ██   ███ ██    ██  ██     ██  ██       ██  ██        
██        ████ ██    ██  ██████    ███████  ████████ ████ ██        

${BLUE}[+]${RESET} - ${YELLOW}Made with love by The Penguin of Mario (El Pingüino de Mario)${RESET}
"

sleep 4

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 archivo.zip diccionario.txt"
    exit 1
fi

ZIPFILE=$1
WORDLIST=$2

if [ ! -f "$ZIPFILE" ]; then
    echo "El archivo zip '$ZIPFILE' no existe."
    exit 1
fi

if [ ! -f "$WORDLIST" ]; then
    echo "El archivo de contraseñas '$WORDLIST' no existe."
    exit 1
fi

while read -r PASSWORD || [[ -n "$PASSWORD" ]]; do
    echo "Intentando con la contraseña: $PASSWORD"
    unzip -t -P "$PASSWORD" "$ZIPFILE" &> /dev/null

    if [ $? -eq 0 ]; then
	echo -e "${BLUE}Contraseña encontrada: $PASSWORD${RESET}"
        exit 0
    fi
done < "$WORDLIST"

echo "No se encontró ninguna contraseña en el diccionario '$WORDLIST'."
exit 1
