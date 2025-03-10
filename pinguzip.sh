#!/bin/bash

# Configuración avanzada de colores ANSI
BLUE="\033[38;5;39m"      # Azul neón
YELLOW="\033[38;5;226m"   # Amarillo brillante
GREEN="\033[38;5;46m"     # Verde fosforito
RED="\033[38;5;196m"      # Rojo intenso
RESET="\033[0m"

# Banner ASCII mejorado
show_banner() {
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
    sleep 2
}

# Funciones de variación de contraseñas
generate_variations() {
    local pass="$1"
    echo "$pass"                # Original
    echo "${pass}123"           # Sufijo numérico
    echo "${pass}!"             # Sufijo especial
    echo "abc${pass}"           # Prefijo común
    echo "${pass^^}"            # Todo mayúsculas
    echo "${pass,,}"            # Todo minúsculas
    echo "${pass:0:1}${pass:1}" # Capitalización
}

# Configuración multi-plataforma
setup_environment() {
    case "$(uname -s)" in
        Darwin*) # macOS
            STAT_CMD="stat -f %z"
            SHASUM="shasum -a 256"
            ;;
        Linux*)  # Linux
            STAT_CMD="stat -c %s"
            SHASUM="sha256sum"
            ;;
        *)
            echo -e "${RED}Sistema operativo no soportado${RESET}"
            exit 1
            ;;
    esac
}

# Manejo de señales para interrupción limpia
handle_interrupt() {
    echo -e "\n${YELLOW}[!] Interrupción detectada. Mostrando resumen...${RESET}"
    show_summary
    cleanup
    exit 1
}

# Limpieza de recursos temporales
cleanup() {
    [[ -f "$ZIP_CACHE" ]] && rm -f "$ZIP_CACHE"
}

# Mostrar resumen de ejecución
show_summary() {
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    
    echo -e "\n${BLUE}=== RESUMEN DE EJECUCIÓN ==="
    echo -e "Archivo analizado: ${YELLOW}$ZIPFILE${BLUE}"
    echo -e "Diccionario usado: ${YELLOW}$WORDLIST${BLUE}"
    echo -e "Tamaño del diccionario: ${YELLOW}$TOTAL_LINES líneas${BLUE}"
    echo -e "Variaciones generadas: ${YELLOW}$((TOTAL_LINES * 7)) estimadas${BLUE}"
    echo -e "Contraseñas probadas: ${YELLOW}$ATTEMPT_COUNT${BLUE}"
    echo -e "Tiempo total: ${YELLOW}${total_time} segundos${BLUE}"
    [[ $total_time -gt 0 ]] && \
    echo -e "Velocidad promedio: ${YELLOW}$((ATTEMPT_COUNT / total_time)) p/s${BLUE}"
    echo -e "Estado final: ${1}${RESET}"
}

# Validación de dependencias
check_dependencies() {
    local missing=()
    for cmd in unzip pv; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Faltan dependencias críticas:${RESET}"
        for m in "${missing[@]}"; do
            echo -e " - ${YELLOW}$m${RESET}"
        done
        exit 1
    fi
}

# Configuración inicial
trap handle_interrupt SIGINT
VERBOSE=0
ZIP_CACHE=""

# ─── INICIO DEL SCRIPT ───
show_banner
check_dependencies
setup_environment

# Manejo de parámetros
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v) VERBOSE=1; shift ;;
        -vv) VERBOSE=2; shift ;;
        *) break ;;
    esac
done

if [[ "$#" -ne 2 ]]; then
    echo -e "${RED}Uso: $0 [-v|-vv] archivo.zip diccionario.txt${RESET}"
    exit 1
fi

ZIPFILE="$1"
WORDLIST="$2"

# Validación de archivos
[[ ! -f "$ZIPFILE" ]] && echo -e "${RED}El archivo ZIP no existe${RESET}" && exit 1
[[ ! -f "$WORDLIST" ]] && echo -e "${RED}El diccionario no existe${RESET}" && exit 1

# Detección de cifrado AES
if unzip -v "$ZIPFILE" | grep -q "AES"; then
    echo -e "${YELLOW}[!] Advertencia: Archivo usa cifrado AES (más seguro)${RESET}"
fi

# Caching en RAM
ZIP_CACHE="/dev/shm/${ZIPFILE##*/}"
cp "$ZIPFILE" "$ZIP_CACHE" && trap "cleanup" EXIT || exit 1

# Configuración de estadísticas
START_TIME=$(date +%s)
ATTEMPT_COUNT=0
TOTAL_LINES=$(wc -l < "$WORDLIST")
[[ $VERBOSE -ge 1 ]] && echo -e "${BLUE}Iniciando proceso con ${YELLOW}$TOTAL_LINES${BLUE} entradas base${RESET}"

# Proceso principal de fuerza bruta
while IFS= read -r base_password || [[ -n "$base_password" ]]; do
    while IFS= read -r password; do
        ((ATTEMPT_COUNT++))
        
        # Modo verboso avanzado
        if [[ $VERBOSE -ge 2 ]]; then
            echo -ne "${YELLOW}Probando variación ${ATTEMPT_COUNT}: "
            echo -e "${password:0:12}$([[ ${#password} -gt 12 ]] && echo '...')${RESET}"
        fi
        
        # Intento de descompresión
        if unzip -t -P "$password" "$ZIP_CACHE" &> /dev/null; then
            echo -e "\n${GREEN}[+] ¡Contraseña encontrada!: ${YELLOW}$password${RESET}"
            show_summary "${GREEN}ÉXITO${RESET}"
            exit 0
        fi
    done < <(generate_variations "$base_password")
    
    # Actualización de progreso
    if [[ $((ATTEMPT_COUNT % 100)) -eq 0 ]] || [[ $VERBOSE -ge 1 ]]; then
        elapsed=$(( $(date +%s) - START_TIME ))
        speed=$(( ATTEMPT_COUNT / (elapsed + 1) ))
        echo -ne "${BLUE}Progreso: ${YELLOW}$ATTEMPT_COUNT${BLUE} intentos | "
        echo -ne "Velocidad: ${YELLOW}$speed p/s${BLUE} | "
        echo -e "Tiempo: ${YELLOW}${elapsed}s${RESET}\r"
    fi
done < <(pv -pet -s "$TOTAL_LINES" "$WORDLIST")

# Si llega aquí = fallo
show_summary "${RED}FRACASO${RESET}"
exit 1
